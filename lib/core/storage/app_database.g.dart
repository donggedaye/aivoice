// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TranscriptsTable extends Transcripts
    with TableInfo<$TranscriptsTable, TranscriptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranscriptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordingIdMeta = const VerificationMeta(
    'recordingId',
  );
  @override
  late final GeneratedColumn<String> recordingId = GeneratedColumn<String>(
    'recording_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [recordingId, createdAt, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transcripts';
  @override
  VerificationContext validateIntegrity(
    Insertable<TranscriptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recording_id')) {
      context.handle(
        _recordingIdMeta,
        recordingId.isAcceptableOrUnknown(
          data['recording_id']!,
          _recordingIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordingIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordingId};
  @override
  TranscriptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranscriptRow(
      recordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $TranscriptsTable createAlias(String alias) {
    return $TranscriptsTable(attachedDatabase, alias);
  }
}

class TranscriptRow extends DataClass implements Insertable<TranscriptRow> {
  final String recordingId;
  final DateTime createdAt;

  /// 什麼產生了這份轉寫，例如 `asr:sensevoice-small@int8`。
  /// 換模型之後要知道舊的結果是誰轉的。
  final String source;
  const TranscriptRow({
    required this.recordingId,
    required this.createdAt,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recording_id'] = Variable<String>(recordingId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['source'] = Variable<String>(source);
    return map;
  }

  TranscriptsCompanion toCompanion(bool nullToAbsent) {
    return TranscriptsCompanion(
      recordingId: Value(recordingId),
      createdAt: Value(createdAt),
      source: Value(source),
    );
  }

  factory TranscriptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranscriptRow(
      recordingId: serializer.fromJson<String>(json['recordingId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordingId': serializer.toJson<String>(recordingId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'source': serializer.toJson<String>(source),
    };
  }

  TranscriptRow copyWith({
    String? recordingId,
    DateTime? createdAt,
    String? source,
  }) => TranscriptRow(
    recordingId: recordingId ?? this.recordingId,
    createdAt: createdAt ?? this.createdAt,
    source: source ?? this.source,
  );
  TranscriptRow copyWithCompanion(TranscriptsCompanion data) {
    return TranscriptRow(
      recordingId: data.recordingId.present
          ? data.recordingId.value
          : this.recordingId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptRow(')
          ..write('recordingId: $recordingId, ')
          ..write('createdAt: $createdAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recordingId, createdAt, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranscriptRow &&
          other.recordingId == this.recordingId &&
          other.createdAt == this.createdAt &&
          other.source == this.source);
}

class TranscriptsCompanion extends UpdateCompanion<TranscriptRow> {
  final Value<String> recordingId;
  final Value<DateTime> createdAt;
  final Value<String> source;
  final Value<int> rowid;
  const TranscriptsCompanion({
    this.recordingId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranscriptsCompanion.insert({
    required String recordingId,
    required DateTime createdAt,
    required String source,
    this.rowid = const Value.absent(),
  }) : recordingId = Value(recordingId),
       createdAt = Value(createdAt),
       source = Value(source);
  static Insertable<TranscriptRow> custom({
    Expression<String>? recordingId,
    Expression<DateTime>? createdAt,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordingId != null) 'recording_id': recordingId,
      if (createdAt != null) 'created_at': createdAt,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranscriptsCompanion copyWith({
    Value<String>? recordingId,
    Value<DateTime>? createdAt,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return TranscriptsCompanion(
      recordingId: recordingId ?? this.recordingId,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordingId.present) {
      map['recording_id'] = Variable<String>(recordingId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptsCompanion(')
          ..write('recordingId: $recordingId, ')
          ..write('createdAt: $createdAt, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranscriptSegmentsTable extends TranscriptSegments
    with TableInfo<$TranscriptSegmentsTable, TranscriptSegmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranscriptSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordingIdMeta = const VerificationMeta(
    'recordingId',
  );
  @override
  late final GeneratedColumn<String> recordingId = GeneratedColumn<String>(
    'recording_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordingId,
    startMs,
    endMs,
    content,
    confidence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transcript_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<TranscriptSegmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recording_id')) {
      context.handle(
        _recordingIdMeta,
        recordingId.isAcceptableOrUnknown(
          data['recording_id']!,
          _recordingIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordingIdMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TranscriptSegmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranscriptSegmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording_id'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
    );
  }

  @override
  $TranscriptSegmentsTable createAlias(String alias) {
    return $TranscriptSegmentsTable(attachedDatabase, alias);
  }
}

class TranscriptSegmentRow extends DataClass
    implements Insertable<TranscriptSegmentRow> {
  final String id;
  final String recordingId;
  final int startMs;
  final int endMs;
  final String content;
  final double? confidence;
  const TranscriptSegmentRow({
    required this.id,
    required this.recordingId,
    required this.startMs,
    required this.endMs,
    required this.content,
    this.confidence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recording_id'] = Variable<String>(recordingId);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    return map;
  }

  TranscriptSegmentsCompanion toCompanion(bool nullToAbsent) {
    return TranscriptSegmentsCompanion(
      id: Value(id),
      recordingId: Value(recordingId),
      startMs: Value(startMs),
      endMs: Value(endMs),
      content: Value(content),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
    );
  }

  factory TranscriptSegmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranscriptSegmentRow(
      id: serializer.fromJson<String>(json['id']),
      recordingId: serializer.fromJson<String>(json['recordingId']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
      content: serializer.fromJson<String>(json['content']),
      confidence: serializer.fromJson<double?>(json['confidence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordingId': serializer.toJson<String>(recordingId),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
      'content': serializer.toJson<String>(content),
      'confidence': serializer.toJson<double?>(confidence),
    };
  }

  TranscriptSegmentRow copyWith({
    String? id,
    String? recordingId,
    int? startMs,
    int? endMs,
    String? content,
    Value<double?> confidence = const Value.absent(),
  }) => TranscriptSegmentRow(
    id: id ?? this.id,
    recordingId: recordingId ?? this.recordingId,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
    content: content ?? this.content,
    confidence: confidence.present ? confidence.value : this.confidence,
  );
  TranscriptSegmentRow copyWithCompanion(TranscriptSegmentsCompanion data) {
    return TranscriptSegmentRow(
      id: data.id.present ? data.id.value : this.id,
      recordingId: data.recordingId.present
          ? data.recordingId.value
          : this.recordingId,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      content: data.content.present ? data.content.value : this.content,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptSegmentRow(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('content: $content, ')
          ..write('confidence: $confidence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recordingId, startMs, endMs, content, confidence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranscriptSegmentRow &&
          other.id == this.id &&
          other.recordingId == this.recordingId &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.content == this.content &&
          other.confidence == this.confidence);
}

class TranscriptSegmentsCompanion
    extends UpdateCompanion<TranscriptSegmentRow> {
  final Value<String> id;
  final Value<String> recordingId;
  final Value<int> startMs;
  final Value<int> endMs;
  final Value<String> content;
  final Value<double?> confidence;
  final Value<int> rowid;
  const TranscriptSegmentsCompanion({
    this.id = const Value.absent(),
    this.recordingId = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.content = const Value.absent(),
    this.confidence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranscriptSegmentsCompanion.insert({
    required String id,
    required String recordingId,
    required int startMs,
    required int endMs,
    required String content,
    this.confidence = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordingId = Value(recordingId),
       startMs = Value(startMs),
       endMs = Value(endMs),
       content = Value(content);
  static Insertable<TranscriptSegmentRow> custom({
    Expression<String>? id,
    Expression<String>? recordingId,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<String>? content,
    Expression<double>? confidence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordingId != null) 'recording_id': recordingId,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (content != null) 'content': content,
      if (confidence != null) 'confidence': confidence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranscriptSegmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? recordingId,
    Value<int>? startMs,
    Value<int>? endMs,
    Value<String>? content,
    Value<double?>? confidence,
    Value<int>? rowid,
  }) {
    return TranscriptSegmentsCompanion(
      id: id ?? this.id,
      recordingId: recordingId ?? this.recordingId,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      content: content ?? this.content,
      confidence: confidence ?? this.confidence,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recordingId.present) {
      map['recording_id'] = Variable<String>(recordingId.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('content: $content, ')
          ..write('confidence: $confidence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnalysesTable extends Analyses
    with TableInfo<$AnalysesTable, AnalysisRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalysesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordingIdMeta = const VerificationMeta(
    'recordingId',
  );
  @override
  late final GeneratedColumn<String> recordingId = GeneratedColumn<String>(
    'recording_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _droppedCountMeta = const VerificationMeta(
    'droppedCount',
  );
  @override
  late final GeneratedColumn<int> droppedCount = GeneratedColumn<int>(
    'dropped_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recordingId,
    createdAt,
    source,
    droppedCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analyses';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnalysisRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recording_id')) {
      context.handle(
        _recordingIdMeta,
        recordingId.isAcceptableOrUnknown(
          data['recording_id']!,
          _recordingIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordingIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('dropped_count')) {
      context.handle(
        _droppedCountMeta,
        droppedCount.isAcceptableOrUnknown(
          data['dropped_count']!,
          _droppedCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_droppedCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordingId};
  @override
  AnalysisRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalysisRow(
      recordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      droppedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dropped_count'],
      )!,
    );
  }

  @override
  $AnalysesTable createAlias(String alias) {
    return $AnalysesTable(attachedDatabase, alias);
  }
}

class AnalysisRow extends DataClass implements Insertable<AnalysisRow> {
  final String recordingId;
  final DateTime createdAt;

  /// 誰做出來的，例如
  /// `asr:sensevoice-small@int8 + llm:<model>@analyzer_v1+verifier_v1`。
  final String source;

  /// 被客戶端擋掉的條數。用來知道提示詞多常生出沒有依據的結論。
  final int droppedCount;
  const AnalysisRow({
    required this.recordingId,
    required this.createdAt,
    required this.source,
    required this.droppedCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recording_id'] = Variable<String>(recordingId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['source'] = Variable<String>(source);
    map['dropped_count'] = Variable<int>(droppedCount);
    return map;
  }

  AnalysesCompanion toCompanion(bool nullToAbsent) {
    return AnalysesCompanion(
      recordingId: Value(recordingId),
      createdAt: Value(createdAt),
      source: Value(source),
      droppedCount: Value(droppedCount),
    );
  }

  factory AnalysisRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalysisRow(
      recordingId: serializer.fromJson<String>(json['recordingId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      source: serializer.fromJson<String>(json['source']),
      droppedCount: serializer.fromJson<int>(json['droppedCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordingId': serializer.toJson<String>(recordingId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'source': serializer.toJson<String>(source),
      'droppedCount': serializer.toJson<int>(droppedCount),
    };
  }

  AnalysisRow copyWith({
    String? recordingId,
    DateTime? createdAt,
    String? source,
    int? droppedCount,
  }) => AnalysisRow(
    recordingId: recordingId ?? this.recordingId,
    createdAt: createdAt ?? this.createdAt,
    source: source ?? this.source,
    droppedCount: droppedCount ?? this.droppedCount,
  );
  AnalysisRow copyWithCompanion(AnalysesCompanion data) {
    return AnalysisRow(
      recordingId: data.recordingId.present
          ? data.recordingId.value
          : this.recordingId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      source: data.source.present ? data.source.value : this.source,
      droppedCount: data.droppedCount.present
          ? data.droppedCount.value
          : this.droppedCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisRow(')
          ..write('recordingId: $recordingId, ')
          ..write('createdAt: $createdAt, ')
          ..write('source: $source, ')
          ..write('droppedCount: $droppedCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recordingId, createdAt, source, droppedCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalysisRow &&
          other.recordingId == this.recordingId &&
          other.createdAt == this.createdAt &&
          other.source == this.source &&
          other.droppedCount == this.droppedCount);
}

class AnalysesCompanion extends UpdateCompanion<AnalysisRow> {
  final Value<String> recordingId;
  final Value<DateTime> createdAt;
  final Value<String> source;
  final Value<int> droppedCount;
  final Value<int> rowid;
  const AnalysesCompanion({
    this.recordingId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.source = const Value.absent(),
    this.droppedCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalysesCompanion.insert({
    required String recordingId,
    required DateTime createdAt,
    required String source,
    required int droppedCount,
    this.rowid = const Value.absent(),
  }) : recordingId = Value(recordingId),
       createdAt = Value(createdAt),
       source = Value(source),
       droppedCount = Value(droppedCount);
  static Insertable<AnalysisRow> custom({
    Expression<String>? recordingId,
    Expression<DateTime>? createdAt,
    Expression<String>? source,
    Expression<int>? droppedCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordingId != null) 'recording_id': recordingId,
      if (createdAt != null) 'created_at': createdAt,
      if (source != null) 'source': source,
      if (droppedCount != null) 'dropped_count': droppedCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalysesCompanion copyWith({
    Value<String>? recordingId,
    Value<DateTime>? createdAt,
    Value<String>? source,
    Value<int>? droppedCount,
    Value<int>? rowid,
  }) {
    return AnalysesCompanion(
      recordingId: recordingId ?? this.recordingId,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      droppedCount: droppedCount ?? this.droppedCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordingId.present) {
      map['recording_id'] = Variable<String>(recordingId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (droppedCount.present) {
      map['dropped_count'] = Variable<int>(droppedCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalysesCompanion(')
          ..write('recordingId: $recordingId, ')
          ..write('createdAt: $createdAt, ')
          ..write('source: $source, ')
          ..write('droppedCount: $droppedCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClaimsTable extends Claims with TableInfo<$ClaimsTable, ClaimRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClaimsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordingIdMeta = const VerificationMeta(
    'recordingId',
  );
  @override
  late final GeneratedColumn<String> recordingId = GeneratedColumn<String>(
    'recording_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasoningMeta = const VerificationMeta(
    'reasoning',
  );
  @override
  late final GeneratedColumn<String> reasoning = GeneratedColumn<String>(
    'reasoning',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _missingInfoMeta = const VerificationMeta(
    'missingInfo',
  );
  @override
  late final GeneratedColumn<String> missingInfo = GeneratedColumn<String>(
    'missing_info',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  @override
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
    'owner',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityIdsMeta = const VerificationMeta(
    'entityIds',
  );
  @override
  late final GeneratedColumn<String> entityIds = GeneratedColumn<String>(
    'entity_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userActionMeta = const VerificationMeta(
    'userAction',
  );
  @override
  late final GeneratedColumn<String> userAction = GeneratedColumn<String>(
    'user_action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordingId,
    type,
    category,
    content,
    reasoning,
    confidence,
    missingInfo,
    owner,
    dueDate,
    entityIds,
    userAction,
    createdAt,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'claims';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClaimRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recording_id')) {
      context.handle(
        _recordingIdMeta,
        recordingId.isAcceptableOrUnknown(
          data['recording_id']!,
          _recordingIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordingIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('reasoning')) {
      context.handle(
        _reasoningMeta,
        reasoning.isAcceptableOrUnknown(data['reasoning']!, _reasoningMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('missing_info')) {
      context.handle(
        _missingInfoMeta,
        missingInfo.isAcceptableOrUnknown(
          data['missing_info']!,
          _missingInfoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_missingInfoMeta);
    }
    if (data.containsKey('owner')) {
      context.handle(
        _ownerMeta,
        owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('entity_ids')) {
      context.handle(
        _entityIdsMeta,
        entityIds.isAcceptableOrUnknown(data['entity_ids']!, _entityIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdsMeta);
    }
    if (data.containsKey('user_action')) {
      context.handle(
        _userActionMeta,
        userAction.isAcceptableOrUnknown(data['user_action']!, _userActionMeta),
      );
    } else if (isInserting) {
      context.missing(_userActionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClaimRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClaimRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      reasoning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasoning'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence'],
      )!,
      missingInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missing_info'],
      )!,
      owner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      entityIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_ids'],
      )!,
      userAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_action'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $ClaimsTable createAlias(String alias) {
    return $ClaimsTable(attachedDatabase, alias);
  }
}

class ClaimRow extends DataClass implements Insertable<ClaimRow> {
  final String id;
  final String recordingId;
  final String type;
  final String category;
  final String content;
  final String? reasoning;
  final String confidence;
  final String missingInfo;
  final String? owner;

  /// `YYYY-MM-DD`。存字串而不是 `DateTime`：契約是純日期。
  final String? dueDate;
  final String entityIds;
  final String userAction;
  final DateTime createdAt;
  final String source;
  const ClaimRow({
    required this.id,
    required this.recordingId,
    required this.type,
    required this.category,
    required this.content,
    this.reasoning,
    required this.confidence,
    required this.missingInfo,
    this.owner,
    this.dueDate,
    required this.entityIds,
    required this.userAction,
    required this.createdAt,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recording_id'] = Variable<String>(recordingId);
    map['type'] = Variable<String>(type);
    map['category'] = Variable<String>(category);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || reasoning != null) {
      map['reasoning'] = Variable<String>(reasoning);
    }
    map['confidence'] = Variable<String>(confidence);
    map['missing_info'] = Variable<String>(missingInfo);
    if (!nullToAbsent || owner != null) {
      map['owner'] = Variable<String>(owner);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    map['entity_ids'] = Variable<String>(entityIds);
    map['user_action'] = Variable<String>(userAction);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['source'] = Variable<String>(source);
    return map;
  }

  ClaimsCompanion toCompanion(bool nullToAbsent) {
    return ClaimsCompanion(
      id: Value(id),
      recordingId: Value(recordingId),
      type: Value(type),
      category: Value(category),
      content: Value(content),
      reasoning: reasoning == null && nullToAbsent
          ? const Value.absent()
          : Value(reasoning),
      confidence: Value(confidence),
      missingInfo: Value(missingInfo),
      owner: owner == null && nullToAbsent
          ? const Value.absent()
          : Value(owner),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      entityIds: Value(entityIds),
      userAction: Value(userAction),
      createdAt: Value(createdAt),
      source: Value(source),
    );
  }

  factory ClaimRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClaimRow(
      id: serializer.fromJson<String>(json['id']),
      recordingId: serializer.fromJson<String>(json['recordingId']),
      type: serializer.fromJson<String>(json['type']),
      category: serializer.fromJson<String>(json['category']),
      content: serializer.fromJson<String>(json['content']),
      reasoning: serializer.fromJson<String?>(json['reasoning']),
      confidence: serializer.fromJson<String>(json['confidence']),
      missingInfo: serializer.fromJson<String>(json['missingInfo']),
      owner: serializer.fromJson<String?>(json['owner']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      entityIds: serializer.fromJson<String>(json['entityIds']),
      userAction: serializer.fromJson<String>(json['userAction']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordingId': serializer.toJson<String>(recordingId),
      'type': serializer.toJson<String>(type),
      'category': serializer.toJson<String>(category),
      'content': serializer.toJson<String>(content),
      'reasoning': serializer.toJson<String?>(reasoning),
      'confidence': serializer.toJson<String>(confidence),
      'missingInfo': serializer.toJson<String>(missingInfo),
      'owner': serializer.toJson<String?>(owner),
      'dueDate': serializer.toJson<String?>(dueDate),
      'entityIds': serializer.toJson<String>(entityIds),
      'userAction': serializer.toJson<String>(userAction),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'source': serializer.toJson<String>(source),
    };
  }

  ClaimRow copyWith({
    String? id,
    String? recordingId,
    String? type,
    String? category,
    String? content,
    Value<String?> reasoning = const Value.absent(),
    String? confidence,
    String? missingInfo,
    Value<String?> owner = const Value.absent(),
    Value<String?> dueDate = const Value.absent(),
    String? entityIds,
    String? userAction,
    DateTime? createdAt,
    String? source,
  }) => ClaimRow(
    id: id ?? this.id,
    recordingId: recordingId ?? this.recordingId,
    type: type ?? this.type,
    category: category ?? this.category,
    content: content ?? this.content,
    reasoning: reasoning.present ? reasoning.value : this.reasoning,
    confidence: confidence ?? this.confidence,
    missingInfo: missingInfo ?? this.missingInfo,
    owner: owner.present ? owner.value : this.owner,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    entityIds: entityIds ?? this.entityIds,
    userAction: userAction ?? this.userAction,
    createdAt: createdAt ?? this.createdAt,
    source: source ?? this.source,
  );
  ClaimRow copyWithCompanion(ClaimsCompanion data) {
    return ClaimRow(
      id: data.id.present ? data.id.value : this.id,
      recordingId: data.recordingId.present
          ? data.recordingId.value
          : this.recordingId,
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
      content: data.content.present ? data.content.value : this.content,
      reasoning: data.reasoning.present ? data.reasoning.value : this.reasoning,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      missingInfo: data.missingInfo.present
          ? data.missingInfo.value
          : this.missingInfo,
      owner: data.owner.present ? data.owner.value : this.owner,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      entityIds: data.entityIds.present ? data.entityIds.value : this.entityIds,
      userAction: data.userAction.present
          ? data.userAction.value
          : this.userAction,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClaimRow(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('content: $content, ')
          ..write('reasoning: $reasoning, ')
          ..write('confidence: $confidence, ')
          ..write('missingInfo: $missingInfo, ')
          ..write('owner: $owner, ')
          ..write('dueDate: $dueDate, ')
          ..write('entityIds: $entityIds, ')
          ..write('userAction: $userAction, ')
          ..write('createdAt: $createdAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordingId,
    type,
    category,
    content,
    reasoning,
    confidence,
    missingInfo,
    owner,
    dueDate,
    entityIds,
    userAction,
    createdAt,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClaimRow &&
          other.id == this.id &&
          other.recordingId == this.recordingId &&
          other.type == this.type &&
          other.category == this.category &&
          other.content == this.content &&
          other.reasoning == this.reasoning &&
          other.confidence == this.confidence &&
          other.missingInfo == this.missingInfo &&
          other.owner == this.owner &&
          other.dueDate == this.dueDate &&
          other.entityIds == this.entityIds &&
          other.userAction == this.userAction &&
          other.createdAt == this.createdAt &&
          other.source == this.source);
}

class ClaimsCompanion extends UpdateCompanion<ClaimRow> {
  final Value<String> id;
  final Value<String> recordingId;
  final Value<String> type;
  final Value<String> category;
  final Value<String> content;
  final Value<String?> reasoning;
  final Value<String> confidence;
  final Value<String> missingInfo;
  final Value<String?> owner;
  final Value<String?> dueDate;
  final Value<String> entityIds;
  final Value<String> userAction;
  final Value<DateTime> createdAt;
  final Value<String> source;
  final Value<int> rowid;
  const ClaimsCompanion({
    this.id = const Value.absent(),
    this.recordingId = const Value.absent(),
    this.type = const Value.absent(),
    this.category = const Value.absent(),
    this.content = const Value.absent(),
    this.reasoning = const Value.absent(),
    this.confidence = const Value.absent(),
    this.missingInfo = const Value.absent(),
    this.owner = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.entityIds = const Value.absent(),
    this.userAction = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClaimsCompanion.insert({
    required String id,
    required String recordingId,
    required String type,
    required String category,
    required String content,
    this.reasoning = const Value.absent(),
    required String confidence,
    required String missingInfo,
    this.owner = const Value.absent(),
    this.dueDate = const Value.absent(),
    required String entityIds,
    required String userAction,
    required DateTime createdAt,
    required String source,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordingId = Value(recordingId),
       type = Value(type),
       category = Value(category),
       content = Value(content),
       confidence = Value(confidence),
       missingInfo = Value(missingInfo),
       entityIds = Value(entityIds),
       userAction = Value(userAction),
       createdAt = Value(createdAt),
       source = Value(source);
  static Insertable<ClaimRow> custom({
    Expression<String>? id,
    Expression<String>? recordingId,
    Expression<String>? type,
    Expression<String>? category,
    Expression<String>? content,
    Expression<String>? reasoning,
    Expression<String>? confidence,
    Expression<String>? missingInfo,
    Expression<String>? owner,
    Expression<String>? dueDate,
    Expression<String>? entityIds,
    Expression<String>? userAction,
    Expression<DateTime>? createdAt,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordingId != null) 'recording_id': recordingId,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (content != null) 'content': content,
      if (reasoning != null) 'reasoning': reasoning,
      if (confidence != null) 'confidence': confidence,
      if (missingInfo != null) 'missing_info': missingInfo,
      if (owner != null) 'owner': owner,
      if (dueDate != null) 'due_date': dueDate,
      if (entityIds != null) 'entity_ids': entityIds,
      if (userAction != null) 'user_action': userAction,
      if (createdAt != null) 'created_at': createdAt,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClaimsCompanion copyWith({
    Value<String>? id,
    Value<String>? recordingId,
    Value<String>? type,
    Value<String>? category,
    Value<String>? content,
    Value<String?>? reasoning,
    Value<String>? confidence,
    Value<String>? missingInfo,
    Value<String?>? owner,
    Value<String?>? dueDate,
    Value<String>? entityIds,
    Value<String>? userAction,
    Value<DateTime>? createdAt,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return ClaimsCompanion(
      id: id ?? this.id,
      recordingId: recordingId ?? this.recordingId,
      type: type ?? this.type,
      category: category ?? this.category,
      content: content ?? this.content,
      reasoning: reasoning ?? this.reasoning,
      confidence: confidence ?? this.confidence,
      missingInfo: missingInfo ?? this.missingInfo,
      owner: owner ?? this.owner,
      dueDate: dueDate ?? this.dueDate,
      entityIds: entityIds ?? this.entityIds,
      userAction: userAction ?? this.userAction,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recordingId.present) {
      map['recording_id'] = Variable<String>(recordingId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (reasoning.present) {
      map['reasoning'] = Variable<String>(reasoning.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (missingInfo.present) {
      map['missing_info'] = Variable<String>(missingInfo.value);
    }
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (entityIds.present) {
      map['entity_ids'] = Variable<String>(entityIds.value);
    }
    if (userAction.present) {
      map['user_action'] = Variable<String>(userAction.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClaimsCompanion(')
          ..write('id: $id, ')
          ..write('recordingId: $recordingId, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('content: $content, ')
          ..write('reasoning: $reasoning, ')
          ..write('confidence: $confidence, ')
          ..write('missingInfo: $missingInfo, ')
          ..write('owner: $owner, ')
          ..write('dueDate: $dueDate, ')
          ..write('entityIds: $entityIds, ')
          ..write('userAction: $userAction, ')
          ..write('createdAt: $createdAt, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClaimEvidenceTable extends ClaimEvidence
    with TableInfo<$ClaimEvidenceTable, ClaimEvidenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClaimEvidenceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _claimIdMeta = const VerificationMeta(
    'claimId',
  );
  @override
  late final GeneratedColumn<String> claimId = GeneratedColumn<String>(
    'claim_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentIdMeta = const VerificationMeta(
    'segmentId',
  );
  @override
  late final GeneratedColumn<String> segmentId = GeneratedColumn<String>(
    'segment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quoteMeta = const VerificationMeta('quote');
  @override
  late final GeneratedColumn<String> quote = GeneratedColumn<String>(
    'quote',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    claimId,
    ordinal,
    segmentId,
    startMs,
    endMs,
    quote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'claim_evidence';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClaimEvidenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('claim_id')) {
      context.handle(
        _claimIdMeta,
        claimId.isAcceptableOrUnknown(data['claim_id']!, _claimIdMeta),
      );
    } else if (isInserting) {
      context.missing(_claimIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('segment_id')) {
      context.handle(
        _segmentIdMeta,
        segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentIdMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    if (data.containsKey('quote')) {
      context.handle(
        _quoteMeta,
        quote.isAcceptableOrUnknown(data['quote']!, _quoteMeta),
      );
    } else if (isInserting) {
      context.missing(_quoteMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {claimId, ordinal};
  @override
  ClaimEvidenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClaimEvidenceRow(
      claimId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claim_id'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      segmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_id'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      )!,
      quote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote'],
      )!,
    );
  }

  @override
  $ClaimEvidenceTable createAlias(String alias) {
    return $ClaimEvidenceTable(attachedDatabase, alias);
  }
}

class ClaimEvidenceRow extends DataClass
    implements Insertable<ClaimEvidenceRow> {
  final String claimId;
  final int ordinal;
  final String segmentId;
  final int startMs;
  final int endMs;
  final String quote;
  const ClaimEvidenceRow({
    required this.claimId,
    required this.ordinal,
    required this.segmentId,
    required this.startMs,
    required this.endMs,
    required this.quote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['claim_id'] = Variable<String>(claimId);
    map['ordinal'] = Variable<int>(ordinal);
    map['segment_id'] = Variable<String>(segmentId);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    map['quote'] = Variable<String>(quote);
    return map;
  }

  ClaimEvidenceCompanion toCompanion(bool nullToAbsent) {
    return ClaimEvidenceCompanion(
      claimId: Value(claimId),
      ordinal: Value(ordinal),
      segmentId: Value(segmentId),
      startMs: Value(startMs),
      endMs: Value(endMs),
      quote: Value(quote),
    );
  }

  factory ClaimEvidenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClaimEvidenceRow(
      claimId: serializer.fromJson<String>(json['claimId']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      segmentId: serializer.fromJson<String>(json['segmentId']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
      quote: serializer.fromJson<String>(json['quote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'claimId': serializer.toJson<String>(claimId),
      'ordinal': serializer.toJson<int>(ordinal),
      'segmentId': serializer.toJson<String>(segmentId),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
      'quote': serializer.toJson<String>(quote),
    };
  }

  ClaimEvidenceRow copyWith({
    String? claimId,
    int? ordinal,
    String? segmentId,
    int? startMs,
    int? endMs,
    String? quote,
  }) => ClaimEvidenceRow(
    claimId: claimId ?? this.claimId,
    ordinal: ordinal ?? this.ordinal,
    segmentId: segmentId ?? this.segmentId,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
    quote: quote ?? this.quote,
  );
  ClaimEvidenceRow copyWithCompanion(ClaimEvidenceCompanion data) {
    return ClaimEvidenceRow(
      claimId: data.claimId.present ? data.claimId.value : this.claimId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      quote: data.quote.present ? data.quote.value : this.quote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClaimEvidenceRow(')
          ..write('claimId: $claimId, ')
          ..write('ordinal: $ordinal, ')
          ..write('segmentId: $segmentId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('quote: $quote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(claimId, ordinal, segmentId, startMs, endMs, quote);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClaimEvidenceRow &&
          other.claimId == this.claimId &&
          other.ordinal == this.ordinal &&
          other.segmentId == this.segmentId &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.quote == this.quote);
}

class ClaimEvidenceCompanion extends UpdateCompanion<ClaimEvidenceRow> {
  final Value<String> claimId;
  final Value<int> ordinal;
  final Value<String> segmentId;
  final Value<int> startMs;
  final Value<int> endMs;
  final Value<String> quote;
  final Value<int> rowid;
  const ClaimEvidenceCompanion({
    this.claimId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.segmentId = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.quote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClaimEvidenceCompanion.insert({
    required String claimId,
    required int ordinal,
    required String segmentId,
    required int startMs,
    required int endMs,
    required String quote,
    this.rowid = const Value.absent(),
  }) : claimId = Value(claimId),
       ordinal = Value(ordinal),
       segmentId = Value(segmentId),
       startMs = Value(startMs),
       endMs = Value(endMs),
       quote = Value(quote);
  static Insertable<ClaimEvidenceRow> custom({
    Expression<String>? claimId,
    Expression<int>? ordinal,
    Expression<String>? segmentId,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<String>? quote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (claimId != null) 'claim_id': claimId,
      if (ordinal != null) 'ordinal': ordinal,
      if (segmentId != null) 'segment_id': segmentId,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (quote != null) 'quote': quote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClaimEvidenceCompanion copyWith({
    Value<String>? claimId,
    Value<int>? ordinal,
    Value<String>? segmentId,
    Value<int>? startMs,
    Value<int>? endMs,
    Value<String>? quote,
    Value<int>? rowid,
  }) {
    return ClaimEvidenceCompanion(
      claimId: claimId ?? this.claimId,
      ordinal: ordinal ?? this.ordinal,
      segmentId: segmentId ?? this.segmentId,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      quote: quote ?? this.quote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (claimId.present) {
      map['claim_id'] = Variable<String>(claimId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (segmentId.present) {
      map['segment_id'] = Variable<String>(segmentId.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (quote.present) {
      map['quote'] = Variable<String>(quote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClaimEvidenceCompanion(')
          ..write('claimId: $claimId, ')
          ..write('ordinal: $ordinal, ')
          ..write('segmentId: $segmentId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('quote: $quote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TranscriptsTable transcripts = $TranscriptsTable(this);
  late final $TranscriptSegmentsTable transcriptSegments =
      $TranscriptSegmentsTable(this);
  late final $AnalysesTable analyses = $AnalysesTable(this);
  late final $ClaimsTable claims = $ClaimsTable(this);
  late final $ClaimEvidenceTable claimEvidence = $ClaimEvidenceTable(this);
  late final Index segmentsByRecording = Index(
    'segments_by_recording',
    'CREATE INDEX segments_by_recording ON transcript_segments (recording_id)',
  );
  late final Index claimsByRecording = Index(
    'claims_by_recording',
    'CREATE INDEX claims_by_recording ON claims (recording_id)',
  );
  late final Index evidenceByClaim = Index(
    'evidence_by_claim',
    'CREATE INDEX evidence_by_claim ON claim_evidence (claim_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transcripts,
    transcriptSegments,
    analyses,
    claims,
    claimEvidence,
    segmentsByRecording,
    claimsByRecording,
    evidenceByClaim,
  ];
}

typedef $$TranscriptsTableCreateCompanionBuilder =
    TranscriptsCompanion Function({
      required String recordingId,
      required DateTime createdAt,
      required String source,
      Value<int> rowid,
    });
typedef $$TranscriptsTableUpdateCompanionBuilder =
    TranscriptsCompanion Function({
      Value<String> recordingId,
      Value<DateTime> createdAt,
      Value<String> source,
      Value<int> rowid,
    });

class $$TranscriptsTableFilterComposer
    extends Composer<_$AppDatabase, $TranscriptsTable> {
  $$TranscriptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TranscriptsTableOrderingComposer
    extends Composer<_$AppDatabase, $TranscriptsTable> {
  $$TranscriptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TranscriptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranscriptsTable> {
  $$TranscriptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$TranscriptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranscriptsTable,
          TranscriptRow,
          $$TranscriptsTableFilterComposer,
          $$TranscriptsTableOrderingComposer,
          $$TranscriptsTableAnnotationComposer,
          $$TranscriptsTableCreateCompanionBuilder,
          $$TranscriptsTableUpdateCompanionBuilder,
          (
            TranscriptRow,
            BaseReferences<_$AppDatabase, $TranscriptsTable, TranscriptRow>,
          ),
          TranscriptRow,
          PrefetchHooks Function()
        > {
  $$TranscriptsTableTableManager(_$AppDatabase db, $TranscriptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranscriptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranscriptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranscriptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recordingId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranscriptsCompanion(
                recordingId: recordingId,
                createdAt: createdAt,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordingId,
                required DateTime createdAt,
                required String source,
                Value<int> rowid = const Value.absent(),
              }) => TranscriptsCompanion.insert(
                recordingId: recordingId,
                createdAt: createdAt,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TranscriptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranscriptsTable,
      TranscriptRow,
      $$TranscriptsTableFilterComposer,
      $$TranscriptsTableOrderingComposer,
      $$TranscriptsTableAnnotationComposer,
      $$TranscriptsTableCreateCompanionBuilder,
      $$TranscriptsTableUpdateCompanionBuilder,
      (
        TranscriptRow,
        BaseReferences<_$AppDatabase, $TranscriptsTable, TranscriptRow>,
      ),
      TranscriptRow,
      PrefetchHooks Function()
    >;
typedef $$TranscriptSegmentsTableCreateCompanionBuilder =
    TranscriptSegmentsCompanion Function({
      required String id,
      required String recordingId,
      required int startMs,
      required int endMs,
      required String content,
      Value<double?> confidence,
      Value<int> rowid,
    });
typedef $$TranscriptSegmentsTableUpdateCompanionBuilder =
    TranscriptSegmentsCompanion Function({
      Value<String> id,
      Value<String> recordingId,
      Value<int> startMs,
      Value<int> endMs,
      Value<String> content,
      Value<double?> confidence,
      Value<int> rowid,
    });

class $$TranscriptSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $TranscriptSegmentsTable> {
  $$TranscriptSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TranscriptSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $TranscriptSegmentsTable> {
  $$TranscriptSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TranscriptSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranscriptSegmentsTable> {
  $$TranscriptSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );
}

class $$TranscriptSegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranscriptSegmentsTable,
          TranscriptSegmentRow,
          $$TranscriptSegmentsTableFilterComposer,
          $$TranscriptSegmentsTableOrderingComposer,
          $$TranscriptSegmentsTableAnnotationComposer,
          $$TranscriptSegmentsTableCreateCompanionBuilder,
          $$TranscriptSegmentsTableUpdateCompanionBuilder,
          (
            TranscriptSegmentRow,
            BaseReferences<
              _$AppDatabase,
              $TranscriptSegmentsTable,
              TranscriptSegmentRow
            >,
          ),
          TranscriptSegmentRow,
          PrefetchHooks Function()
        > {
  $$TranscriptSegmentsTableTableManager(
    _$AppDatabase db,
    $TranscriptSegmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranscriptSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranscriptSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranscriptSegmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recordingId = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int> endMs = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranscriptSegmentsCompanion(
                id: id,
                recordingId: recordingId,
                startMs: startMs,
                endMs: endMs,
                content: content,
                confidence: confidence,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recordingId,
                required int startMs,
                required int endMs,
                required String content,
                Value<double?> confidence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranscriptSegmentsCompanion.insert(
                id: id,
                recordingId: recordingId,
                startMs: startMs,
                endMs: endMs,
                content: content,
                confidence: confidence,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TranscriptSegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranscriptSegmentsTable,
      TranscriptSegmentRow,
      $$TranscriptSegmentsTableFilterComposer,
      $$TranscriptSegmentsTableOrderingComposer,
      $$TranscriptSegmentsTableAnnotationComposer,
      $$TranscriptSegmentsTableCreateCompanionBuilder,
      $$TranscriptSegmentsTableUpdateCompanionBuilder,
      (
        TranscriptSegmentRow,
        BaseReferences<
          _$AppDatabase,
          $TranscriptSegmentsTable,
          TranscriptSegmentRow
        >,
      ),
      TranscriptSegmentRow,
      PrefetchHooks Function()
    >;
typedef $$AnalysesTableCreateCompanionBuilder = AnalysesCompanion Function({
  required String recordingId,
  required DateTime createdAt,
  required String source,
  required int droppedCount,
  Value<int> rowid,
});
typedef $$AnalysesTableUpdateCompanionBuilder = AnalysesCompanion Function({
  Value<String> recordingId,
  Value<DateTime> createdAt,
  Value<String> source,
  Value<int> droppedCount,
  Value<int> rowid,
});

class $$AnalysesTableFilterComposer
    extends Composer<_$AppDatabase, $AnalysesTable> {
  $$AnalysesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get droppedCount => $composableBuilder(
    column: $table.droppedCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnalysesTableOrderingComposer
    extends Composer<_$AppDatabase, $AnalysesTable> {
  $$AnalysesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get droppedCount => $composableBuilder(
    column: $table.droppedCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnalysesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnalysesTable> {
  $$AnalysesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get droppedCount => $composableBuilder(
    column: $table.droppedCount,
    builder: (column) => column,
  );
}

class $$AnalysesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnalysesTable,
          AnalysisRow,
          $$AnalysesTableFilterComposer,
          $$AnalysesTableOrderingComposer,
          $$AnalysesTableAnnotationComposer,
          $$AnalysesTableCreateCompanionBuilder,
          $$AnalysesTableUpdateCompanionBuilder,
          (
            AnalysisRow,
            BaseReferences<_$AppDatabase, $AnalysesTable, AnalysisRow>,
          ),
          AnalysisRow,
          PrefetchHooks Function()
        > {
  $$AnalysesTableTableManager(_$AppDatabase db, $AnalysesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalysesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalysesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalysesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recordingId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> droppedCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnalysesCompanion(
                recordingId: recordingId,
                createdAt: createdAt,
                source: source,
                droppedCount: droppedCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordingId,
                required DateTime createdAt,
                required String source,
                required int droppedCount,
                Value<int> rowid = const Value.absent(),
              }) => AnalysesCompanion.insert(
                recordingId: recordingId,
                createdAt: createdAt,
                source: source,
                droppedCount: droppedCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnalysesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnalysesTable,
      AnalysisRow,
      $$AnalysesTableFilterComposer,
      $$AnalysesTableOrderingComposer,
      $$AnalysesTableAnnotationComposer,
      $$AnalysesTableCreateCompanionBuilder,
      $$AnalysesTableUpdateCompanionBuilder,
      (AnalysisRow, BaseReferences<_$AppDatabase, $AnalysesTable, AnalysisRow>),
      AnalysisRow,
      PrefetchHooks Function()
    >;
typedef $$ClaimsTableCreateCompanionBuilder = ClaimsCompanion Function({
  required String id,
  required String recordingId,
  required String type,
  required String category,
  required String content,
  Value<String?> reasoning,
  required String confidence,
  required String missingInfo,
  Value<String?> owner,
  Value<String?> dueDate,
  required String entityIds,
  required String userAction,
  required DateTime createdAt,
  required String source,
  Value<int> rowid,
});
typedef $$ClaimsTableUpdateCompanionBuilder = ClaimsCompanion Function({
  Value<String> id,
  Value<String> recordingId,
  Value<String> type,
  Value<String> category,
  Value<String> content,
  Value<String?> reasoning,
  Value<String> confidence,
  Value<String> missingInfo,
  Value<String?> owner,
  Value<String?> dueDate,
  Value<String> entityIds,
  Value<String> userAction,
  Value<DateTime> createdAt,
  Value<String> source,
  Value<int> rowid,
});

class $$ClaimsTableFilterComposer
    extends Composer<_$AppDatabase, $ClaimsTable> {
  $$ClaimsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missingInfo => $composableBuilder(
    column: $table.missingInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityIds => $composableBuilder(
    column: $table.entityIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAction => $composableBuilder(
    column: $table.userAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClaimsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClaimsTable> {
  $$ClaimsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasoning => $composableBuilder(
    column: $table.reasoning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missingInfo => $composableBuilder(
    column: $table.missingInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityIds => $composableBuilder(
    column: $table.entityIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAction => $composableBuilder(
    column: $table.userAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClaimsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClaimsTable> {
  $$ClaimsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get reasoning =>
      $composableBuilder(column: $table.reasoning, builder: (column) => column);

  GeneratedColumn<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get missingInfo => $composableBuilder(
    column: $table.missingInfo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get entityIds =>
      $composableBuilder(column: $table.entityIds, builder: (column) => column);

  GeneratedColumn<String> get userAction => $composableBuilder(
    column: $table.userAction,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$ClaimsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClaimsTable,
          ClaimRow,
          $$ClaimsTableFilterComposer,
          $$ClaimsTableOrderingComposer,
          $$ClaimsTableAnnotationComposer,
          $$ClaimsTableCreateCompanionBuilder,
          $$ClaimsTableUpdateCompanionBuilder,
          (ClaimRow, BaseReferences<_$AppDatabase, $ClaimsTable, ClaimRow>),
          ClaimRow,
          PrefetchHooks Function()
        > {
  $$ClaimsTableTableManager(_$AppDatabase db, $ClaimsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClaimsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClaimsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClaimsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recordingId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> reasoning = const Value.absent(),
                Value<String> confidence = const Value.absent(),
                Value<String> missingInfo = const Value.absent(),
                Value<String?> owner = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String> entityIds = const Value.absent(),
                Value<String> userAction = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClaimsCompanion(
                id: id,
                recordingId: recordingId,
                type: type,
                category: category,
                content: content,
                reasoning: reasoning,
                confidence: confidence,
                missingInfo: missingInfo,
                owner: owner,
                dueDate: dueDate,
                entityIds: entityIds,
                userAction: userAction,
                createdAt: createdAt,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recordingId,
                required String type,
                required String category,
                required String content,
                Value<String?> reasoning = const Value.absent(),
                required String confidence,
                required String missingInfo,
                Value<String?> owner = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                required String entityIds,
                required String userAction,
                required DateTime createdAt,
                required String source,
                Value<int> rowid = const Value.absent(),
              }) => ClaimsCompanion.insert(
                id: id,
                recordingId: recordingId,
                type: type,
                category: category,
                content: content,
                reasoning: reasoning,
                confidence: confidence,
                missingInfo: missingInfo,
                owner: owner,
                dueDate: dueDate,
                entityIds: entityIds,
                userAction: userAction,
                createdAt: createdAt,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClaimsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClaimsTable,
      ClaimRow,
      $$ClaimsTableFilterComposer,
      $$ClaimsTableOrderingComposer,
      $$ClaimsTableAnnotationComposer,
      $$ClaimsTableCreateCompanionBuilder,
      $$ClaimsTableUpdateCompanionBuilder,
      (ClaimRow, BaseReferences<_$AppDatabase, $ClaimsTable, ClaimRow>),
      ClaimRow,
      PrefetchHooks Function()
    >;
typedef $$ClaimEvidenceTableCreateCompanionBuilder =
    ClaimEvidenceCompanion Function({
      required String claimId,
      required int ordinal,
      required String segmentId,
      required int startMs,
      required int endMs,
      required String quote,
      Value<int> rowid,
    });
typedef $$ClaimEvidenceTableUpdateCompanionBuilder =
    ClaimEvidenceCompanion Function({
      Value<String> claimId,
      Value<int> ordinal,
      Value<String> segmentId,
      Value<int> startMs,
      Value<int> endMs,
      Value<String> quote,
      Value<int> rowid,
    });

class $$ClaimEvidenceTableFilterComposer
    extends Composer<_$AppDatabase, $ClaimEvidenceTable> {
  $$ClaimEvidenceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get claimId => $composableBuilder(
    column: $table.claimId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quote => $composableBuilder(
    column: $table.quote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClaimEvidenceTableOrderingComposer
    extends Composer<_$AppDatabase, $ClaimEvidenceTable> {
  $$ClaimEvidenceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get claimId => $composableBuilder(
    column: $table.claimId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quote => $composableBuilder(
    column: $table.quote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClaimEvidenceTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClaimEvidenceTable> {
  $$ClaimEvidenceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get claimId =>
      $composableBuilder(column: $table.claimId, builder: (column) => column);

  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<String> get segmentId =>
      $composableBuilder(column: $table.segmentId, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  GeneratedColumn<String> get quote =>
      $composableBuilder(column: $table.quote, builder: (column) => column);
}

class $$ClaimEvidenceTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClaimEvidenceTable,
          ClaimEvidenceRow,
          $$ClaimEvidenceTableFilterComposer,
          $$ClaimEvidenceTableOrderingComposer,
          $$ClaimEvidenceTableAnnotationComposer,
          $$ClaimEvidenceTableCreateCompanionBuilder,
          $$ClaimEvidenceTableUpdateCompanionBuilder,
          (
            ClaimEvidenceRow,
            BaseReferences<
              _$AppDatabase,
              $ClaimEvidenceTable,
              ClaimEvidenceRow
            >,
          ),
          ClaimEvidenceRow,
          PrefetchHooks Function()
        > {
  $$ClaimEvidenceTableTableManager(_$AppDatabase db, $ClaimEvidenceTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClaimEvidenceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClaimEvidenceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClaimEvidenceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> claimId = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<String> segmentId = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int> endMs = const Value.absent(),
                Value<String> quote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClaimEvidenceCompanion(
                claimId: claimId,
                ordinal: ordinal,
                segmentId: segmentId,
                startMs: startMs,
                endMs: endMs,
                quote: quote,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String claimId,
                required int ordinal,
                required String segmentId,
                required int startMs,
                required int endMs,
                required String quote,
                Value<int> rowid = const Value.absent(),
              }) => ClaimEvidenceCompanion.insert(
                claimId: claimId,
                ordinal: ordinal,
                segmentId: segmentId,
                startMs: startMs,
                endMs: endMs,
                quote: quote,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClaimEvidenceTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClaimEvidenceTable,
      ClaimEvidenceRow,
      $$ClaimEvidenceTableFilterComposer,
      $$ClaimEvidenceTableOrderingComposer,
      $$ClaimEvidenceTableAnnotationComposer,
      $$ClaimEvidenceTableCreateCompanionBuilder,
      $$ClaimEvidenceTableUpdateCompanionBuilder,
      (
        ClaimEvidenceRow,
        BaseReferences<_$AppDatabase, $ClaimEvidenceTable, ClaimEvidenceRow>,
      ),
      ClaimEvidenceRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TranscriptsTableTableManager get transcripts =>
      $$TranscriptsTableTableManager(_db, _db.transcripts);
  $$TranscriptSegmentsTableTableManager get transcriptSegments =>
      $$TranscriptSegmentsTableTableManager(_db, _db.transcriptSegments);
  $$AnalysesTableTableManager get analyses =>
      $$AnalysesTableTableManager(_db, _db.analyses);
  $$ClaimsTableTableManager get claims =>
      $$ClaimsTableTableManager(_db, _db.claims);
  $$ClaimEvidenceTableTableManager get claimEvidence =>
      $$ClaimEvidenceTableTableManager(_db, _db.claimEvidence);
}
