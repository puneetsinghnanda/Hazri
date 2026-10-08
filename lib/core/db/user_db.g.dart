// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_db.dart';

// ignore_for_file: type=lint
class $ReadingProgressTable extends ReadingProgress
    with TableInfo<$ReadingProgressTable, ReadingProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _baniVersionIdMeta = const VerificationMeta(
    'baniVersionId',
  );
  @override
  late final GeneratedColumn<String> baniVersionId = GeneratedColumn<String>(
    'bani_version_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineIdxMeta = const VerificationMeta(
    'lineIdx',
  );
  @override
  late final GeneratedColumn<int> lineIdx = GeneratedColumn<int>(
    'line_idx',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _audioPosMsMeta = const VerificationMeta(
    'audioPosMs',
  );
  @override
  late final GeneratedColumn<int> audioPosMs = GeneratedColumn<int>(
    'audio_pos_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    baniVersionId,
    lineIdx,
    audioPosMs,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bani_version_id')) {
      context.handle(
        _baniVersionIdMeta,
        baniVersionId.isAcceptableOrUnknown(
          data['bani_version_id']!,
          _baniVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baniVersionIdMeta);
    }
    if (data.containsKey('line_idx')) {
      context.handle(
        _lineIdxMeta,
        lineIdx.isAcceptableOrUnknown(data['line_idx']!, _lineIdxMeta),
      );
    }
    if (data.containsKey('audio_pos_ms')) {
      context.handle(
        _audioPosMsMeta,
        audioPosMs.isAcceptableOrUnknown(
          data['audio_pos_ms']!,
          _audioPosMsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {baniVersionId};
  @override
  ReadingProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingProgressData(
      baniVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bani_version_id'],
      )!,
      lineIdx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_idx'],
      )!,
      audioPosMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}audio_pos_ms'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReadingProgressTable createAlias(String alias) {
    return $ReadingProgressTable(attachedDatabase, alias);
  }
}

class ReadingProgressData extends DataClass
    implements Insertable<ReadingProgressData> {
  final String baniVersionId;
  final int lineIdx;
  final int audioPosMs;
  final DateTime updatedAt;
  const ReadingProgressData({
    required this.baniVersionId,
    required this.lineIdx,
    required this.audioPosMs,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bani_version_id'] = Variable<String>(baniVersionId);
    map['line_idx'] = Variable<int>(lineIdx);
    map['audio_pos_ms'] = Variable<int>(audioPosMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReadingProgressCompanion toCompanion(bool nullToAbsent) {
    return ReadingProgressCompanion(
      baniVersionId: Value(baniVersionId),
      lineIdx: Value(lineIdx),
      audioPosMs: Value(audioPosMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReadingProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingProgressData(
      baniVersionId: serializer.fromJson<String>(json['baniVersionId']),
      lineIdx: serializer.fromJson<int>(json['lineIdx']),
      audioPosMs: serializer.fromJson<int>(json['audioPosMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'baniVersionId': serializer.toJson<String>(baniVersionId),
      'lineIdx': serializer.toJson<int>(lineIdx),
      'audioPosMs': serializer.toJson<int>(audioPosMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReadingProgressData copyWith({
    String? baniVersionId,
    int? lineIdx,
    int? audioPosMs,
    DateTime? updatedAt,
  }) => ReadingProgressData(
    baniVersionId: baniVersionId ?? this.baniVersionId,
    lineIdx: lineIdx ?? this.lineIdx,
    audioPosMs: audioPosMs ?? this.audioPosMs,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReadingProgressData copyWithCompanion(ReadingProgressCompanion data) {
    return ReadingProgressData(
      baniVersionId: data.baniVersionId.present
          ? data.baniVersionId.value
          : this.baniVersionId,
      lineIdx: data.lineIdx.present ? data.lineIdx.value : this.lineIdx,
      audioPosMs: data.audioPosMs.present
          ? data.audioPosMs.value
          : this.audioPosMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressData(')
          ..write('baniVersionId: $baniVersionId, ')
          ..write('lineIdx: $lineIdx, ')
          ..write('audioPosMs: $audioPosMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(baniVersionId, lineIdx, audioPosMs, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgressData &&
          other.baniVersionId == this.baniVersionId &&
          other.lineIdx == this.lineIdx &&
          other.audioPosMs == this.audioPosMs &&
          other.updatedAt == this.updatedAt);
}

class ReadingProgressCompanion extends UpdateCompanion<ReadingProgressData> {
  final Value<String> baniVersionId;
  final Value<int> lineIdx;
  final Value<int> audioPosMs;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReadingProgressCompanion({
    this.baniVersionId = const Value.absent(),
    this.lineIdx = const Value.absent(),
    this.audioPosMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingProgressCompanion.insert({
    required String baniVersionId,
    this.lineIdx = const Value.absent(),
    this.audioPosMs = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : baniVersionId = Value(baniVersionId),
       updatedAt = Value(updatedAt);
  static Insertable<ReadingProgressData> custom({
    Expression<String>? baniVersionId,
    Expression<int>? lineIdx,
    Expression<int>? audioPosMs,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (baniVersionId != null) 'bani_version_id': baniVersionId,
      if (lineIdx != null) 'line_idx': lineIdx,
      if (audioPosMs != null) 'audio_pos_ms': audioPosMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingProgressCompanion copyWith({
    Value<String>? baniVersionId,
    Value<int>? lineIdx,
    Value<int>? audioPosMs,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReadingProgressCompanion(
      baniVersionId: baniVersionId ?? this.baniVersionId,
      lineIdx: lineIdx ?? this.lineIdx,
      audioPosMs: audioPosMs ?? this.audioPosMs,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (baniVersionId.present) {
      map['bani_version_id'] = Variable<String>(baniVersionId.value);
    }
    if (lineIdx.present) {
      map['line_idx'] = Variable<int>(lineIdx.value);
    }
    if (audioPosMs.present) {
      map['audio_pos_ms'] = Variable<int>(audioPosMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressCompanion(')
          ..write('baniVersionId: $baniVersionId, ')
          ..write('lineIdx: $lineIdx, ')
          ..write('audioPosMs: $audioPosMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompletionsTable extends Completions
    with TableInfo<$CompletionsTable, Completion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baniIdMeta = const VerificationMeta('baniId');
  @override
  late final GeneratedColumn<String> baniId = GeneratedColumn<String>(
    'bani_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BaniSlotValue, String> slot =
      GeneratedColumn<String>(
        'slot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BaniSlotValue>($CompletionsTable.$converterslot);
  @override
  late final GeneratedColumnWithTypeConverter<CompletionSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CompletionSource>($CompletionsTable.$convertersource);
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localDate,
    baniId,
    slot,
    source,
    completedAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Completion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('bani_id')) {
      context.handle(
        _baniIdMeta,
        baniId.isAcceptableOrUnknown(data['bani_id']!, _baniIdMeta),
      );
    } else if (isInserting) {
      context.missing(_baniIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Completion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Completion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      baniId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bani_id'],
      )!,
      slot: $CompletionsTable.$converterslot.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}slot'],
        )!,
      ),
      source: $CompletionsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CompletionsTable createAlias(String alias) {
    return $CompletionsTable(attachedDatabase, alias);
  }

  static TypeConverter<BaniSlotValue, String> $converterslot = const UpperSnake(
    BaniSlotValue.values,
  );
  static TypeConverter<CompletionSource, String> $convertersource =
      const UpperSnake(CompletionSource.values);
}

class Completion extends DataClass implements Insertable<Completion> {
  final String id;
  final String localDate;
  final String baniId;
  final BaniSlotValue slot;
  final CompletionSource source;
  final DateTime completedAt;
  final DateTime updatedAt;

  /// Set by Diary − (CR3). A row with it set is ignored everywhere.
  final DateTime? deletedAt;
  const Completion({
    required this.id,
    required this.localDate,
    required this.baniId,
    required this.slot,
    required this.source,
    required this.completedAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_date'] = Variable<String>(localDate);
    map['bani_id'] = Variable<String>(baniId);
    {
      map['slot'] = Variable<String>(
        $CompletionsTable.$converterslot.toSql(slot),
      );
    }
    {
      map['source'] = Variable<String>(
        $CompletionsTable.$convertersource.toSql(source),
      );
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CompletionsCompanion toCompanion(bool nullToAbsent) {
    return CompletionsCompanion(
      id: Value(id),
      localDate: Value(localDate),
      baniId: Value(baniId),
      slot: Value(slot),
      source: Value(source),
      completedAt: Value(completedAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Completion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Completion(
      id: serializer.fromJson<String>(json['id']),
      localDate: serializer.fromJson<String>(json['localDate']),
      baniId: serializer.fromJson<String>(json['baniId']),
      slot: serializer.fromJson<BaniSlotValue>(json['slot']),
      source: serializer.fromJson<CompletionSource>(json['source']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localDate': serializer.toJson<String>(localDate),
      'baniId': serializer.toJson<String>(baniId),
      'slot': serializer.toJson<BaniSlotValue>(slot),
      'source': serializer.toJson<CompletionSource>(source),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Completion copyWith({
    String? id,
    String? localDate,
    String? baniId,
    BaniSlotValue? slot,
    CompletionSource? source,
    DateTime? completedAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Completion(
    id: id ?? this.id,
    localDate: localDate ?? this.localDate,
    baniId: baniId ?? this.baniId,
    slot: slot ?? this.slot,
    source: source ?? this.source,
    completedAt: completedAt ?? this.completedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Completion copyWithCompanion(CompletionsCompanion data) {
    return Completion(
      id: data.id.present ? data.id.value : this.id,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      baniId: data.baniId.present ? data.baniId.value : this.baniId,
      slot: data.slot.present ? data.slot.value : this.slot,
      source: data.source.present ? data.source.value : this.source,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Completion(')
          ..write('id: $id, ')
          ..write('localDate: $localDate, ')
          ..write('baniId: $baniId, ')
          ..write('slot: $slot, ')
          ..write('source: $source, ')
          ..write('completedAt: $completedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localDate,
    baniId,
    slot,
    source,
    completedAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Completion &&
          other.id == this.id &&
          other.localDate == this.localDate &&
          other.baniId == this.baniId &&
          other.slot == this.slot &&
          other.source == this.source &&
          other.completedAt == this.completedAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CompletionsCompanion extends UpdateCompanion<Completion> {
  final Value<String> id;
  final Value<String> localDate;
  final Value<String> baniId;
  final Value<BaniSlotValue> slot;
  final Value<CompletionSource> source;
  final Value<DateTime> completedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CompletionsCompanion({
    this.id = const Value.absent(),
    this.localDate = const Value.absent(),
    this.baniId = const Value.absent(),
    this.slot = const Value.absent(),
    this.source = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompletionsCompanion.insert({
    required String id,
    required String localDate,
    required String baniId,
    required BaniSlotValue slot,
    required CompletionSource source,
    required DateTime completedAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localDate = Value(localDate),
       baniId = Value(baniId),
       slot = Value(slot),
       source = Value(source),
       completedAt = Value(completedAt),
       updatedAt = Value(updatedAt);
  static Insertable<Completion> custom({
    Expression<String>? id,
    Expression<String>? localDate,
    Expression<String>? baniId,
    Expression<String>? slot,
    Expression<String>? source,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localDate != null) 'local_date': localDate,
      if (baniId != null) 'bani_id': baniId,
      if (slot != null) 'slot': slot,
      if (source != null) 'source': source,
      if (completedAt != null) 'completed_at': completedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompletionsCompanion copyWith({
    Value<String>? id,
    Value<String>? localDate,
    Value<String>? baniId,
    Value<BaniSlotValue>? slot,
    Value<CompletionSource>? source,
    Value<DateTime>? completedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CompletionsCompanion(
      id: id ?? this.id,
      localDate: localDate ?? this.localDate,
      baniId: baniId ?? this.baniId,
      slot: slot ?? this.slot,
      source: source ?? this.source,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (baniId.present) {
      map['bani_id'] = Variable<String>(baniId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(
        $CompletionsTable.$converterslot.toSql(slot.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $CompletionsTable.$convertersource.toSql(source.value),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionsCompanion(')
          ..write('id: $id, ')
          ..write('localDate: $localDate, ')
          ..write('baniId: $baniId, ')
          ..write('slot: $slot, ')
          ..write('source: $source, ')
          ..write('completedAt: $completedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SimranSessionsTable extends SimranSessions
    with TableInfo<$SimranSessionsTable, SimranSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SimranSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSMeta = const VerificationMeta(
    'durationS',
  );
  @override
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
    'duration_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SittingSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SittingSource>($SimranSessionsTable.$convertersource);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localDate,
    startedAt,
    durationS,
    count,
    completed,
    source,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'simran_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SimranSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('duration_s')) {
      context.handle(
        _durationSMeta,
        durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta),
      );
    } else if (isInserting) {
      context.missing(_durationSMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SimranSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SimranSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      durationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_s'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      source: $SimranSessionsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SimranSessionsTable createAlias(String alias) {
    return $SimranSessionsTable(attachedDatabase, alias);
  }

  static TypeConverter<SittingSource, String> $convertersource =
      const UpperSnake(SittingSource.values);
}

class SimranSession extends DataClass implements Insertable<SimranSession> {
  final String id;
  final String localDate;
  final DateTime startedAt;
  final int durationS;
  final int count;

  /// True when the sitting reached the timer's planned length.
  final bool completed;
  final SittingSource source;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const SimranSession({
    required this.id,
    required this.localDate,
    required this.startedAt,
    required this.durationS,
    required this.count,
    required this.completed,
    required this.source,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_date'] = Variable<String>(localDate);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['duration_s'] = Variable<int>(durationS);
    map['count'] = Variable<int>(count);
    map['completed'] = Variable<bool>(completed);
    {
      map['source'] = Variable<String>(
        $SimranSessionsTable.$convertersource.toSql(source),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SimranSessionsCompanion toCompanion(bool nullToAbsent) {
    return SimranSessionsCompanion(
      id: Value(id),
      localDate: Value(localDate),
      startedAt: Value(startedAt),
      durationS: Value(durationS),
      count: Value(count),
      completed: Value(completed),
      source: Value(source),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SimranSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SimranSession(
      id: serializer.fromJson<String>(json['id']),
      localDate: serializer.fromJson<String>(json['localDate']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      durationS: serializer.fromJson<int>(json['durationS']),
      count: serializer.fromJson<int>(json['count']),
      completed: serializer.fromJson<bool>(json['completed']),
      source: serializer.fromJson<SittingSource>(json['source']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localDate': serializer.toJson<String>(localDate),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'durationS': serializer.toJson<int>(durationS),
      'count': serializer.toJson<int>(count),
      'completed': serializer.toJson<bool>(completed),
      'source': serializer.toJson<SittingSource>(source),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SimranSession copyWith({
    String? id,
    String? localDate,
    DateTime? startedAt,
    int? durationS,
    int? count,
    bool? completed,
    SittingSource? source,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SimranSession(
    id: id ?? this.id,
    localDate: localDate ?? this.localDate,
    startedAt: startedAt ?? this.startedAt,
    durationS: durationS ?? this.durationS,
    count: count ?? this.count,
    completed: completed ?? this.completed,
    source: source ?? this.source,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SimranSession copyWithCompanion(SimranSessionsCompanion data) {
    return SimranSession(
      id: data.id.present ? data.id.value : this.id,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      count: data.count.present ? data.count.value : this.count,
      completed: data.completed.present ? data.completed.value : this.completed,
      source: data.source.present ? data.source.value : this.source,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SimranSession(')
          ..write('id: $id, ')
          ..write('localDate: $localDate, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationS: $durationS, ')
          ..write('count: $count, ')
          ..write('completed: $completed, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localDate,
    startedAt,
    durationS,
    count,
    completed,
    source,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SimranSession &&
          other.id == this.id &&
          other.localDate == this.localDate &&
          other.startedAt == this.startedAt &&
          other.durationS == this.durationS &&
          other.count == this.count &&
          other.completed == this.completed &&
          other.source == this.source &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SimranSessionsCompanion extends UpdateCompanion<SimranSession> {
  final Value<String> id;
  final Value<String> localDate;
  final Value<DateTime> startedAt;
  final Value<int> durationS;
  final Value<int> count;
  final Value<bool> completed;
  final Value<SittingSource> source;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SimranSessionsCompanion({
    this.id = const Value.absent(),
    this.localDate = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationS = const Value.absent(),
    this.count = const Value.absent(),
    this.completed = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SimranSessionsCompanion.insert({
    required String id,
    required String localDate,
    required DateTime startedAt,
    required int durationS,
    this.count = const Value.absent(),
    this.completed = const Value.absent(),
    required SittingSource source,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localDate = Value(localDate),
       startedAt = Value(startedAt),
       durationS = Value(durationS),
       source = Value(source),
       updatedAt = Value(updatedAt);
  static Insertable<SimranSession> custom({
    Expression<String>? id,
    Expression<String>? localDate,
    Expression<DateTime>? startedAt,
    Expression<int>? durationS,
    Expression<int>? count,
    Expression<bool>? completed,
    Expression<String>? source,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localDate != null) 'local_date': localDate,
      if (startedAt != null) 'started_at': startedAt,
      if (durationS != null) 'duration_s': durationS,
      if (count != null) 'count': count,
      if (completed != null) 'completed': completed,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SimranSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? localDate,
    Value<DateTime>? startedAt,
    Value<int>? durationS,
    Value<int>? count,
    Value<bool>? completed,
    Value<SittingSource>? source,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SimranSessionsCompanion(
      id: id ?? this.id,
      localDate: localDate ?? this.localDate,
      startedAt: startedAt ?? this.startedAt,
      durationS: durationS ?? this.durationS,
      count: count ?? this.count,
      completed: completed ?? this.completed,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $SimranSessionsTable.$convertersource.toSql(source.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SimranSessionsCompanion(')
          ..write('id: $id, ')
          ..write('localDate: $localDate, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationS: $durationS, ')
          ..write('count: $count, ')
          ..write('completed: $completed, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedOnMeta = const VerificationMeta(
    'completedOn',
  );
  @override
  late final GeneratedColumn<String> completedOn = GeneratedColumn<String>(
    'completed_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startDate,
    completedOn,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('completed_on')) {
      context.handle(
        _completedOnMeta,
        completedOn.isAcceptableOrUnknown(
          data['completed_on']!,
          _completedOnMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      completedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_on'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String startDate;

  /// The first blank day (BG1, BG2). Null while the goal is active.
  final String? completedOn;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Goal({
    required this.id,
    required this.startDate,
    this.completedOn,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || completedOn != null) {
      map['completed_on'] = Variable<String>(completedOn);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      startDate: Value(startDate),
      completedOn: completedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(completedOn),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      startDate: serializer.fromJson<String>(json['startDate']),
      completedOn: serializer.fromJson<String?>(json['completedOn']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startDate': serializer.toJson<String>(startDate),
      'completedOn': serializer.toJson<String?>(completedOn),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Goal copyWith({
    String? id,
    String? startDate,
    Value<String?> completedOn = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Goal(
    id: id ?? this.id,
    startDate: startDate ?? this.startDate,
    completedOn: completedOn.present ? completedOn.value : this.completedOn,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      completedOn: data.completedOn.present
          ? data.completedOn.value
          : this.completedOn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('completedOn: $completedOn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startDate, completedOn, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.startDate == this.startDate &&
          other.completedOn == this.completedOn &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String> startDate;
  final Value<String?> completedOn;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.startDate = const Value.absent(),
    this.completedOn = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String startDate,
    this.completedOn = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startDate = Value(startDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? startDate,
    Expression<String>? completedOn,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startDate != null) 'start_date': startDate,
      if (completedOn != null) 'completed_on': completedOn,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? startDate,
    Value<String?>? completedOn,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      completedOn: completedOn ?? this.completedOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (completedOn.present) {
      map['completed_on'] = Variable<String>(completedOn.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('completedOn: $completedOn, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalItemsTable extends GoalItems
    with TableInfo<$GoalItemsTable, GoalItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemType, String> itemType =
      GeneratedColumn<String>(
        'item_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemType>($GoalItemsTable.$converteritemType);
  static const VerificationMeta _baniIdMeta = const VerificationMeta('baniId');
  @override
  late final GeneratedColumn<String> baniId = GeneratedColumn<String>(
    'bani_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timesPerDayMeta = const VerificationMeta(
    'timesPerDay',
  );
  @override
  late final GeneratedColumn<int> timesPerDay = GeneratedColumn<int>(
    'times_per_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _simranMinutesMeta = const VerificationMeta(
    'simranMinutes',
  );
  @override
  late final GeneratedColumn<int> simranMinutes = GeneratedColumn<int>(
    'simran_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DurationType, String>
  durationType = GeneratedColumn<String>(
    'duration_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DurationType>($GoalItemsTable.$converterdurationType);
  static const VerificationMeta _durationDaysMeta = const VerificationMeta(
    'durationDays',
  );
  @override
  late final GeneratedColumn<int> durationDays = GeneratedColumn<int>(
    'duration_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _removedOnMeta = const VerificationMeta(
    'removedOn',
  );
  @override
  late final GeneratedColumn<String> removedOn = GeneratedColumn<String>(
    'removed_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    seriesId,
    itemType,
    baniId,
    timesPerDay,
    simranMinutes,
    durationType,
    durationDays,
    startDate,
    endDate,
    removedOn,
    reminderTime,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('bani_id')) {
      context.handle(
        _baniIdMeta,
        baniId.isAcceptableOrUnknown(data['bani_id']!, _baniIdMeta),
      );
    }
    if (data.containsKey('times_per_day')) {
      context.handle(
        _timesPerDayMeta,
        timesPerDay.isAcceptableOrUnknown(
          data['times_per_day']!,
          _timesPerDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timesPerDayMeta);
    }
    if (data.containsKey('simran_minutes')) {
      context.handle(
        _simranMinutesMeta,
        simranMinutes.isAcceptableOrUnknown(
          data['simran_minutes']!,
          _simranMinutesMeta,
        ),
      );
    }
    if (data.containsKey('duration_days')) {
      context.handle(
        _durationDaysMeta,
        durationDays.isAcceptableOrUnknown(
          data['duration_days']!,
          _durationDaysMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('removed_on')) {
      context.handle(
        _removedOnMeta,
        removedOn.isAcceptableOrUnknown(data['removed_on']!, _removedOnMeta),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      itemType: $GoalItemsTable.$converteritemType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}item_type'],
        )!,
      ),
      baniId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bani_id'],
      ),
      timesPerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_per_day'],
      )!,
      simranMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}simran_minutes'],
      ),
      durationType: $GoalItemsTable.$converterdurationType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}duration_type'],
        )!,
      ),
      durationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_days'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      removedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}removed_on'],
      ),
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GoalItemsTable createAlias(String alias) {
    return $GoalItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<ItemType, String> $converteritemType = const UpperSnake(
    ItemType.values,
  );
  static TypeConverter<DurationType, String> $converterdurationType =
      const UpperSnake(DurationType.values);
}

class GoalItem extends DataClass implements Insertable<GoalItem> {
  final String id;
  final String goalId;

  /// Equals [id] on the first row of a series; a target edit copies it (GI6).
  final String seriesId;
  final ItemType itemType;
  final String? baniId;
  final int timesPerDay;
  final int? simranMinutes;
  final DurationType durationType;
  final int? durationDays;
  final String startDate;
  final String? endDate;
  final String? removedOn;

  /// `HH:mm`, local. Null means the reminder is off (RM1).
  final String? reminderTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  const GoalItem({
    required this.id,
    required this.goalId,
    required this.seriesId,
    required this.itemType,
    this.baniId,
    required this.timesPerDay,
    this.simranMinutes,
    required this.durationType,
    this.durationDays,
    required this.startDate,
    this.endDate,
    this.removedOn,
    this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['series_id'] = Variable<String>(seriesId);
    {
      map['item_type'] = Variable<String>(
        $GoalItemsTable.$converteritemType.toSql(itemType),
      );
    }
    if (!nullToAbsent || baniId != null) {
      map['bani_id'] = Variable<String>(baniId);
    }
    map['times_per_day'] = Variable<int>(timesPerDay);
    if (!nullToAbsent || simranMinutes != null) {
      map['simran_minutes'] = Variable<int>(simranMinutes);
    }
    {
      map['duration_type'] = Variable<String>(
        $GoalItemsTable.$converterdurationType.toSql(durationType),
      );
    }
    if (!nullToAbsent || durationDays != null) {
      map['duration_days'] = Variable<int>(durationDays);
    }
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    if (!nullToAbsent || removedOn != null) {
      map['removed_on'] = Variable<String>(removedOn);
    }
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<String>(reminderTime);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalItemsCompanion toCompanion(bool nullToAbsent) {
    return GoalItemsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      seriesId: Value(seriesId),
      itemType: Value(itemType),
      baniId: baniId == null && nullToAbsent
          ? const Value.absent()
          : Value(baniId),
      timesPerDay: Value(timesPerDay),
      simranMinutes: simranMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(simranMinutes),
      durationType: Value(durationType),
      durationDays: durationDays == null && nullToAbsent
          ? const Value.absent()
          : Value(durationDays),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      removedOn: removedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(removedOn),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GoalItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalItem(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      itemType: serializer.fromJson<ItemType>(json['itemType']),
      baniId: serializer.fromJson<String?>(json['baniId']),
      timesPerDay: serializer.fromJson<int>(json['timesPerDay']),
      simranMinutes: serializer.fromJson<int?>(json['simranMinutes']),
      durationType: serializer.fromJson<DurationType>(json['durationType']),
      durationDays: serializer.fromJson<int?>(json['durationDays']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      removedOn: serializer.fromJson<String?>(json['removedOn']),
      reminderTime: serializer.fromJson<String?>(json['reminderTime']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'seriesId': serializer.toJson<String>(seriesId),
      'itemType': serializer.toJson<ItemType>(itemType),
      'baniId': serializer.toJson<String?>(baniId),
      'timesPerDay': serializer.toJson<int>(timesPerDay),
      'simranMinutes': serializer.toJson<int?>(simranMinutes),
      'durationType': serializer.toJson<DurationType>(durationType),
      'durationDays': serializer.toJson<int?>(durationDays),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'removedOn': serializer.toJson<String?>(removedOn),
      'reminderTime': serializer.toJson<String?>(reminderTime),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GoalItem copyWith({
    String? id,
    String? goalId,
    String? seriesId,
    ItemType? itemType,
    Value<String?> baniId = const Value.absent(),
    int? timesPerDay,
    Value<int?> simranMinutes = const Value.absent(),
    DurationType? durationType,
    Value<int?> durationDays = const Value.absent(),
    String? startDate,
    Value<String?> endDate = const Value.absent(),
    Value<String?> removedOn = const Value.absent(),
    Value<String?> reminderTime = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => GoalItem(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    seriesId: seriesId ?? this.seriesId,
    itemType: itemType ?? this.itemType,
    baniId: baniId.present ? baniId.value : this.baniId,
    timesPerDay: timesPerDay ?? this.timesPerDay,
    simranMinutes: simranMinutes.present
        ? simranMinutes.value
        : this.simranMinutes,
    durationType: durationType ?? this.durationType,
    durationDays: durationDays.present ? durationDays.value : this.durationDays,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    removedOn: removedOn.present ? removedOn.value : this.removedOn,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GoalItem copyWithCompanion(GoalItemsCompanion data) {
    return GoalItem(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      baniId: data.baniId.present ? data.baniId.value : this.baniId,
      timesPerDay: data.timesPerDay.present
          ? data.timesPerDay.value
          : this.timesPerDay,
      simranMinutes: data.simranMinutes.present
          ? data.simranMinutes.value
          : this.simranMinutes,
      durationType: data.durationType.present
          ? data.durationType.value
          : this.durationType,
      durationDays: data.durationDays.present
          ? data.durationDays.value
          : this.durationDays,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      removedOn: data.removedOn.present ? data.removedOn.value : this.removedOn,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalItem(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('seriesId: $seriesId, ')
          ..write('itemType: $itemType, ')
          ..write('baniId: $baniId, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('simranMinutes: $simranMinutes, ')
          ..write('durationType: $durationType, ')
          ..write('durationDays: $durationDays, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('removedOn: $removedOn, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    seriesId,
    itemType,
    baniId,
    timesPerDay,
    simranMinutes,
    durationType,
    durationDays,
    startDate,
    endDate,
    removedOn,
    reminderTime,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalItem &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.seriesId == this.seriesId &&
          other.itemType == this.itemType &&
          other.baniId == this.baniId &&
          other.timesPerDay == this.timesPerDay &&
          other.simranMinutes == this.simranMinutes &&
          other.durationType == this.durationType &&
          other.durationDays == this.durationDays &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.removedOn == this.removedOn &&
          other.reminderTime == this.reminderTime &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GoalItemsCompanion extends UpdateCompanion<GoalItem> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> seriesId;
  final Value<ItemType> itemType;
  final Value<String?> baniId;
  final Value<int> timesPerDay;
  final Value<int?> simranMinutes;
  final Value<DurationType> durationType;
  final Value<int?> durationDays;
  final Value<String> startDate;
  final Value<String?> endDate;
  final Value<String?> removedOn;
  final Value<String?> reminderTime;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GoalItemsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.baniId = const Value.absent(),
    this.timesPerDay = const Value.absent(),
    this.simranMinutes = const Value.absent(),
    this.durationType = const Value.absent(),
    this.durationDays = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.removedOn = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalItemsCompanion.insert({
    required String id,
    required String goalId,
    required String seriesId,
    required ItemType itemType,
    this.baniId = const Value.absent(),
    required int timesPerDay,
    this.simranMinutes = const Value.absent(),
    required DurationType durationType,
    this.durationDays = const Value.absent(),
    required String startDate,
    this.endDate = const Value.absent(),
    this.removedOn = const Value.absent(),
    this.reminderTime = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       seriesId = Value(seriesId),
       itemType = Value(itemType),
       timesPerDay = Value(timesPerDay),
       durationType = Value(durationType),
       startDate = Value(startDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GoalItem> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? seriesId,
    Expression<String>? itemType,
    Expression<String>? baniId,
    Expression<int>? timesPerDay,
    Expression<int>? simranMinutes,
    Expression<String>? durationType,
    Expression<int>? durationDays,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? removedOn,
    Expression<String>? reminderTime,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (seriesId != null) 'series_id': seriesId,
      if (itemType != null) 'item_type': itemType,
      if (baniId != null) 'bani_id': baniId,
      if (timesPerDay != null) 'times_per_day': timesPerDay,
      if (simranMinutes != null) 'simran_minutes': simranMinutes,
      if (durationType != null) 'duration_type': durationType,
      if (durationDays != null) 'duration_days': durationDays,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (removedOn != null) 'removed_on': removedOn,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? seriesId,
    Value<ItemType>? itemType,
    Value<String?>? baniId,
    Value<int>? timesPerDay,
    Value<int?>? simranMinutes,
    Value<DurationType>? durationType,
    Value<int?>? durationDays,
    Value<String>? startDate,
    Value<String?>? endDate,
    Value<String?>? removedOn,
    Value<String?>? reminderTime,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return GoalItemsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      seriesId: seriesId ?? this.seriesId,
      itemType: itemType ?? this.itemType,
      baniId: baniId ?? this.baniId,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      simranMinutes: simranMinutes ?? this.simranMinutes,
      durationType: durationType ?? this.durationType,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      removedOn: removedOn ?? this.removedOn,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(
        $GoalItemsTable.$converteritemType.toSql(itemType.value),
      );
    }
    if (baniId.present) {
      map['bani_id'] = Variable<String>(baniId.value);
    }
    if (timesPerDay.present) {
      map['times_per_day'] = Variable<int>(timesPerDay.value);
    }
    if (simranMinutes.present) {
      map['simran_minutes'] = Variable<int>(simranMinutes.value);
    }
    if (durationType.present) {
      map['duration_type'] = Variable<String>(
        $GoalItemsTable.$converterdurationType.toSql(durationType.value),
      );
    }
    if (durationDays.present) {
      map['duration_days'] = Variable<int>(durationDays.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (removedOn.present) {
      map['removed_on'] = Variable<String>(removedOn.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalItemsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('seriesId: $seriesId, ')
          ..write('itemType: $itemType, ')
          ..write('baniId: $baniId, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('simranMinutes: $simranMinutes, ')
          ..write('durationType: $durationType, ')
          ..write('durationDays: $durationDays, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('removedOn: $removedOn, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SangatOutboxTable extends SangatOutbox
    with TableInfo<$SangatOutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SangatOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baniIdMeta = const VerificationMeta('baniId');
  @override
  late final GeneratedColumn<String> baniId = GeneratedColumn<String>(
    'bani_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSMeta = const VerificationMeta(
    'durationS',
  );
  @override
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
    'duration_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retractedMeta = const VerificationMeta(
    'retracted',
  );
  @override
  late final GeneratedColumn<bool> retracted = GeneratedColumn<bool>(
    'retracted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retracted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    baniId,
    durationS,
    source,
    at,
    retracted,
    attempts,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sangat_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('bani_id')) {
      context.handle(
        _baniIdMeta,
        baniId.isAcceptableOrUnknown(data['bani_id']!, _baniIdMeta),
      );
    }
    if (data.containsKey('duration_s')) {
      context.handle(
        _durationSMeta,
        durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('retracted')) {
      context.handle(
        _retractedMeta,
        retracted.isAcceptableOrUnknown(data['retracted']!, _retractedMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, retracted};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      baniId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bani_id'],
      ),
      durationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_s'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      retracted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retracted'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SangatOutboxTable createAlias(String alias) {
    return $SangatOutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  /// The completion's or sitting's id.
  final String id;

  /// `BANI` or `SIMRAN`.
  final String kind;
  final String? baniId;
  final int? durationS;

  /// `READER`, `AUDIO`, `DIARY`, `TIMER`, …
  final String source;
  final DateTime at;

  /// True when this row takes back an earlier one (Diary −, CT5).
  final bool retracted;
  final int attempts;
  final DateTime createdAt;
  const OutboxRow({
    required this.id,
    required this.kind,
    this.baniId,
    this.durationS,
    required this.source,
    required this.at,
    required this.retracted,
    required this.attempts,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || baniId != null) {
      map['bani_id'] = Variable<String>(baniId);
    }
    if (!nullToAbsent || durationS != null) {
      map['duration_s'] = Variable<int>(durationS);
    }
    map['source'] = Variable<String>(source);
    map['at'] = Variable<DateTime>(at);
    map['retracted'] = Variable<bool>(retracted);
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SangatOutboxCompanion toCompanion(bool nullToAbsent) {
    return SangatOutboxCompanion(
      id: Value(id),
      kind: Value(kind),
      baniId: baniId == null && nullToAbsent
          ? const Value.absent()
          : Value(baniId),
      durationS: durationS == null && nullToAbsent
          ? const Value.absent()
          : Value(durationS),
      source: Value(source),
      at: Value(at),
      retracted: Value(retracted),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      baniId: serializer.fromJson<String?>(json['baniId']),
      durationS: serializer.fromJson<int?>(json['durationS']),
      source: serializer.fromJson<String>(json['source']),
      at: serializer.fromJson<DateTime>(json['at']),
      retracted: serializer.fromJson<bool>(json['retracted']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'baniId': serializer.toJson<String?>(baniId),
      'durationS': serializer.toJson<int?>(durationS),
      'source': serializer.toJson<String>(source),
      'at': serializer.toJson<DateTime>(at),
      'retracted': serializer.toJson<bool>(retracted),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxRow copyWith({
    String? id,
    String? kind,
    Value<String?> baniId = const Value.absent(),
    Value<int?> durationS = const Value.absent(),
    String? source,
    DateTime? at,
    bool? retracted,
    int? attempts,
    DateTime? createdAt,
  }) => OutboxRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    baniId: baniId.present ? baniId.value : this.baniId,
    durationS: durationS.present ? durationS.value : this.durationS,
    source: source ?? this.source,
    at: at ?? this.at,
    retracted: retracted ?? this.retracted,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxRow copyWithCompanion(SangatOutboxCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      baniId: data.baniId.present ? data.baniId.value : this.baniId,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      source: data.source.present ? data.source.value : this.source,
      at: data.at.present ? data.at.value : this.at,
      retracted: data.retracted.present ? data.retracted.value : this.retracted,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('baniId: $baniId, ')
          ..write('durationS: $durationS, ')
          ..write('source: $source, ')
          ..write('at: $at, ')
          ..write('retracted: $retracted, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    baniId,
    durationS,
    source,
    at,
    retracted,
    attempts,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.baniId == this.baniId &&
          other.durationS == this.durationS &&
          other.source == this.source &&
          other.at == this.at &&
          other.retracted == this.retracted &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt);
}

class SangatOutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String?> baniId;
  final Value<int?> durationS;
  final Value<String> source;
  final Value<DateTime> at;
  final Value<bool> retracted;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SangatOutboxCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.baniId = const Value.absent(),
    this.durationS = const Value.absent(),
    this.source = const Value.absent(),
    this.at = const Value.absent(),
    this.retracted = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SangatOutboxCompanion.insert({
    required String id,
    required String kind,
    this.baniId = const Value.absent(),
    this.durationS = const Value.absent(),
    required String source,
    required DateTime at,
    this.retracted = const Value.absent(),
    this.attempts = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       source = Value(source),
       at = Value(at),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? baniId,
    Expression<int>? durationS,
    Expression<String>? source,
    Expression<DateTime>? at,
    Expression<bool>? retracted,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (baniId != null) 'bani_id': baniId,
      if (durationS != null) 'duration_s': durationS,
      if (source != null) 'source': source,
      if (at != null) 'at': at,
      if (retracted != null) 'retracted': retracted,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SangatOutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String?>? baniId,
    Value<int?>? durationS,
    Value<String>? source,
    Value<DateTime>? at,
    Value<bool>? retracted,
    Value<int>? attempts,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SangatOutboxCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      baniId: baniId ?? this.baniId,
      durationS: durationS ?? this.durationS,
      source: source ?? this.source,
      at: at ?? this.at,
      retracted: retracted ?? this.retracted,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (baniId.present) {
      map['bani_id'] = Variable<String>(baniId.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (retracted.present) {
      map['retracted'] = Variable<bool>(retracted.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SangatOutboxCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('baniId: $baniId, ')
          ..write('durationS: $durationS, ')
          ..write('source: $source, ')
          ..write('at: $at, ')
          ..write('retracted: $retracted, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GraceDaysTable extends GraceDays
    with TableInfo<$GraceDaysTable, GraceDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GraceDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
    'month_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [localDate, monthKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grace_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<GraceDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localDate};
  @override
  GraceDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GraceDay(
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_key'],
      )!,
    );
  }

  @override
  $GraceDaysTable createAlias(String alias) {
    return $GraceDaysTable(attachedDatabase, alias);
  }
}

class GraceDay extends DataClass implements Insertable<GraceDay> {
  final String localDate;
  final String monthKey;
  const GraceDay({required this.localDate, required this.monthKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_date'] = Variable<String>(localDate);
    map['month_key'] = Variable<String>(monthKey);
    return map;
  }

  GraceDaysCompanion toCompanion(bool nullToAbsent) {
    return GraceDaysCompanion(
      localDate: Value(localDate),
      monthKey: Value(monthKey),
    );
  }

  factory GraceDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GraceDay(
      localDate: serializer.fromJson<String>(json['localDate']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localDate': serializer.toJson<String>(localDate),
      'monthKey': serializer.toJson<String>(monthKey),
    };
  }

  GraceDay copyWith({String? localDate, String? monthKey}) => GraceDay(
    localDate: localDate ?? this.localDate,
    monthKey: monthKey ?? this.monthKey,
  );
  GraceDay copyWithCompanion(GraceDaysCompanion data) {
    return GraceDay(
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GraceDay(')
          ..write('localDate: $localDate, ')
          ..write('monthKey: $monthKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localDate, monthKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraceDay &&
          other.localDate == this.localDate &&
          other.monthKey == this.monthKey);
}

class GraceDaysCompanion extends UpdateCompanion<GraceDay> {
  final Value<String> localDate;
  final Value<String> monthKey;
  final Value<int> rowid;
  const GraceDaysCompanion({
    this.localDate = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GraceDaysCompanion.insert({
    required String localDate,
    required String monthKey,
    this.rowid = const Value.absent(),
  }) : localDate = Value(localDate),
       monthKey = Value(monthKey);
  static Insertable<GraceDay> custom({
    Expression<String>? localDate,
    Expression<String>? monthKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localDate != null) 'local_date': localDate,
      if (monthKey != null) 'month_key': monthKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GraceDaysCompanion copyWith({
    Value<String>? localDate,
    Value<String>? monthKey,
    Value<int>? rowid,
  }) {
    return GraceDaysCompanion(
      localDate: localDate ?? this.localDate,
      monthKey: monthKey ?? this.monthKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GraceDaysCompanion(')
          ..write('localDate: $localDate, ')
          ..write('monthKey: $monthKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventReminderOverridesTable extends EventReminderOverrides
    with TableInfo<$EventReminderOverridesTable, EventReminderOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventReminderOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [eventId, enabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_reminder_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventReminderOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  EventReminderOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventReminderOverride(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $EventReminderOverridesTable createAlias(String alias) {
    return $EventReminderOverridesTable(attachedDatabase, alias);
  }
}

class EventReminderOverride extends DataClass
    implements Insertable<EventReminderOverride> {
  final String eventId;
  final bool enabled;
  const EventReminderOverride({required this.eventId, required this.enabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  EventReminderOverridesCompanion toCompanion(bool nullToAbsent) {
    return EventReminderOverridesCompanion(
      eventId: Value(eventId),
      enabled: Value(enabled),
    );
  }

  factory EventReminderOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventReminderOverride(
      eventId: serializer.fromJson<String>(json['eventId']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  EventReminderOverride copyWith({String? eventId, bool? enabled}) =>
      EventReminderOverride(
        eventId: eventId ?? this.eventId,
        enabled: enabled ?? this.enabled,
      );
  EventReminderOverride copyWithCompanion(
    EventReminderOverridesCompanion data,
  ) {
    return EventReminderOverride(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventReminderOverride(')
          ..write('eventId: $eventId, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventReminderOverride &&
          other.eventId == this.eventId &&
          other.enabled == this.enabled);
}

class EventReminderOverridesCompanion
    extends UpdateCompanion<EventReminderOverride> {
  final Value<String> eventId;
  final Value<bool> enabled;
  final Value<int> rowid;
  const EventReminderOverridesCompanion({
    this.eventId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventReminderOverridesCompanion.insert({
    required String eventId,
    required bool enabled,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       enabled = Value(enabled);
  static Insertable<EventReminderOverride> custom({
    Expression<String>? eventId,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventReminderOverridesCompanion copyWith({
    Value<String>? eventId,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return EventReminderOverridesCompanion(
      eventId: eventId ?? this.eventId,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventReminderOverridesCompanion(')
          ..write('eventId: $eventId, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BadgesTable extends Badges with TableInfo<$BadgesTable, BadgeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BadgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _badgeIdMeta = const VerificationMeta(
    'badgeId',
  );
  @override
  late final GeneratedColumn<String> badgeId = GeneratedColumn<String>(
    'badge_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _earnedOnMeta = const VerificationMeta(
    'earnedOn',
  );
  @override
  late final GeneratedColumn<String> earnedOn = GeneratedColumn<String>(
    'earned_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _announcedAtMeta = const VerificationMeta(
    'announcedAt',
  );
  @override
  late final GeneratedColumn<DateTime> announcedAt = GeneratedColumn<DateTime>(
    'announced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    badgeId,
    earnedOn,
    announcedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'badges';
  @override
  VerificationContext validateIntegrity(
    Insertable<BadgeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('badge_id')) {
      context.handle(
        _badgeIdMeta,
        badgeId.isAcceptableOrUnknown(data['badge_id']!, _badgeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_badgeIdMeta);
    }
    if (data.containsKey('earned_on')) {
      context.handle(
        _earnedOnMeta,
        earnedOn.isAcceptableOrUnknown(data['earned_on']!, _earnedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_earnedOnMeta);
    }
    if (data.containsKey('announced_at')) {
      context.handle(
        _announcedAtMeta,
        announcedAt.isAcceptableOrUnknown(
          data['announced_at']!,
          _announcedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {badgeId};
  @override
  BadgeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BadgeRow(
      badgeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}badge_id'],
      )!,
      earnedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}earned_on'],
      )!,
      announcedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}announced_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BadgesTable createAlias(String alias) {
    return $BadgesTable(attachedDatabase, alias);
  }
}

class BadgeRow extends DataClass implements Insertable<BadgeRow> {
  /// One of 12-badges §2, e.g. `JIGYASU`.
  final String badgeId;

  /// The local date the rule was first found met.
  final String earnedOn;

  /// When its sheet was shown, or when it was marked never to be shown.
  final DateTime? announcedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BadgeRow({
    required this.badgeId,
    required this.earnedOn,
    this.announcedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['badge_id'] = Variable<String>(badgeId);
    map['earned_on'] = Variable<String>(earnedOn);
    if (!nullToAbsent || announcedAt != null) {
      map['announced_at'] = Variable<DateTime>(announcedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BadgesCompanion toCompanion(bool nullToAbsent) {
    return BadgesCompanion(
      badgeId: Value(badgeId),
      earnedOn: Value(earnedOn),
      announcedAt: announcedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(announcedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BadgeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BadgeRow(
      badgeId: serializer.fromJson<String>(json['badgeId']),
      earnedOn: serializer.fromJson<String>(json['earnedOn']),
      announcedAt: serializer.fromJson<DateTime?>(json['announcedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'badgeId': serializer.toJson<String>(badgeId),
      'earnedOn': serializer.toJson<String>(earnedOn),
      'announcedAt': serializer.toJson<DateTime?>(announcedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BadgeRow copyWith({
    String? badgeId,
    String? earnedOn,
    Value<DateTime?> announcedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BadgeRow(
    badgeId: badgeId ?? this.badgeId,
    earnedOn: earnedOn ?? this.earnedOn,
    announcedAt: announcedAt.present ? announcedAt.value : this.announcedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BadgeRow copyWithCompanion(BadgesCompanion data) {
    return BadgeRow(
      badgeId: data.badgeId.present ? data.badgeId.value : this.badgeId,
      earnedOn: data.earnedOn.present ? data.earnedOn.value : this.earnedOn,
      announcedAt: data.announcedAt.present
          ? data.announcedAt.value
          : this.announcedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BadgeRow(')
          ..write('badgeId: $badgeId, ')
          ..write('earnedOn: $earnedOn, ')
          ..write('announcedAt: $announcedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(badgeId, earnedOn, announcedAt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BadgeRow &&
          other.badgeId == this.badgeId &&
          other.earnedOn == this.earnedOn &&
          other.announcedAt == this.announcedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BadgesCompanion extends UpdateCompanion<BadgeRow> {
  final Value<String> badgeId;
  final Value<String> earnedOn;
  final Value<DateTime?> announcedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BadgesCompanion({
    this.badgeId = const Value.absent(),
    this.earnedOn = const Value.absent(),
    this.announcedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BadgesCompanion.insert({
    required String badgeId,
    required String earnedOn,
    this.announcedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : badgeId = Value(badgeId),
       earnedOn = Value(earnedOn),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BadgeRow> custom({
    Expression<String>? badgeId,
    Expression<String>? earnedOn,
    Expression<DateTime>? announcedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (badgeId != null) 'badge_id': badgeId,
      if (earnedOn != null) 'earned_on': earnedOn,
      if (announcedAt != null) 'announced_at': announcedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BadgesCompanion copyWith({
    Value<String>? badgeId,
    Value<String>? earnedOn,
    Value<DateTime?>? announcedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BadgesCompanion(
      badgeId: badgeId ?? this.badgeId,
      earnedOn: earnedOn ?? this.earnedOn,
      announcedAt: announcedAt ?? this.announcedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (badgeId.present) {
      map['badge_id'] = Variable<String>(badgeId.value);
    }
    if (earnedOn.present) {
      map['earned_on'] = Variable<String>(earnedOn.value);
    }
    if (announcedAt.present) {
      map['announced_at'] = Variable<DateTime>(announcedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BadgesCompanion(')
          ..write('badgeId: $badgeId, ')
          ..write('earnedOn: $earnedOn, ')
          ..write('announcedAt: $announcedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDb extends GeneratedDatabase {
  _$UserDb(QueryExecutor e) : super(e);
  $UserDbManager get managers => $UserDbManager(this);
  late final $ReadingProgressTable readingProgress = $ReadingProgressTable(
    this,
  );
  late final $CompletionsTable completions = $CompletionsTable(this);
  late final $SimranSessionsTable simranSessions = $SimranSessionsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $GoalItemsTable goalItems = $GoalItemsTable(this);
  late final $SangatOutboxTable sangatOutbox = $SangatOutboxTable(this);
  late final $GraceDaysTable graceDays = $GraceDaysTable(this);
  late final $EventReminderOverridesTable eventReminderOverrides =
      $EventReminderOverridesTable(this);
  late final $BadgesTable badges = $BadgesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    readingProgress,
    completions,
    simranSessions,
    goals,
    goalItems,
    sangatOutbox,
    graceDays,
    eventReminderOverrides,
    badges,
  ];
}

typedef $$ReadingProgressTableCreateCompanionBuilder =
    ReadingProgressCompanion Function({
      required String baniVersionId,
      Value<int> lineIdx,
      Value<int> audioPosMs,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReadingProgressTableUpdateCompanionBuilder =
    ReadingProgressCompanion Function({
      Value<String> baniVersionId,
      Value<int> lineIdx,
      Value<int> audioPosMs,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ReadingProgressTableFilterComposer
    extends Composer<_$UserDb, $ReadingProgressTable> {
  $$ReadingProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get baniVersionId => $composableBuilder(
    column: $table.baniVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineIdx => $composableBuilder(
    column: $table.lineIdx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get audioPosMs => $composableBuilder(
    column: $table.audioPosMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingProgressTableOrderingComposer
    extends Composer<_$UserDb, $ReadingProgressTable> {
  $$ReadingProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get baniVersionId => $composableBuilder(
    column: $table.baniVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineIdx => $composableBuilder(
    column: $table.lineIdx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get audioPosMs => $composableBuilder(
    column: $table.audioPosMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingProgressTableAnnotationComposer
    extends Composer<_$UserDb, $ReadingProgressTable> {
  $$ReadingProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get baniVersionId => $composableBuilder(
    column: $table.baniVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lineIdx =>
      $composableBuilder(column: $table.lineIdx, builder: (column) => column);

  GeneratedColumn<int> get audioPosMs => $composableBuilder(
    column: $table.audioPosMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReadingProgressTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $ReadingProgressTable,
          ReadingProgressData,
          $$ReadingProgressTableFilterComposer,
          $$ReadingProgressTableOrderingComposer,
          $$ReadingProgressTableAnnotationComposer,
          $$ReadingProgressTableCreateCompanionBuilder,
          $$ReadingProgressTableUpdateCompanionBuilder,
          (
            ReadingProgressData,
            BaseReferences<
              _$UserDb,
              $ReadingProgressTable,
              ReadingProgressData
            >,
          ),
          ReadingProgressData,
          PrefetchHooks Function()
        > {
  $$ReadingProgressTableTableManager(_$UserDb db, $ReadingProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> baniVersionId = const Value.absent(),
                Value<int> lineIdx = const Value.absent(),
                Value<int> audioPosMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion(
                baniVersionId: baniVersionId,
                lineIdx: lineIdx,
                audioPosMs: audioPosMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String baniVersionId,
                Value<int> lineIdx = const Value.absent(),
                Value<int> audioPosMs = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion.insert(
                baniVersionId: baniVersionId,
                lineIdx: lineIdx,
                audioPosMs: audioPosMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingProgressTable, ReadingProgressData>(
                    table,
                  ),
                  BaseReferences<
                    _$UserDb,
                    $ReadingProgressTable,
                    ReadingProgressData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $ReadingProgressTable,
      ReadingProgressData,
      $$ReadingProgressTableFilterComposer,
      $$ReadingProgressTableOrderingComposer,
      $$ReadingProgressTableAnnotationComposer,
      $$ReadingProgressTableCreateCompanionBuilder,
      $$ReadingProgressTableUpdateCompanionBuilder,
      (
        ReadingProgressData,
        BaseReferences<_$UserDb, $ReadingProgressTable, ReadingProgressData>,
      ),
      ReadingProgressData,
      PrefetchHooks Function()
    >;
typedef $$CompletionsTableCreateCompanionBuilder =
    CompletionsCompanion Function({
      required String id,
      required String localDate,
      required String baniId,
      required BaniSlotValue slot,
      required CompletionSource source,
      required DateTime completedAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$CompletionsTableUpdateCompanionBuilder =
    CompletionsCompanion Function({
      Value<String> id,
      Value<String> localDate,
      Value<String> baniId,
      Value<BaniSlotValue> slot,
      Value<CompletionSource> source,
      Value<DateTime> completedAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$CompletionsTableFilterComposer
    extends Composer<_$UserDb, $CompletionsTable> {
  $$CompletionsTableFilterComposer({
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

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baniId => $composableBuilder(
    column: $table.baniId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BaniSlotValue, BaniSlotValue, String>
  get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CompletionSource, CompletionSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompletionsTableOrderingComposer
    extends Composer<_$UserDb, $CompletionsTable> {
  $$CompletionsTableOrderingComposer({
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

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baniId => $composableBuilder(
    column: $table.baniId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompletionsTableAnnotationComposer
    extends Composer<_$UserDb, $CompletionsTable> {
  $$CompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get baniId =>
      $composableBuilder(column: $table.baniId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BaniSlotValue, String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CompletionSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CompletionsTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $CompletionsTable,
          Completion,
          $$CompletionsTableFilterComposer,
          $$CompletionsTableOrderingComposer,
          $$CompletionsTableAnnotationComposer,
          $$CompletionsTableCreateCompanionBuilder,
          $$CompletionsTableUpdateCompanionBuilder,
          (Completion, BaseReferences<_$UserDb, $CompletionsTable, Completion>),
          Completion,
          PrefetchHooks Function()
        > {
  $$CompletionsTableTableManager(_$UserDb db, $CompletionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String> baniId = const Value.absent(),
                Value<BaniSlotValue> slot = const Value.absent(),
                Value<CompletionSource> source = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletionsCompanion(
                id: id,
                localDate: localDate,
                baniId: baniId,
                slot: slot,
                source: source,
                completedAt: completedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String localDate,
                required String baniId,
                required BaniSlotValue slot,
                required CompletionSource source,
                required DateTime completedAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletionsCompanion.insert(
                id: id,
                localDate: localDate,
                baniId: baniId,
                slot: slot,
                source: source,
                completedAt: completedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CompletionsTable, Completion>(table),
                  BaseReferences<_$UserDb, $CompletionsTable, Completion>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $CompletionsTable,
      Completion,
      $$CompletionsTableFilterComposer,
      $$CompletionsTableOrderingComposer,
      $$CompletionsTableAnnotationComposer,
      $$CompletionsTableCreateCompanionBuilder,
      $$CompletionsTableUpdateCompanionBuilder,
      (Completion, BaseReferences<_$UserDb, $CompletionsTable, Completion>),
      Completion,
      PrefetchHooks Function()
    >;
typedef $$SimranSessionsTableCreateCompanionBuilder =
    SimranSessionsCompanion Function({
      required String id,
      required String localDate,
      required DateTime startedAt,
      required int durationS,
      Value<int> count,
      Value<bool> completed,
      required SittingSource source,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$SimranSessionsTableUpdateCompanionBuilder =
    SimranSessionsCompanion Function({
      Value<String> id,
      Value<String> localDate,
      Value<DateTime> startedAt,
      Value<int> durationS,
      Value<int> count,
      Value<bool> completed,
      Value<SittingSource> source,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$SimranSessionsTableFilterComposer
    extends Composer<_$UserDb, $SimranSessionsTable> {
  $$SimranSessionsTableFilterComposer({
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

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SittingSource, SittingSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SimranSessionsTableOrderingComposer
    extends Composer<_$UserDb, $SimranSessionsTable> {
  $$SimranSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SimranSessionsTableAnnotationComposer
    extends Composer<_$UserDb, $SimranSessionsTable> {
  $$SimranSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SittingSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SimranSessionsTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $SimranSessionsTable,
          SimranSession,
          $$SimranSessionsTableFilterComposer,
          $$SimranSessionsTableOrderingComposer,
          $$SimranSessionsTableAnnotationComposer,
          $$SimranSessionsTableCreateCompanionBuilder,
          $$SimranSessionsTableUpdateCompanionBuilder,
          (
            SimranSession,
            BaseReferences<_$UserDb, $SimranSessionsTable, SimranSession>,
          ),
          SimranSession,
          PrefetchHooks Function()
        > {
  $$SimranSessionsTableTableManager(_$UserDb db, $SimranSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SimranSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SimranSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SimranSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> durationS = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<SittingSource> source = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SimranSessionsCompanion(
                id: id,
                localDate: localDate,
                startedAt: startedAt,
                durationS: durationS,
                count: count,
                completed: completed,
                source: source,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String localDate,
                required DateTime startedAt,
                required int durationS,
                Value<int> count = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                required SittingSource source,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SimranSessionsCompanion.insert(
                id: id,
                localDate: localDate,
                startedAt: startedAt,
                durationS: durationS,
                count: count,
                completed: completed,
                source: source,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SimranSessionsTable, SimranSession>(table),
                  BaseReferences<_$UserDb, $SimranSessionsTable, SimranSession>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SimranSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $SimranSessionsTable,
      SimranSession,
      $$SimranSessionsTableFilterComposer,
      $$SimranSessionsTableOrderingComposer,
      $$SimranSessionsTableAnnotationComposer,
      $$SimranSessionsTableCreateCompanionBuilder,
      $$SimranSessionsTableUpdateCompanionBuilder,
      (
        SimranSession,
        BaseReferences<_$UserDb, $SimranSessionsTable, SimranSession>,
      ),
      SimranSession,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      required String id,
      required String startDate,
      Value<String?> completedOn,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<String> id,
      Value<String> startDate,
      Value<String?> completedOn,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$GoalsTableFilterComposer extends Composer<_$UserDb, $GoalsTable> {
  $$GoalsTableFilterComposer({
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

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedOn => $composableBuilder(
    column: $table.completedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer extends Composer<_$UserDb, $GoalsTable> {
  $$GoalsTableOrderingComposer({
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

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedOn => $composableBuilder(
    column: $table.completedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer extends Composer<_$UserDb, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get completedOn => $composableBuilder(
    column: $table.completedOn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$UserDb, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$UserDb db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> completedOn = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                startDate: startDate,
                completedOn: completedOn,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String startDate,
                Value<String?> completedOn = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                startDate: startDate,
                completedOn: completedOn,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalsTable, Goal>(table),
                  BaseReferences<_$UserDb, $GoalsTable, Goal>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$UserDb, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$GoalItemsTableCreateCompanionBuilder =
    GoalItemsCompanion Function({
      required String id,
      required String goalId,
      required String seriesId,
      required ItemType itemType,
      Value<String?> baniId,
      required int timesPerDay,
      Value<int?> simranMinutes,
      required DurationType durationType,
      Value<int?> durationDays,
      required String startDate,
      Value<String?> endDate,
      Value<String?> removedOn,
      Value<String?> reminderTime,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$GoalItemsTableUpdateCompanionBuilder =
    GoalItemsCompanion Function({
      Value<String> id,
      Value<String> goalId,
      Value<String> seriesId,
      Value<ItemType> itemType,
      Value<String?> baniId,
      Value<int> timesPerDay,
      Value<int?> simranMinutes,
      Value<DurationType> durationType,
      Value<int?> durationDays,
      Value<String> startDate,
      Value<String?> endDate,
      Value<String?> removedOn,
      Value<String?> reminderTime,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$GoalItemsTableFilterComposer
    extends Composer<_$UserDb, $GoalItemsTable> {
  $$GoalItemsTableFilterComposer({
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

  ColumnFilters<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemType, ItemType, String> get itemType =>
      $composableBuilder(
        column: $table.itemType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get baniId => $composableBuilder(
    column: $table.baniId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timesPerDay => $composableBuilder(
    column: $table.timesPerDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get simranMinutes => $composableBuilder(
    column: $table.simranMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DurationType, DurationType, String>
  get durationType => $composableBuilder(
    column: $table.durationType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get removedOn => $composableBuilder(
    column: $table.removedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalItemsTableOrderingComposer
    extends Composer<_$UserDb, $GoalItemsTable> {
  $$GoalItemsTableOrderingComposer({
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

  ColumnOrderings<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baniId => $composableBuilder(
    column: $table.baniId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timesPerDay => $composableBuilder(
    column: $table.timesPerDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get simranMinutes => $composableBuilder(
    column: $table.simranMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get durationType => $composableBuilder(
    column: $table.durationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get removedOn => $composableBuilder(
    column: $table.removedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalItemsTableAnnotationComposer
    extends Composer<_$UserDb, $GoalItemsTable> {
  $$GoalItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemType, String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get baniId =>
      $composableBuilder(column: $table.baniId, builder: (column) => column);

  GeneratedColumn<int> get timesPerDay => $composableBuilder(
    column: $table.timesPerDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get simranMinutes => $composableBuilder(
    column: $table.simranMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DurationType, String> get durationType =>
      $composableBuilder(
        column: $table.durationType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get removedOn =>
      $composableBuilder(column: $table.removedOn, builder: (column) => column);

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GoalItemsTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $GoalItemsTable,
          GoalItem,
          $$GoalItemsTableFilterComposer,
          $$GoalItemsTableOrderingComposer,
          $$GoalItemsTableAnnotationComposer,
          $$GoalItemsTableCreateCompanionBuilder,
          $$GoalItemsTableUpdateCompanionBuilder,
          (GoalItem, BaseReferences<_$UserDb, $GoalItemsTable, GoalItem>),
          GoalItem,
          PrefetchHooks Function()
        > {
  $$GoalItemsTableTableManager(_$UserDb db, $GoalItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<ItemType> itemType = const Value.absent(),
                Value<String?> baniId = const Value.absent(),
                Value<int> timesPerDay = const Value.absent(),
                Value<int?> simranMinutes = const Value.absent(),
                Value<DurationType> durationType = const Value.absent(),
                Value<int?> durationDays = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> removedOn = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalItemsCompanion(
                id: id,
                goalId: goalId,
                seriesId: seriesId,
                itemType: itemType,
                baniId: baniId,
                timesPerDay: timesPerDay,
                simranMinutes: simranMinutes,
                durationType: durationType,
                durationDays: durationDays,
                startDate: startDate,
                endDate: endDate,
                removedOn: removedOn,
                reminderTime: reminderTime,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String seriesId,
                required ItemType itemType,
                Value<String?> baniId = const Value.absent(),
                required int timesPerDay,
                Value<int?> simranMinutes = const Value.absent(),
                required DurationType durationType,
                Value<int?> durationDays = const Value.absent(),
                required String startDate,
                Value<String?> endDate = const Value.absent(),
                Value<String?> removedOn = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => GoalItemsCompanion.insert(
                id: id,
                goalId: goalId,
                seriesId: seriesId,
                itemType: itemType,
                baniId: baniId,
                timesPerDay: timesPerDay,
                simranMinutes: simranMinutes,
                durationType: durationType,
                durationDays: durationDays,
                startDate: startDate,
                endDate: endDate,
                removedOn: removedOn,
                reminderTime: reminderTime,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalItemsTable, GoalItem>(table),
                  BaseReferences<_$UserDb, $GoalItemsTable, GoalItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $GoalItemsTable,
      GoalItem,
      $$GoalItemsTableFilterComposer,
      $$GoalItemsTableOrderingComposer,
      $$GoalItemsTableAnnotationComposer,
      $$GoalItemsTableCreateCompanionBuilder,
      $$GoalItemsTableUpdateCompanionBuilder,
      (GoalItem, BaseReferences<_$UserDb, $GoalItemsTable, GoalItem>),
      GoalItem,
      PrefetchHooks Function()
    >;
typedef $$SangatOutboxTableCreateCompanionBuilder =
    SangatOutboxCompanion Function({
      required String id,
      required String kind,
      Value<String?> baniId,
      Value<int?> durationS,
      required String source,
      required DateTime at,
      Value<bool> retracted,
      Value<int> attempts,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SangatOutboxTableUpdateCompanionBuilder =
    SangatOutboxCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String?> baniId,
      Value<int?> durationS,
      Value<String> source,
      Value<DateTime> at,
      Value<bool> retracted,
      Value<int> attempts,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SangatOutboxTableFilterComposer
    extends Composer<_$UserDb, $SangatOutboxTable> {
  $$SangatOutboxTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baniId => $composableBuilder(
    column: $table.baniId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retracted => $composableBuilder(
    column: $table.retracted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SangatOutboxTableOrderingComposer
    extends Composer<_$UserDb, $SangatOutboxTable> {
  $$SangatOutboxTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baniId => $composableBuilder(
    column: $table.baniId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retracted => $composableBuilder(
    column: $table.retracted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SangatOutboxTableAnnotationComposer
    extends Composer<_$UserDb, $SangatOutboxTable> {
  $$SangatOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get baniId =>
      $composableBuilder(column: $table.baniId, builder: (column) => column);

  GeneratedColumn<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<bool> get retracted =>
      $composableBuilder(column: $table.retracted, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SangatOutboxTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $SangatOutboxTable,
          OutboxRow,
          $$SangatOutboxTableFilterComposer,
          $$SangatOutboxTableOrderingComposer,
          $$SangatOutboxTableAnnotationComposer,
          $$SangatOutboxTableCreateCompanionBuilder,
          $$SangatOutboxTableUpdateCompanionBuilder,
          (OutboxRow, BaseReferences<_$UserDb, $SangatOutboxTable, OutboxRow>),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$SangatOutboxTableTableManager(_$UserDb db, $SangatOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SangatOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SangatOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SangatOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> baniId = const Value.absent(),
                Value<int?> durationS = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<bool> retracted = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SangatOutboxCompanion(
                id: id,
                kind: kind,
                baniId: baniId,
                durationS: durationS,
                source: source,
                at: at,
                retracted: retracted,
                attempts: attempts,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                Value<String?> baniId = const Value.absent(),
                Value<int?> durationS = const Value.absent(),
                required String source,
                required DateTime at,
                Value<bool> retracted = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SangatOutboxCompanion.insert(
                id: id,
                kind: kind,
                baniId: baniId,
                durationS: durationS,
                source: source,
                at: at,
                retracted: retracted,
                attempts: attempts,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SangatOutboxTable, OutboxRow>(table),
                  BaseReferences<_$UserDb, $SangatOutboxTable, OutboxRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SangatOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $SangatOutboxTable,
      OutboxRow,
      $$SangatOutboxTableFilterComposer,
      $$SangatOutboxTableOrderingComposer,
      $$SangatOutboxTableAnnotationComposer,
      $$SangatOutboxTableCreateCompanionBuilder,
      $$SangatOutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$UserDb, $SangatOutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$GraceDaysTableCreateCompanionBuilder =
    GraceDaysCompanion Function({
      required String localDate,
      required String monthKey,
      Value<int> rowid,
    });
typedef $$GraceDaysTableUpdateCompanionBuilder =
    GraceDaysCompanion Function({
      Value<String> localDate,
      Value<String> monthKey,
      Value<int> rowid,
    });

class $$GraceDaysTableFilterComposer
    extends Composer<_$UserDb, $GraceDaysTable> {
  $$GraceDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GraceDaysTableOrderingComposer
    extends Composer<_$UserDb, $GraceDaysTable> {
  $$GraceDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GraceDaysTableAnnotationComposer
    extends Composer<_$UserDb, $GraceDaysTable> {
  $$GraceDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);
}

class $$GraceDaysTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $GraceDaysTable,
          GraceDay,
          $$GraceDaysTableFilterComposer,
          $$GraceDaysTableOrderingComposer,
          $$GraceDaysTableAnnotationComposer,
          $$GraceDaysTableCreateCompanionBuilder,
          $$GraceDaysTableUpdateCompanionBuilder,
          (GraceDay, BaseReferences<_$UserDb, $GraceDaysTable, GraceDay>),
          GraceDay,
          PrefetchHooks Function()
        > {
  $$GraceDaysTableTableManager(_$UserDb db, $GraceDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GraceDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GraceDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GraceDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localDate = const Value.absent(),
                Value<String> monthKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GraceDaysCompanion(
                localDate: localDate,
                monthKey: monthKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localDate,
                required String monthKey,
                Value<int> rowid = const Value.absent(),
              }) => GraceDaysCompanion.insert(
                localDate: localDate,
                monthKey: monthKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GraceDaysTable, GraceDay>(table),
                  BaseReferences<_$UserDb, $GraceDaysTable, GraceDay>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GraceDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $GraceDaysTable,
      GraceDay,
      $$GraceDaysTableFilterComposer,
      $$GraceDaysTableOrderingComposer,
      $$GraceDaysTableAnnotationComposer,
      $$GraceDaysTableCreateCompanionBuilder,
      $$GraceDaysTableUpdateCompanionBuilder,
      (GraceDay, BaseReferences<_$UserDb, $GraceDaysTable, GraceDay>),
      GraceDay,
      PrefetchHooks Function()
    >;
typedef $$EventReminderOverridesTableCreateCompanionBuilder =
    EventReminderOverridesCompanion Function({
      required String eventId,
      required bool enabled,
      Value<int> rowid,
    });
typedef $$EventReminderOverridesTableUpdateCompanionBuilder =
    EventReminderOverridesCompanion Function({
      Value<String> eventId,
      Value<bool> enabled,
      Value<int> rowid,
    });

class $$EventReminderOverridesTableFilterComposer
    extends Composer<_$UserDb, $EventReminderOverridesTable> {
  $$EventReminderOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventReminderOverridesTableOrderingComposer
    extends Composer<_$UserDb, $EventReminderOverridesTable> {
  $$EventReminderOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventReminderOverridesTableAnnotationComposer
    extends Composer<_$UserDb, $EventReminderOverridesTable> {
  $$EventReminderOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$EventReminderOverridesTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $EventReminderOverridesTable,
          EventReminderOverride,
          $$EventReminderOverridesTableFilterComposer,
          $$EventReminderOverridesTableOrderingComposer,
          $$EventReminderOverridesTableAnnotationComposer,
          $$EventReminderOverridesTableCreateCompanionBuilder,
          $$EventReminderOverridesTableUpdateCompanionBuilder,
          (
            EventReminderOverride,
            BaseReferences<
              _$UserDb,
              $EventReminderOverridesTable,
              EventReminderOverride
            >,
          ),
          EventReminderOverride,
          PrefetchHooks Function()
        > {
  $$EventReminderOverridesTableTableManager(
    _$UserDb db,
    $EventReminderOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventReminderOverridesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EventReminderOverridesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EventReminderOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventReminderOverridesCompanion(
                eventId: eventId,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required bool enabled,
                Value<int> rowid = const Value.absent(),
              }) => EventReminderOverridesCompanion.insert(
                eventId: eventId,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $EventReminderOverridesTable,
                    EventReminderOverride
                  >(table),
                  BaseReferences<
                    _$UserDb,
                    $EventReminderOverridesTable,
                    EventReminderOverride
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventReminderOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $EventReminderOverridesTable,
      EventReminderOverride,
      $$EventReminderOverridesTableFilterComposer,
      $$EventReminderOverridesTableOrderingComposer,
      $$EventReminderOverridesTableAnnotationComposer,
      $$EventReminderOverridesTableCreateCompanionBuilder,
      $$EventReminderOverridesTableUpdateCompanionBuilder,
      (
        EventReminderOverride,
        BaseReferences<
          _$UserDb,
          $EventReminderOverridesTable,
          EventReminderOverride
        >,
      ),
      EventReminderOverride,
      PrefetchHooks Function()
    >;
typedef $$BadgesTableCreateCompanionBuilder =
    BadgesCompanion Function({
      required String badgeId,
      required String earnedOn,
      Value<DateTime?> announcedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BadgesTableUpdateCompanionBuilder =
    BadgesCompanion Function({
      Value<String> badgeId,
      Value<String> earnedOn,
      Value<DateTime?> announcedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BadgesTableFilterComposer extends Composer<_$UserDb, $BadgesTable> {
  $$BadgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get badgeId => $composableBuilder(
    column: $table.badgeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get earnedOn => $composableBuilder(
    column: $table.earnedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get announcedAt => $composableBuilder(
    column: $table.announcedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BadgesTableOrderingComposer extends Composer<_$UserDb, $BadgesTable> {
  $$BadgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get badgeId => $composableBuilder(
    column: $table.badgeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get earnedOn => $composableBuilder(
    column: $table.earnedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get announcedAt => $composableBuilder(
    column: $table.announcedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BadgesTableAnnotationComposer extends Composer<_$UserDb, $BadgesTable> {
  $$BadgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get badgeId =>
      $composableBuilder(column: $table.badgeId, builder: (column) => column);

  GeneratedColumn<String> get earnedOn =>
      $composableBuilder(column: $table.earnedOn, builder: (column) => column);

  GeneratedColumn<DateTime> get announcedAt => $composableBuilder(
    column: $table.announcedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BadgesTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $BadgesTable,
          BadgeRow,
          $$BadgesTableFilterComposer,
          $$BadgesTableOrderingComposer,
          $$BadgesTableAnnotationComposer,
          $$BadgesTableCreateCompanionBuilder,
          $$BadgesTableUpdateCompanionBuilder,
          (BadgeRow, BaseReferences<_$UserDb, $BadgesTable, BadgeRow>),
          BadgeRow,
          PrefetchHooks Function()
        > {
  $$BadgesTableTableManager(_$UserDb db, $BadgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BadgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BadgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BadgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> badgeId = const Value.absent(),
                Value<String> earnedOn = const Value.absent(),
                Value<DateTime?> announcedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BadgesCompanion(
                badgeId: badgeId,
                earnedOn: earnedOn,
                announcedAt: announcedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String badgeId,
                required String earnedOn,
                Value<DateTime?> announcedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BadgesCompanion.insert(
                badgeId: badgeId,
                earnedOn: earnedOn,
                announcedAt: announcedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BadgesTable, BadgeRow>(table),
                  BaseReferences<_$UserDb, $BadgesTable, BadgeRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BadgesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $BadgesTable,
      BadgeRow,
      $$BadgesTableFilterComposer,
      $$BadgesTableOrderingComposer,
      $$BadgesTableAnnotationComposer,
      $$BadgesTableCreateCompanionBuilder,
      $$BadgesTableUpdateCompanionBuilder,
      (BadgeRow, BaseReferences<_$UserDb, $BadgesTable, BadgeRow>),
      BadgeRow,
      PrefetchHooks Function()
    >;

class $UserDbManager {
  final _$UserDb _db;
  $UserDbManager(this._db);
  $$ReadingProgressTableTableManager get readingProgress =>
      $$ReadingProgressTableTableManager(_db, _db.readingProgress);
  $$CompletionsTableTableManager get completions =>
      $$CompletionsTableTableManager(_db, _db.completions);
  $$SimranSessionsTableTableManager get simranSessions =>
      $$SimranSessionsTableTableManager(_db, _db.simranSessions);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$GoalItemsTableTableManager get goalItems =>
      $$GoalItemsTableTableManager(_db, _db.goalItems);
  $$SangatOutboxTableTableManager get sangatOutbox =>
      $$SangatOutboxTableTableManager(_db, _db.sangatOutbox);
  $$GraceDaysTableTableManager get graceDays =>
      $$GraceDaysTableTableManager(_db, _db.graceDays);
  $$EventReminderOverridesTableTableManager get eventReminderOverrides =>
      $$EventReminderOverridesTableTableManager(
        _db,
        _db.eventReminderOverrides,
      );
  $$BadgesTableTableManager get badges =>
      $$BadgesTableTableManager(_db, _db.badges);
}
