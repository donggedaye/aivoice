import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aivoice/domain/entities/claim.dart';

const _recordingId = '1789833654808';
const _asrSource = 'asr:sensevoice-small@int8';
const _llmModel = 'fixture-model';
final _createdAt = DateTime.utc(2026, 10, 5, 7, 30);

Map<String, Object?> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

ClaimBatch _parse(Object? response) => parseAnalyzeResponse(
      response,
      recordingId: _recordingId,
      asrSource: _asrSource,
      llmModel: _llmModel,
      createdAt: _createdAt,
    );

/// 把一條 claim 包成一份 `analyze_response` 的信封。
Map<String, Object?> _envelope(List<Object?> claims) => {
      'prompt_version': 'analyzer_v1+verifier_v1',
      'claims': claims,
    };

/// 一條什麼都沒犯的 claim，給針對單一欄位的測試當底。
Map<String, Object?> _ok({
  String type = 'FACT',
  String category = 'SUMMARY',
  Object? reasoning,
  Object? dueDate,
}) =>
    {
      'type': type,
      'category': category,
      'text': '客戶合約明年三月到期。',
      'evidence': [
        {
          'segment_id': '$_recordingId-0007',
          'start_ms': 41200,
          'end_ms': 47800,
          'quote': '合約明年三月到期',
        },
      ],
      'reasoning': reasoning,
      'confidence': 'HIGH',
      'missing_info': <String>[],
      'owner': null,
      'due_date': dueDate,
    };

void main() {
  test('the positive example in the contract survives intact', () {
    final batch = _parse(_readJson('schema/examples/analyze_response.json'));

    expect(batch.dropped, isEmpty);
    expect(batch.kept, hasLength(6));
    expect(batch.kept.map((c) => c.id), [
      '$_recordingId-c0000',
      '$_recordingId-c0001',
      '$_recordingId-c0002',
      '$_recordingId-c0003',
      '$_recordingId-c0004',
      '$_recordingId-c0005',
    ]);

    // SUGGESTION 不需要依據，但一定要有理由 —— 契約就是這樣分的。
    final suggestion = batch.kept.last;
    expect(suggestion.type, ClaimType.suggestion);
    expect(suggestion.evidence, isEmpty);
    expect(suggestion.reasoning, isNotEmpty);

    final uncertain = batch.kept[4];
    expect(uncertain.confidence, Confidence.uncertain);
    expect(uncertain.missingInfo, ['下次碰面的確切日期', '參加的人有誰']);

    final inference = batch.kept[2];
    expect(inference.type, ClaimType.inference);
    expect(inference.evidence, hasLength(2));
    expect(inference.evidence.first.segmentId, '$_recordingId-0007');
    expect(inference.evidence.first.quote, '我們這套是二〇一九年上線的，合約明年三月到期');

    expect(batch.kept.first.source,
        '$_asrSource + llm:$_llmModel@analyzer_v1+verifier_v1');
    expect(batch.kept.first.userAction, UserAction.pending);
    expect(batch.kept.first.entityIds, isEmpty);
  });

  test('every negative example in the contract is thrown out', () {
    final cases = _readJson('schema/examples/rejected.json')['cases'] as List;

    for (var i = 0; i < cases.length; i++) {
      final item = (cases[i] as Map).cast<String, Object?>();
      final why = item['why'] as String;
      final batch = _parse(_envelope([item['claim']]));

      if (item['schema_cannot_catch'] == true) {
        // 產品原則 4（不做對人的判斷）結構上驗不了，是提示詞與人工檢查的責任。
        // 這裡確認它真的擋不住，不要讓人以為客戶端有在管。
        expect(batch.kept, hasLength(1), reason: '第 $i 條：$why');
        expect(batch.dropped, isEmpty, reason: '第 $i 條：$why');
      } else {
        expect(batch.kept, isEmpty, reason: '第 $i 條：$why');
        expect(batch.dropped, hasLength(1), reason: '第 $i 條：$why');
        expect(batch.dropped.single.index, 0);
      }
    }
  });

  test('a FACT with no evidence is discarded, the rest of the batch is not',
      () {
    final batch = _parse(
      _envelope([
        _ok(),
        {..._ok(), 'evidence': <Object?>[]},
        _ok(category: 'RISK'),
      ]),
    );

    expect(batch.kept, hasLength(2));
    expect(batch.dropped, hasLength(1));
    expect(batch.dropped.single.index, 1);
    expect(batch.dropped.single.reason, 'FACT 沒有依據');
    // 編號照模型回來的位置算，被丟掉的那條留一個空號。
    expect(batch.kept.map((c) => c.id),
        ['$_recordingId-c0000', '$_recordingId-c0002']);
  });

  test('a SUGGESTION with no reasoning is discarded', () {
    // check.py 的反例只驗了 INFERENCE，但契約同一條規則也管 SUGGESTION。
    final batch = _parse(
      _envelope([
        {..._ok(type: 'SUGGESTION'), 'evidence': <Object?>[]},
      ]),
    );

    expect(batch.kept, isEmpty);
    expect(batch.dropped.single.reason, 'SUGGESTION 沒寫 reasoning');
  });

  test('an INFERENCE keeps its reasoning', () {
    final batch = _parse(
      _envelope([_ok(type: 'INFERENCE', reasoning: '合約三月到期，往前推三個月。')]),
    );

    expect(batch.kept.single.reasoning, '合約三月到期，往前推三個月。');
  });

  test('a value outside the contract is discarded', () {
    for (final bad in [
      {..._ok(), 'type': 'GUESS'},
      {..._ok(), 'category': 'NOTE'},
      {..._ok(), 'confidence': 'PRETTY_SURE'},
      {..._ok(), 'text': ''},
    ]) {
      expect(_parse(_envelope([bad])).kept, isEmpty, reason: bad.toString());
    }
  });

  test('broken evidence is discarded', () {
    for (final bad in [
      {'start_ms': 0, 'end_ms': 1, 'quote': '話'},
      {'segment_id': '', 'start_ms': 0, 'end_ms': 1, 'quote': '話'},
      {'segment_id': 'a-0000', 'start_ms': -1, 'end_ms': 1, 'quote': '話'},
      {'segment_id': 'a-0000', 'start_ms': 0, 'end_ms': 1, 'quote': ''},
      {
        'segment_id': 'a-0000',
        'start_ms': 0,
        'end_ms': 1,
        'quote': '話',
        'speaker': '客戶',
      },
    ]) {
      final batch = _parse(_envelope([
        {..._ok(), 'evidence': [bad]},
      ]));
      expect(batch.kept, isEmpty, reason: bad.toString());
    }
  });

  test('a due_date that is not a real date is discarded', () {
    // 契約寫 format: "date"，但 jsonschema 預設不驗 format，所以後端那一側
    // 只擋得住位數不對的。十三月的待辦要在這裡擋下來。
    for (final bad in ['next month', '2026-13-45', '2026-02-31', '26-03-01']) {
      final batch = _parse(_envelope([_ok(dueDate: bad)]));
      expect(batch.kept, isEmpty, reason: bad);
      expect(batch.dropped.single.reason, contains('due_date'), reason: bad);
    }

    expect(_parse(_envelope([_ok(dueDate: '2026-02-28')])).kept.single.dueDate,
        '2026-02-28');
  });

  test('a broken envelope is a failure, not a silent empty analysis', () {
    // 一條一條違規是丟掉那一條；整份信封不對是真的失敗，要讓使用者看到。
    expect(() => _parse('不是物件'), throwsStateError);
    expect(() => _parse({'claims': <Object?>[]}), throwsStateError);
    expect(() => _parse({'prompt_version': '', 'claims': <Object?>[]}),
        throwsStateError);
    expect(() => _parse({'prompt_version': 'analyzer_v1'}), throwsStateError);
    expect(
        () => _parse({'prompt_version': 'analyzer_v1', 'claims': {}}),
        throwsStateError);
  });

  test('an analysis that kept nothing is still an analysis', () {
    final batch = _parse(_envelope([
      {..._ok(), 'evidence': <Object?>[]},
    ]));

    expect(batch.kept, isEmpty);
    expect(batch.dropped, hasLength(1));
  });
}
