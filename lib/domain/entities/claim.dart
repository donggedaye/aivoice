/// Claim 與它的依據。欄位與 `schema/claim.json` 一對一，改動必須同時改兩邊。
///
/// 這個檔案就是產品原則 2 與 3 在客戶端的閘門：
/// 模型回來的每一條都先過 [Claim.fromAnalyzed]，過不了的直接丟掉，不展示。
/// 後端的 Verifier 也會擋一次，但不能只靠它 —— 代理壞掉或被換掉時，
/// 最後一道防線在手機上。
library;

/// 對應契約的 `type`。
///
/// FACT 對方說出口的事實；OPINION 對方表達的看法；
/// INFERENCE 從話裡推出來的；SUGGESTION 我們建議的行動。
enum ClaimType { fact, opinion, inference, suggestion }

/// 對應契約的 `category`。分析卡片的四個分區。
enum ClaimCategory { summary, todo, decision, risk }

/// 對應契約的 `confidence`。
enum Confidence { high, medium, low, uncertain }

/// 對應契約的 `user_action`。這個月只有確認與拒絕，
/// `edited` 留著是因為契約有，逐條修改排在 10 月以後。
enum UserAction { confirmed, edited, rejected, pending }

/// 一條 claim 的依據，指回轉寫的某一段。
///
/// [quote] 必須是該段落裡真的出現過的字，不是改寫也不是摘要。
/// 這一點結構上驗不了，由後端的 Verifier 負責。
class Evidence {
  const Evidence({
    required this.segmentId,
    required this.startMs,
    required this.endMs,
    required this.quote,
  });

  /// 轉寫段落 id，格式 `<recording_id>-0000`。
  ///
  /// 注意這個 id 是按 VAD 段落的索引生的，重新轉寫會先刪後插，
  /// 所以它跨重轉並不穩定。因此重轉時那筆錄音的 claim 會一起刪掉。
  final String segmentId;
  final int startMs;
  final int endMs;
  final String quote;
}

/// 模型產生的一條結論，加上 App 自己填的欄位。
class Claim {
  const Claim({
    required this.id,
    required this.recordingId,
    required this.type,
    required this.category,
    required this.text,
    required this.confidence,
    required this.createdAt,
    required this.source,
    this.evidence = const [],
    this.reasoning,
    this.missingInfo = const [],
    this.owner,
    this.dueDate,
    this.entityIds = const [],
    this.userAction = UserAction.pending,
  });

  final String id;
  final String recordingId;
  final ClaimType type;
  final ClaimCategory category;

  /// 台灣正體中文。一條只講一件事。
  final String text;

  /// FACT / OPINION / INFERENCE 一定非空，這是產品原則 2。
  final List<Evidence> evidence;

  /// 從依據到這條結論之間的推理。INFERENCE 與 SUGGESTION 一定非空。
  final String? reasoning;

  final Confidence confidence;

  /// [confidence] 是 [Confidence.uncertain] 時一定非空，這是產品原則 3。
  final List<String> missingInfo;

  /// TODO 由誰負責。不知道就是 null，不猜。
  final String? owner;

  /// TODO 的期限，`YYYY-MM-DD`。不知道就是 null，不猜。
  ///
  /// 存字串而不是 `DateTime`：契約是純日期，轉成 `DateTime` 會多出一個
  /// 本地時區的午夜，之後要再猜回來。
  final String? dueDate;

  /// 關聯到的客戶 / 人 / 專案。實體功能排在 10 月以後，現在一律是空陣列。
  final List<String> entityIds;

  final UserAction userAction;
  final DateTime createdAt;

  /// 誰做出來的，例如
  /// `asr:sensevoice-small@int8 + llm:<model>@analyzer_v1+verifier_v1`。
  final String source;

  Claim copyWith({UserAction? userAction}) => Claim(
        id: id,
        recordingId: recordingId,
        type: type,
        category: category,
        text: text,
        confidence: confidence,
        createdAt: createdAt,
        source: source,
        evidence: evidence,
        reasoning: reasoning,
        missingInfo: missingInfo,
        owner: owner,
        dueDate: dueDate,
        entityIds: entityIds,
        userAction: userAction ?? this.userAction,
      );

  /// 把模型回來的一條轉成 [Claim]，違反契約就丟 [RejectedClaim]。
  ///
  /// [id]、[recordingId]、[createdAt]、[source] 是 App 自己填的，
  /// 不要叫模型生。
  factory Claim.fromAnalyzed(
    Object? raw, {
    required String id,
    required String recordingId,
    required DateTime createdAt,
    required String source,
  }) {
    if (raw is! Map) throw const RejectedClaim('不是物件');
    final json = raw.cast<String, Object?>();

    // 契約的 analyzed_claim_strict 用 unevaluatedProperties: false 擋多餘欄位。
    // 多出來的欄位代表這份回應不是照我們的契約生的，整條不要。
    final unknown = json.keys.where((key) => !_allowedKeys.contains(key));
    if (unknown.isNotEmpty) {
      throw RejectedClaim('有契約沒有的欄位：${unknown.join('、')}');
    }

    final type = _wireEnum(ClaimType.values, json['type'], 'type');
    final category =
        _wireEnum(ClaimCategory.values, json['category'], 'category');
    final confidence =
        _wireEnum(Confidence.values, json['confidence'], 'confidence');

    final text = json['text'];
    if (text is! String || text.isEmpty) {
      throw const RejectedClaim('text 不是非空字串');
    }

    final evidence = _parseEvidence(json['evidence']);
    // 產品原則 2：說是事實、看法或推論，就得指得出哪句話。
    if (evidence.isEmpty &&
        const {ClaimType.fact, ClaimType.opinion, ClaimType.inference}
            .contains(type)) {
      throw RejectedClaim('${wireName(type)} 沒有依據');
    }

    final reasoning = json['reasoning'];
    if (reasoning != null && reasoning is! String) {
      throw const RejectedClaim('reasoning 不是字串也不是 null');
    }
    // 推論與建議要說得出理由。
    if (const {ClaimType.inference, ClaimType.suggestion}.contains(type) &&
        (reasoning is! String || reasoning.isEmpty)) {
      throw RejectedClaim('${wireName(type)} 沒寫 reasoning');
    }

    final missingInfo = _parseStringList(json['missing_info'], 'missing_info');
    // 產品原則 3：資訊不足就說不足，並講清楚缺什麼。
    if (confidence == Confidence.uncertain && missingInfo.isEmpty) {
      throw const RejectedClaim('UNCERTAIN 沒填 missing_info');
    }

    final owner = json['owner'];
    if (owner != null && (owner is! String || owner.isEmpty)) {
      throw const RejectedClaim('owner 不是非空字串也不是 null');
    }

    return Claim(
      id: id,
      recordingId: recordingId,
      type: type,
      category: category,
      text: text,
      evidence: evidence,
      reasoning: reasoning as String?,
      confidence: confidence,
      missingInfo: missingInfo,
      owner: owner as String?,
      dueDate: _parseDueDate(json['due_date']),
      source: source,
      createdAt: createdAt,
    );
  }

  static const _allowedKeys = {
    'type',
    'category',
    'text',
    'evidence',
    'reasoning',
    'confidence',
    'missing_info',
    'owner',
    'due_date',
  };
}

/// 一條 claim 違反契約。整條丟掉，不是整批失敗。
class RejectedClaim implements Exception {
  const RejectedClaim(this.reason);

  final String reason;

  @override
  String toString() => 'RejectedClaim: $reason';
}

/// 被丟掉的那一條，以及丟掉的理由。
///
/// [index] 是在模型回來的陣列裡的位置，用來對照後端的紀錄。
class DroppedClaim {
  const DroppedClaim({required this.index, required this.reason});

  final int index;
  final String reason;
}

/// 一次 `/analyze` 的解析結果。
///
/// [dropped] 不是錯誤：模型偶爾會生出沒有依據的 FACT，照產品原則 2 丟掉就是了。
/// 留著數量是為了知道提示詞有多常出錯。
class ClaimBatch {
  const ClaimBatch({required this.kept, required this.dropped});

  final List<Claim> kept;
  final List<DroppedClaim> dropped;
}

/// 解析後端 `/analyze` 的回應。
///
/// [asrSource] 是轉寫那一側的來源字串（`TranscriptionRepository.source`），
/// [llmModel] 由呼叫方給 —— 契約的 `analyze_response` 只帶 `prompt_version`，
/// 沒有模型名稱，而 `Claim.source` 要記下用了哪個模型。
///
/// 整批的信封壞掉（不是物件、沒有 claims、沒有 prompt_version）是真的失敗，
/// 丟 [StateError]；單條違規只會進 [ClaimBatch.dropped]。
ClaimBatch parseAnalyzeResponse(
  Object? raw, {
  required String recordingId,
  required String asrSource,
  required String llmModel,
  required DateTime createdAt,
}) {
  if (raw is! Map) throw StateError('分析結果格式不符，請重試');
  final json = raw.cast<String, Object?>();

  final promptVersion = json['prompt_version'];
  if (promptVersion is! String || promptVersion.isEmpty) {
    throw StateError('分析結果沒有標明提示詞版本，請重試');
  }

  final claims = json['claims'];
  if (claims is! List) throw StateError('分析結果格式不符，請重試');

  final source = '$asrSource + llm:$llmModel@$promptVersion';
  final kept = <Claim>[];
  final dropped = <DroppedClaim>[];

  for (var i = 0; i < claims.length; i++) {
    try {
      kept.add(
        Claim.fromAnalyzed(
          claims[i],
          // 被丟掉的那幾條會在編號上留空，這樣 id 跟模型回來的位置對得上。
          id: '$recordingId-c${i.toString().padLeft(4, '0')}',
          recordingId: recordingId,
          createdAt: createdAt,
          source: source,
        ),
      );
    } on RejectedClaim catch (e) {
      dropped.add(DroppedClaim(index: i, reason: e.reason));
    }
  }

  return ClaimBatch(kept: kept, dropped: dropped);
}

/// enum 在契約與資料庫裡都是大寫，Dart 這邊是小寫。
String wireName(Enum value) => value.name.toUpperCase();

/// 從大寫字串還原 enum，認不出來回傳 null。
T? wireLookup<T extends Enum>(List<T> values, Object? wire) {
  for (final value in values) {
    if (wireName(value) == wire) return value;
  }
  return null;
}

T _wireEnum<T extends Enum>(List<T> values, Object? wire, String field) =>
    wireLookup(values, wire) ??
    (throw RejectedClaim('$field 不是契約裡的值：$wire'));

List<Evidence> _parseEvidence(Object? raw) {
  if (raw == null) return const [];
  if (raw is! List) throw const RejectedClaim('evidence 不是陣列');

  return [
    for (final item in raw) _parseEvidenceItem(item),
  ];
}

Evidence _parseEvidenceItem(Object? raw) {
  if (raw is! Map) throw const RejectedClaim('evidence 裡有不是物件的項目');
  final json = raw.cast<String, Object?>();

  final unknown = json.keys.where((key) => !_evidenceKeys.contains(key));
  if (unknown.isNotEmpty) {
    throw RejectedClaim('evidence 有契約沒有的欄位：${unknown.join('、')}');
  }

  final segmentId = json['segment_id'];
  if (segmentId is! String || segmentId.isEmpty) {
    throw const RejectedClaim('evidence 的 segment_id 不是非空字串');
  }

  final startMs = json['start_ms'];
  final endMs = json['end_ms'];
  if (startMs is! int || startMs < 0 || endMs is! int || endMs < 0) {
    throw const RejectedClaim('evidence 的時間戳不是非負整數');
  }

  final quote = json['quote'];
  if (quote is! String || quote.isEmpty) {
    throw const RejectedClaim('evidence 的 quote 不是非空字串');
  }

  return Evidence(
    segmentId: segmentId,
    startMs: startMs,
    endMs: endMs,
    quote: quote,
  );
}

const _evidenceKeys = {'segment_id', 'start_ms', 'end_ms', 'quote'};

List<String> _parseStringList(Object? raw, String field) {
  if (raw == null) return const [];
  if (raw is! List) throw RejectedClaim('$field 不是陣列');

  return [
    for (final item in raw)
      if (item is String && item.isNotEmpty)
        item
      else
        throw RejectedClaim('$field 裡有不是非空字串的項目'),
  ];
}

/// `YYYY-MM-DD`，而且要是真的日期。
///
/// 契約用 `format: "date"`，但 jsonschema 預設不驗 format，所以後端那一側
/// 其實只擋得住位數不對的字串。`2026-13-45` 位數是對的 ——
/// 放它進來會變成一條期限在十三月的待辦。
String? _parseDueDate(Object? raw) {
  if (raw == null) return null;
  if (raw is! String) throw const RejectedClaim('due_date 不是字串也不是 null');
  if (!_datePattern.hasMatch(raw)) {
    throw RejectedClaim('due_date 不是 YYYY-MM-DD：$raw');
  }

  final parsed = DateTime.tryParse(raw);
  // tryParse 收得下 2026-02-31 並滾到三月，所以要反過來比對一次。
  if (parsed == null ||
      parsed.year != int.parse(raw.substring(0, 4)) ||
      parsed.month != int.parse(raw.substring(5, 7)) ||
      parsed.day != int.parse(raw.substring(8, 10))) {
    throw RejectedClaim('due_date 不是真的日期：$raw');
  }
  return raw;
}

final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
