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
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localDate,
    baniId,
    slot,
    source,
    goalId,
    completedAt,
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
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
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
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $CompletionsTable createAlias(String alias) {
    return $CompletionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BaniSlotValue, String, String> $converterslot =
      const EnumNameConverter<BaniSlotValue>(BaniSlotValue.values);
  static JsonTypeConverter2<CompletionSource, String, String> $convertersource =
      const EnumNameConverter<CompletionSource>(CompletionSource.values);
}

class Completion extends DataClass implements Insertable<Completion> {
  final String id;
  final String localDate;
  final String baniId;
  final BaniSlotValue slot;
  final CompletionSource source;
  final String? goalId;
  final DateTime completedAt;
  const Completion({
    required this.id,
    required this.localDate,
    required this.baniId,
    required this.slot,
    required this.source,
    this.goalId,
    required this.completedAt,
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
    if (!nullToAbsent || goalId != null) {
      map['goal_id'] = Variable<String>(goalId);
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  CompletionsCompanion toCompanion(bool nullToAbsent) {
    return CompletionsCompanion(
      id: Value(id),
      localDate: Value(localDate),
      baniId: Value(baniId),
      slot: Value(slot),
      source: Value(source),
      goalId: goalId == null && nullToAbsent
          ? const Value.absent()
          : Value(goalId),
      completedAt: Value(completedAt),
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
      slot: $CompletionsTable.$converterslot.fromJson(
        serializer.fromJson<String>(json['slot']),
      ),
      source: $CompletionsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      goalId: serializer.fromJson<String?>(json['goalId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localDate': serializer.toJson<String>(localDate),
      'baniId': serializer.toJson<String>(baniId),
      'slot': serializer.toJson<String>(
        $CompletionsTable.$converterslot.toJson(slot),
      ),
      'source': serializer.toJson<String>(
        $CompletionsTable.$convertersource.toJson(source),
      ),
      'goalId': serializer.toJson<String?>(goalId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  Completion copyWith({
    String? id,
    String? localDate,
    String? baniId,
    BaniSlotValue? slot,
    CompletionSource? source,
    Value<String?> goalId = const Value.absent(),
    DateTime? completedAt,
  }) => Completion(
    id: id ?? this.id,
    localDate: localDate ?? this.localDate,
    baniId: baniId ?? this.baniId,
    slot: slot ?? this.slot,
    source: source ?? this.source,
    goalId: goalId.present ? goalId.value : this.goalId,
    completedAt: completedAt ?? this.completedAt,
  );
  Completion copyWithCompanion(CompletionsCompanion data) {
    return Completion(
      id: data.id.present ? data.id.value : this.id,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      baniId: data.baniId.present ? data.baniId.value : this.baniId,
      slot: data.slot.present ? data.slot.value : this.slot,
      source: data.source.present ? data.source.value : this.source,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
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
          ..write('goalId: $goalId, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, localDate, baniId, slot, source, goalId, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Completion &&
          other.id == this.id &&
          other.localDate == this.localDate &&
          other.baniId == this.baniId &&
          other.slot == this.slot &&
          other.source == this.source &&
          other.goalId == this.goalId &&
          other.completedAt == this.completedAt);
}

class CompletionsCompanion extends UpdateCompanion<Completion> {
  final Value<String> id;
  final Value<String> localDate;
  final Value<String> baniId;
  final Value<BaniSlotValue> slot;
  final Value<CompletionSource> source;
  final Value<String?> goalId;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const CompletionsCompanion({
    this.id = const Value.absent(),
    this.localDate = const Value.absent(),
    this.baniId = const Value.absent(),
    this.slot = const Value.absent(),
    this.source = const Value.absent(),
    this.goalId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompletionsCompanion.insert({
    required String id,
    required String localDate,
    required String baniId,
    required BaniSlotValue slot,
    required CompletionSource source,
    this.goalId = const Value.absent(),
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localDate = Value(localDate),
       baniId = Value(baniId),
       slot = Value(slot),
       source = Value(source),
       completedAt = Value(completedAt);
  static Insertable<Completion> custom({
    Expression<String>? id,
    Expression<String>? localDate,
    Expression<String>? baniId,
    Expression<String>? slot,
    Expression<String>? source,
    Expression<String>? goalId,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localDate != null) 'local_date': localDate,
      if (baniId != null) 'bani_id': baniId,
      if (slot != null) 'slot': slot,
      if (source != null) 'source': source,
      if (goalId != null) 'goal_id': goalId,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompletionsCompanion copyWith({
    Value<String>? id,
    Value<String>? localDate,
    Value<String>? baniId,
    Value<BaniSlotValue>? slot,
    Value<CompletionSource>? source,
    Value<String?>? goalId,
    Value<DateTime>? completedAt,
    Value<int>? rowid,
  }) {
    return CompletionsCompanion(
      id: id ?? this.id,
      localDate: localDate ?? this.localDate,
      baniId: baniId ?? this.baniId,
      slot: slot ?? this.slot,
      source: source ?? this.source,
      goalId: goalId ?? this.goalId,
      completedAt: completedAt ?? this.completedAt,
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
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
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
          ..write('goalId: $goalId, ')
          ..write('completedAt: $completedAt, ')
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
  List<GeneratedColumn> get $columns => [
    id,
    localDate,
    startedAt,
    durationS,
    count,
    completed,
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
    );
  }

  @override
  $SimranSessionsTable createAlias(String alias) {
    return $SimranSessionsTable(attachedDatabase, alias);
  }
}

class SimranSession extends DataClass implements Insertable<SimranSession> {
  final String id;
  final String localDate;
  final DateTime startedAt;
  final int durationS;
  final int count;
  final bool completed;
  const SimranSession({
    required this.id,
    required this.localDate,
    required this.startedAt,
    required this.durationS,
    required this.count,
    required this.completed,
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
    };
  }

  SimranSession copyWith({
    String? id,
    String? localDate,
    DateTime? startedAt,
    int? durationS,
    int? count,
    bool? completed,
  }) => SimranSession(
    id: id ?? this.id,
    localDate: localDate ?? this.localDate,
    startedAt: startedAt ?? this.startedAt,
    durationS: durationS ?? this.durationS,
    count: count ?? this.count,
    completed: completed ?? this.completed,
  );
  SimranSession copyWithCompanion(SimranSessionsCompanion data) {
    return SimranSession(
      id: data.id.present ? data.id.value : this.id,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      count: data.count.present ? data.count.value : this.count,
      completed: data.completed.present ? data.completed.value : this.completed,
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
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, localDate, startedAt, durationS, count, completed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SimranSession &&
          other.id == this.id &&
          other.localDate == this.localDate &&
          other.startedAt == this.startedAt &&
          other.durationS == this.durationS &&
          other.count == this.count &&
          other.completed == this.completed);
}

class SimranSessionsCompanion extends UpdateCompanion<SimranSession> {
  final Value<String> id;
  final Value<String> localDate;
  final Value<DateTime> startedAt;
  final Value<int> durationS;
  final Value<int> count;
  final Value<bool> completed;
  final Value<int> rowid;
  const SimranSessionsCompanion({
    this.id = const Value.absent(),
    this.localDate = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationS = const Value.absent(),
    this.count = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SimranSessionsCompanion.insert({
    required String id,
    required String localDate,
    required DateTime startedAt,
    required int durationS,
    this.count = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localDate = Value(localDate),
       startedAt = Value(startedAt),
       durationS = Value(durationS);
  static Insertable<SimranSession> custom({
    Expression<String>? id,
    Expression<String>? localDate,
    Expression<DateTime>? startedAt,
    Expression<int>? durationS,
    Expression<int>? count,
    Expression<bool>? completed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localDate != null) 'local_date': localDate,
      if (startedAt != null) 'started_at': startedAt,
      if (durationS != null) 'duration_s': durationS,
      if (count != null) 'count': count,
      if (completed != null) 'completed': completed,
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
    Value<int>? rowid,
  }) {
    return SimranSessionsCompanion(
      id: id ?? this.id,
      localDate: localDate ?? this.localDate,
      startedAt: startedAt ?? this.startedAt,
      durationS: durationS ?? this.durationS,
      count: count ?? this.count,
      completed: completed ?? this.completed,
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
  static const VerificationMeta _baniIdMeta = const VerificationMeta('baniId');
  @override
  late final GeneratedColumn<String> baniId = GeneratedColumn<String>(
    'bani_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<GoalDuration, String>
  durationType = GeneratedColumn<String>(
    'duration_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<GoalDuration>($GoalsTable.$converterdurationType);
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<int> days = GeneratedColumn<int>(
    'days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _untilDateMeta = const VerificationMeta(
    'untilDate',
  );
  @override
  late final GeneratedColumn<String> untilDate = GeneratedColumn<String>(
    'until_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    baniId,
    timesPerDay,
    durationType,
    days,
    untilDate,
    startDate,
    reminderTime,
    active,
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
    if (data.containsKey('bani_id')) {
      context.handle(
        _baniIdMeta,
        baniId.isAcceptableOrUnknown(data['bani_id']!, _baniIdMeta),
      );
    } else if (isInserting) {
      context.missing(_baniIdMeta);
    }
    if (data.containsKey('times_per_day')) {
      context.handle(
        _timesPerDayMeta,
        timesPerDay.isAcceptableOrUnknown(
          data['times_per_day']!,
          _timesPerDayMeta,
        ),
      );
    }
    if (data.containsKey('days')) {
      context.handle(
        _daysMeta,
        days.isAcceptableOrUnknown(data['days']!, _daysMeta),
      );
    }
    if (data.containsKey('until_date')) {
      context.handle(
        _untilDateMeta,
        untilDate.isAcceptableOrUnknown(data['until_date']!, _untilDateMeta),
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
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
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
      baniId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bani_id'],
      )!,
      timesPerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_per_day'],
      )!,
      durationType: $GoalsTable.$converterdurationType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}duration_type'],
        )!,
      ),
      days: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days'],
      ),
      untilDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}until_date'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
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

  static JsonTypeConverter2<GoalDuration, String, String>
  $converterdurationType = const EnumNameConverter<GoalDuration>(
    GoalDuration.values,
  );
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String baniId;
  final int timesPerDay;
  final GoalDuration durationType;
  final int? days;
  final String? untilDate;
  final String startDate;
  final String? reminderTime;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Goal({
    required this.id,
    required this.baniId,
    required this.timesPerDay,
    required this.durationType,
    this.days,
    this.untilDate,
    required this.startDate,
    this.reminderTime,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bani_id'] = Variable<String>(baniId);
    map['times_per_day'] = Variable<int>(timesPerDay);
    {
      map['duration_type'] = Variable<String>(
        $GoalsTable.$converterdurationType.toSql(durationType),
      );
    }
    if (!nullToAbsent || days != null) {
      map['days'] = Variable<int>(days);
    }
    if (!nullToAbsent || untilDate != null) {
      map['until_date'] = Variable<String>(untilDate);
    }
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<String>(reminderTime);
    }
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      baniId: Value(baniId),
      timesPerDay: Value(timesPerDay),
      durationType: Value(durationType),
      days: days == null && nullToAbsent ? const Value.absent() : Value(days),
      untilDate: untilDate == null && nullToAbsent
          ? const Value.absent()
          : Value(untilDate),
      startDate: Value(startDate),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      active: Value(active),
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
      baniId: serializer.fromJson<String>(json['baniId']),
      timesPerDay: serializer.fromJson<int>(json['timesPerDay']),
      durationType: $GoalsTable.$converterdurationType.fromJson(
        serializer.fromJson<String>(json['durationType']),
      ),
      days: serializer.fromJson<int?>(json['days']),
      untilDate: serializer.fromJson<String?>(json['untilDate']),
      startDate: serializer.fromJson<String>(json['startDate']),
      reminderTime: serializer.fromJson<String?>(json['reminderTime']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'baniId': serializer.toJson<String>(baniId),
      'timesPerDay': serializer.toJson<int>(timesPerDay),
      'durationType': serializer.toJson<String>(
        $GoalsTable.$converterdurationType.toJson(durationType),
      ),
      'days': serializer.toJson<int?>(days),
      'untilDate': serializer.toJson<String?>(untilDate),
      'startDate': serializer.toJson<String>(startDate),
      'reminderTime': serializer.toJson<String?>(reminderTime),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Goal copyWith({
    String? id,
    String? baniId,
    int? timesPerDay,
    GoalDuration? durationType,
    Value<int?> days = const Value.absent(),
    Value<String?> untilDate = const Value.absent(),
    String? startDate,
    Value<String?> reminderTime = const Value.absent(),
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Goal(
    id: id ?? this.id,
    baniId: baniId ?? this.baniId,
    timesPerDay: timesPerDay ?? this.timesPerDay,
    durationType: durationType ?? this.durationType,
    days: days.present ? days.value : this.days,
    untilDate: untilDate.present ? untilDate.value : this.untilDate,
    startDate: startDate ?? this.startDate,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      baniId: data.baniId.present ? data.baniId.value : this.baniId,
      timesPerDay: data.timesPerDay.present
          ? data.timesPerDay.value
          : this.timesPerDay,
      durationType: data.durationType.present
          ? data.durationType.value
          : this.durationType,
      days: data.days.present ? data.days.value : this.days,
      untilDate: data.untilDate.present ? data.untilDate.value : this.untilDate,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('baniId: $baniId, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('durationType: $durationType, ')
          ..write('days: $days, ')
          ..write('untilDate: $untilDate, ')
          ..write('startDate: $startDate, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    baniId,
    timesPerDay,
    durationType,
    days,
    untilDate,
    startDate,
    reminderTime,
    active,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.baniId == this.baniId &&
          other.timesPerDay == this.timesPerDay &&
          other.durationType == this.durationType &&
          other.days == this.days &&
          other.untilDate == this.untilDate &&
          other.startDate == this.startDate &&
          other.reminderTime == this.reminderTime &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String> baniId;
  final Value<int> timesPerDay;
  final Value<GoalDuration> durationType;
  final Value<int?> days;
  final Value<String?> untilDate;
  final Value<String> startDate;
  final Value<String?> reminderTime;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.baniId = const Value.absent(),
    this.timesPerDay = const Value.absent(),
    this.durationType = const Value.absent(),
    this.days = const Value.absent(),
    this.untilDate = const Value.absent(),
    this.startDate = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String baniId,
    this.timesPerDay = const Value.absent(),
    required GoalDuration durationType,
    this.days = const Value.absent(),
    this.untilDate = const Value.absent(),
    required String startDate,
    this.reminderTime = const Value.absent(),
    this.active = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       baniId = Value(baniId),
       durationType = Value(durationType),
       startDate = Value(startDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? baniId,
    Expression<int>? timesPerDay,
    Expression<String>? durationType,
    Expression<int>? days,
    Expression<String>? untilDate,
    Expression<String>? startDate,
    Expression<String>? reminderTime,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baniId != null) 'bani_id': baniId,
      if (timesPerDay != null) 'times_per_day': timesPerDay,
      if (durationType != null) 'duration_type': durationType,
      if (days != null) 'days': days,
      if (untilDate != null) 'until_date': untilDate,
      if (startDate != null) 'start_date': startDate,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? baniId,
    Value<int>? timesPerDay,
    Value<GoalDuration>? durationType,
    Value<int?>? days,
    Value<String?>? untilDate,
    Value<String>? startDate,
    Value<String?>? reminderTime,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      baniId: baniId ?? this.baniId,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      durationType: durationType ?? this.durationType,
      days: days ?? this.days,
      untilDate: untilDate ?? this.untilDate,
      startDate: startDate ?? this.startDate,
      reminderTime: reminderTime ?? this.reminderTime,
      active: active ?? this.active,
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
    if (baniId.present) {
      map['bani_id'] = Variable<String>(baniId.value);
    }
    if (timesPerDay.present) {
      map['times_per_day'] = Variable<int>(timesPerDay.value);
    }
    if (durationType.present) {
      map['duration_type'] = Variable<String>(
        $GoalsTable.$converterdurationType.toSql(durationType.value),
      );
    }
    if (days.present) {
      map['days'] = Variable<int>(days.value);
    }
    if (untilDate.present) {
      map['until_date'] = Variable<String>(untilDate.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
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
          ..write('baniId: $baniId, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('durationType: $durationType, ')
          ..write('days: $days, ')
          ..write('untilDate: $untilDate, ')
          ..write('startDate: $startDate, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalTicksTable extends GoalTicks
    with TableInfo<$GoalTicksTable, GoalTick> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalTicksTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [id, goalId, localDate, source, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_ticks';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalTick> instance, {
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
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalTick map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalTick(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $GoalTicksTable createAlias(String alias) {
    return $GoalTicksTable(attachedDatabase, alias);
  }
}

class GoalTick extends DataClass implements Insertable<GoalTick> {
  final String id;
  final String goalId;
  final String localDate;
  final String source;
  final DateTime at;
  const GoalTick({
    required this.id,
    required this.goalId,
    required this.localDate,
    required this.source,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['local_date'] = Variable<String>(localDate);
    map['source'] = Variable<String>(source);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  GoalTicksCompanion toCompanion(bool nullToAbsent) {
    return GoalTicksCompanion(
      id: Value(id),
      goalId: Value(goalId),
      localDate: Value(localDate),
      source: Value(source),
      at: Value(at),
    );
  }

  factory GoalTick.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalTick(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      localDate: serializer.fromJson<String>(json['localDate']),
      source: serializer.fromJson<String>(json['source']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'localDate': serializer.toJson<String>(localDate),
      'source': serializer.toJson<String>(source),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  GoalTick copyWith({
    String? id,
    String? goalId,
    String? localDate,
    String? source,
    DateTime? at,
  }) => GoalTick(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    localDate: localDate ?? this.localDate,
    source: source ?? this.source,
    at: at ?? this.at,
  );
  GoalTick copyWithCompanion(GoalTicksCompanion data) {
    return GoalTick(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      source: data.source.present ? data.source.value : this.source,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalTick(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('localDate: $localDate, ')
          ..write('source: $source, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, localDate, source, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalTick &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.localDate == this.localDate &&
          other.source == this.source &&
          other.at == this.at);
}

class GoalTicksCompanion extends UpdateCompanion<GoalTick> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> localDate;
  final Value<String> source;
  final Value<DateTime> at;
  final Value<int> rowid;
  const GoalTicksCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.localDate = const Value.absent(),
    this.source = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalTicksCompanion.insert({
    required String id,
    required String goalId,
    required String localDate,
    required String source,
    required DateTime at,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       localDate = Value(localDate),
       source = Value(source),
       at = Value(at);
  static Insertable<GoalTick> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? localDate,
    Expression<String>? source,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (localDate != null) 'local_date': localDate,
      if (source != null) 'source': source,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalTicksCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? localDate,
    Value<String>? source,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return GoalTicksCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      localDate: localDate ?? this.localDate,
      source: source ?? this.source,
      at: at ?? this.at,
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
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalTicksCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('localDate: $localDate, ')
          ..write('source: $source, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderTarget, String>
  targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ReminderTarget>($RemindersTable.$convertertargetType);
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderMode, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReminderMode>($RemindersTable.$convertermode);
  static const VerificationMeta _anchorMeta = const VerificationMeta('anchor');
  @override
  late final GeneratedColumn<String> anchor = GeneratedColumn<String>(
    'anchor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offsetMinMeta = const VerificationMeta(
    'offsetMin',
  );
  @override
  late final GeneratedColumn<int> offsetMin = GeneratedColumn<int>(
    'offset_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeHhmmMeta = const VerificationMeta(
    'timeHhmm',
  );
  @override
  late final GeneratedColumn<String> timeHhmm = GeneratedColumn<String>(
    'time_hhmm',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _daysMaskMeta = const VerificationMeta(
    'daysMask',
  );
  @override
  late final GeneratedColumn<int> daysMask = GeneratedColumn<int>(
    'days_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0x7F),
  );
  static const VerificationMeta _slotOverrideMeta = const VerificationMeta(
    'slotOverride',
  );
  @override
  late final GeneratedColumn<String> slotOverride = GeneratedColumn<String>(
    'slot_override',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    targetType,
    targetId,
    mode,
    anchor,
    offsetMin,
    timeHhmm,
    daysMask,
    slotOverride,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('anchor')) {
      context.handle(
        _anchorMeta,
        anchor.isAcceptableOrUnknown(data['anchor']!, _anchorMeta),
      );
    }
    if (data.containsKey('offset_min')) {
      context.handle(
        _offsetMinMeta,
        offsetMin.isAcceptableOrUnknown(data['offset_min']!, _offsetMinMeta),
      );
    }
    if (data.containsKey('time_hhmm')) {
      context.handle(
        _timeHhmmMeta,
        timeHhmm.isAcceptableOrUnknown(data['time_hhmm']!, _timeHhmmMeta),
      );
    }
    if (data.containsKey('days_mask')) {
      context.handle(
        _daysMaskMeta,
        daysMask.isAcceptableOrUnknown(data['days_mask']!, _daysMaskMeta),
      );
    }
    if (data.containsKey('slot_override')) {
      context.handle(
        _slotOverrideMeta,
        slotOverride.isAcceptableOrUnknown(
          data['slot_override']!,
          _slotOverrideMeta,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      targetType: $RemindersTable.$convertertargetType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}target_type'],
        )!,
      ),
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      mode: $RemindersTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        )!,
      ),
      anchor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor'],
      ),
      offsetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_min'],
      ),
      timeHhmm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_hhmm'],
      ),
      daysMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_mask'],
      )!,
      slotOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot_override'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReminderTarget, String, String>
  $convertertargetType = const EnumNameConverter<ReminderTarget>(
    ReminderTarget.values,
  );
  static JsonTypeConverter2<ReminderMode, String, String> $convertermode =
      const EnumNameConverter<ReminderMode>(ReminderMode.values);
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final String id;
  final ReminderTarget targetType;
  final String targetId;
  final ReminderMode mode;
  final String? anchor;
  final int? offsetMin;
  final String? timeHhmm;
  final int daysMask;
  final String? slotOverride;
  final DateTime updatedAt;
  const Reminder({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.mode,
    this.anchor,
    this.offsetMin,
    this.timeHhmm,
    required this.daysMask,
    this.slotOverride,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['target_type'] = Variable<String>(
        $RemindersTable.$convertertargetType.toSql(targetType),
      );
    }
    map['target_id'] = Variable<String>(targetId);
    {
      map['mode'] = Variable<String>(
        $RemindersTable.$convertermode.toSql(mode),
      );
    }
    if (!nullToAbsent || anchor != null) {
      map['anchor'] = Variable<String>(anchor);
    }
    if (!nullToAbsent || offsetMin != null) {
      map['offset_min'] = Variable<int>(offsetMin);
    }
    if (!nullToAbsent || timeHhmm != null) {
      map['time_hhmm'] = Variable<String>(timeHhmm);
    }
    map['days_mask'] = Variable<int>(daysMask);
    if (!nullToAbsent || slotOverride != null) {
      map['slot_override'] = Variable<String>(slotOverride);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      targetType: Value(targetType),
      targetId: Value(targetId),
      mode: Value(mode),
      anchor: anchor == null && nullToAbsent
          ? const Value.absent()
          : Value(anchor),
      offsetMin: offsetMin == null && nullToAbsent
          ? const Value.absent()
          : Value(offsetMin),
      timeHhmm: timeHhmm == null && nullToAbsent
          ? const Value.absent()
          : Value(timeHhmm),
      daysMask: Value(daysMask),
      slotOverride: slotOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(slotOverride),
      updatedAt: Value(updatedAt),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<String>(json['id']),
      targetType: $RemindersTable.$convertertargetType.fromJson(
        serializer.fromJson<String>(json['targetType']),
      ),
      targetId: serializer.fromJson<String>(json['targetId']),
      mode: $RemindersTable.$convertermode.fromJson(
        serializer.fromJson<String>(json['mode']),
      ),
      anchor: serializer.fromJson<String?>(json['anchor']),
      offsetMin: serializer.fromJson<int?>(json['offsetMin']),
      timeHhmm: serializer.fromJson<String?>(json['timeHhmm']),
      daysMask: serializer.fromJson<int>(json['daysMask']),
      slotOverride: serializer.fromJson<String?>(json['slotOverride']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetType': serializer.toJson<String>(
        $RemindersTable.$convertertargetType.toJson(targetType),
      ),
      'targetId': serializer.toJson<String>(targetId),
      'mode': serializer.toJson<String>(
        $RemindersTable.$convertermode.toJson(mode),
      ),
      'anchor': serializer.toJson<String?>(anchor),
      'offsetMin': serializer.toJson<int?>(offsetMin),
      'timeHhmm': serializer.toJson<String?>(timeHhmm),
      'daysMask': serializer.toJson<int>(daysMask),
      'slotOverride': serializer.toJson<String?>(slotOverride),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Reminder copyWith({
    String? id,
    ReminderTarget? targetType,
    String? targetId,
    ReminderMode? mode,
    Value<String?> anchor = const Value.absent(),
    Value<int?> offsetMin = const Value.absent(),
    Value<String?> timeHhmm = const Value.absent(),
    int? daysMask,
    Value<String?> slotOverride = const Value.absent(),
    DateTime? updatedAt,
  }) => Reminder(
    id: id ?? this.id,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
    mode: mode ?? this.mode,
    anchor: anchor.present ? anchor.value : this.anchor,
    offsetMin: offsetMin.present ? offsetMin.value : this.offsetMin,
    timeHhmm: timeHhmm.present ? timeHhmm.value : this.timeHhmm,
    daysMask: daysMask ?? this.daysMask,
    slotOverride: slotOverride.present ? slotOverride.value : this.slotOverride,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      mode: data.mode.present ? data.mode.value : this.mode,
      anchor: data.anchor.present ? data.anchor.value : this.anchor,
      offsetMin: data.offsetMin.present ? data.offsetMin.value : this.offsetMin,
      timeHhmm: data.timeHhmm.present ? data.timeHhmm.value : this.timeHhmm,
      daysMask: data.daysMask.present ? data.daysMask.value : this.daysMask,
      slotOverride: data.slotOverride.present
          ? data.slotOverride.value
          : this.slotOverride,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('mode: $mode, ')
          ..write('anchor: $anchor, ')
          ..write('offsetMin: $offsetMin, ')
          ..write('timeHhmm: $timeHhmm, ')
          ..write('daysMask: $daysMask, ')
          ..write('slotOverride: $slotOverride, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetType,
    targetId,
    mode,
    anchor,
    offsetMin,
    timeHhmm,
    daysMask,
    slotOverride,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.mode == this.mode &&
          other.anchor == this.anchor &&
          other.offsetMin == this.offsetMin &&
          other.timeHhmm == this.timeHhmm &&
          other.daysMask == this.daysMask &&
          other.slotOverride == this.slotOverride &&
          other.updatedAt == this.updatedAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<String> id;
  final Value<ReminderTarget> targetType;
  final Value<String> targetId;
  final Value<ReminderMode> mode;
  final Value<String?> anchor;
  final Value<int?> offsetMin;
  final Value<String?> timeHhmm;
  final Value<int> daysMask;
  final Value<String?> slotOverride;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.mode = const Value.absent(),
    this.anchor = const Value.absent(),
    this.offsetMin = const Value.absent(),
    this.timeHhmm = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.slotOverride = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required ReminderTarget targetType,
    required String targetId,
    required ReminderMode mode,
    this.anchor = const Value.absent(),
    this.offsetMin = const Value.absent(),
    this.timeHhmm = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.slotOverride = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       targetType = Value(targetType),
       targetId = Value(targetId),
       mode = Value(mode),
       updatedAt = Value(updatedAt);
  static Insertable<Reminder> custom({
    Expression<String>? id,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<String>? mode,
    Expression<String>? anchor,
    Expression<int>? offsetMin,
    Expression<String>? timeHhmm,
    Expression<int>? daysMask,
    Expression<String>? slotOverride,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (mode != null) 'mode': mode,
      if (anchor != null) 'anchor': anchor,
      if (offsetMin != null) 'offset_min': offsetMin,
      if (timeHhmm != null) 'time_hhmm': timeHhmm,
      if (daysMask != null) 'days_mask': daysMask,
      if (slotOverride != null) 'slot_override': slotOverride,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<ReminderTarget>? targetType,
    Value<String>? targetId,
    Value<ReminderMode>? mode,
    Value<String?>? anchor,
    Value<int?>? offsetMin,
    Value<String?>? timeHhmm,
    Value<int>? daysMask,
    Value<String?>? slotOverride,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      mode: mode ?? this.mode,
      anchor: anchor ?? this.anchor,
      offsetMin: offsetMin ?? this.offsetMin,
      timeHhmm: timeHhmm ?? this.timeHhmm,
      daysMask: daysMask ?? this.daysMask,
      slotOverride: slotOverride ?? this.slotOverride,
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
    if (targetType.present) {
      map['target_type'] = Variable<String>(
        $RemindersTable.$convertertargetType.toSql(targetType.value),
      );
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
        $RemindersTable.$convertermode.toSql(mode.value),
      );
    }
    if (anchor.present) {
      map['anchor'] = Variable<String>(anchor.value);
    }
    if (offsetMin.present) {
      map['offset_min'] = Variable<int>(offsetMin.value);
    }
    if (timeHhmm.present) {
      map['time_hhmm'] = Variable<String>(timeHhmm.value);
    }
    if (daysMask.present) {
      map['days_mask'] = Variable<int>(daysMask.value);
    }
    if (slotOverride.present) {
      map['slot_override'] = Variable<String>(slotOverride.value);
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
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('mode: $mode, ')
          ..write('anchor: $anchor, ')
          ..write('offsetMin: $offsetMin, ')
          ..write('timeHhmm: $timeHhmm, ')
          ..write('daysMask: $daysMask, ')
          ..write('slotOverride: $slotOverride, ')
          ..write('updatedAt: $updatedAt, ')
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

abstract class _$UserDb extends GeneratedDatabase {
  _$UserDb(QueryExecutor e) : super(e);
  $UserDbManager get managers => $UserDbManager(this);
  late final $ReadingProgressTable readingProgress = $ReadingProgressTable(
    this,
  );
  late final $CompletionsTable completions = $CompletionsTable(this);
  late final $SimranSessionsTable simranSessions = $SimranSessionsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $GoalTicksTable goalTicks = $GoalTicksTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $GraceDaysTable graceDays = $GraceDaysTable(this);
  late final $EventReminderOverridesTable eventReminderOverrides =
      $EventReminderOverridesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    readingProgress,
    completions,
    simranSessions,
    goals,
    goalTicks,
    reminders,
    graceDays,
    eventReminderOverrides,
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
      Value<String?> goalId,
      required DateTime completedAt,
      Value<int> rowid,
    });
typedef $$CompletionsTableUpdateCompanionBuilder =
    CompletionsCompanion Function({
      Value<String> id,
      Value<String> localDate,
      Value<String> baniId,
      Value<BaniSlotValue> slot,
      Value<CompletionSource> source,
      Value<String?> goalId,
      Value<DateTime> completedAt,
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

  ColumnFilters<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
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

  ColumnOrderings<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
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

  GeneratedColumn<String> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
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
                Value<String?> goalId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletionsCompanion(
                id: id,
                localDate: localDate,
                baniId: baniId,
                slot: slot,
                source: source,
                goalId: goalId,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String localDate,
                required String baniId,
                required BaniSlotValue slot,
                required CompletionSource source,
                Value<String?> goalId = const Value.absent(),
                required DateTime completedAt,
                Value<int> rowid = const Value.absent(),
              }) => CompletionsCompanion.insert(
                id: id,
                localDate: localDate,
                baniId: baniId,
                slot: slot,
                source: source,
                goalId: goalId,
                completedAt: completedAt,
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
                Value<int> rowid = const Value.absent(),
              }) => SimranSessionsCompanion(
                id: id,
                localDate: localDate,
                startedAt: startedAt,
                durationS: durationS,
                count: count,
                completed: completed,
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
                Value<int> rowid = const Value.absent(),
              }) => SimranSessionsCompanion.insert(
                id: id,
                localDate: localDate,
                startedAt: startedAt,
                durationS: durationS,
                count: count,
                completed: completed,
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
      required String baniId,
      Value<int> timesPerDay,
      required GoalDuration durationType,
      Value<int?> days,
      Value<String?> untilDate,
      required String startDate,
      Value<String?> reminderTime,
      Value<bool> active,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<String> id,
      Value<String> baniId,
      Value<int> timesPerDay,
      Value<GoalDuration> durationType,
      Value<int?> days,
      Value<String?> untilDate,
      Value<String> startDate,
      Value<String?> reminderTime,
      Value<bool> active,
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

  ColumnFilters<String> get baniId => $composableBuilder(
    column: $table.baniId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timesPerDay => $composableBuilder(
    column: $table.timesPerDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GoalDuration, GoalDuration, String>
  get durationType => $composableBuilder(
    column: $table.durationType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get untilDate => $composableBuilder(
    column: $table.untilDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
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

  ColumnOrderings<String> get baniId => $composableBuilder(
    column: $table.baniId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timesPerDay => $composableBuilder(
    column: $table.timesPerDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get durationType => $composableBuilder(
    column: $table.durationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get untilDate => $composableBuilder(
    column: $table.untilDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
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

  GeneratedColumn<String> get baniId =>
      $composableBuilder(column: $table.baniId, builder: (column) => column);

  GeneratedColumn<int> get timesPerDay => $composableBuilder(
    column: $table.timesPerDay,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<GoalDuration, String> get durationType =>
      $composableBuilder(
        column: $table.durationType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);

  GeneratedColumn<String> get untilDate =>
      $composableBuilder(column: $table.untilDate, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

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
                Value<String> baniId = const Value.absent(),
                Value<int> timesPerDay = const Value.absent(),
                Value<GoalDuration> durationType = const Value.absent(),
                Value<int?> days = const Value.absent(),
                Value<String?> untilDate = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                baniId: baniId,
                timesPerDay: timesPerDay,
                durationType: durationType,
                days: days,
                untilDate: untilDate,
                startDate: startDate,
                reminderTime: reminderTime,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String baniId,
                Value<int> timesPerDay = const Value.absent(),
                required GoalDuration durationType,
                Value<int?> days = const Value.absent(),
                Value<String?> untilDate = const Value.absent(),
                required String startDate,
                Value<String?> reminderTime = const Value.absent(),
                Value<bool> active = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                baniId: baniId,
                timesPerDay: timesPerDay,
                durationType: durationType,
                days: days,
                untilDate: untilDate,
                startDate: startDate,
                reminderTime: reminderTime,
                active: active,
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
typedef $$GoalTicksTableCreateCompanionBuilder =
    GoalTicksCompanion Function({
      required String id,
      required String goalId,
      required String localDate,
      required String source,
      required DateTime at,
      Value<int> rowid,
    });
typedef $$GoalTicksTableUpdateCompanionBuilder =
    GoalTicksCompanion Function({
      Value<String> id,
      Value<String> goalId,
      Value<String> localDate,
      Value<String> source,
      Value<DateTime> at,
      Value<int> rowid,
    });

class $$GoalTicksTableFilterComposer
    extends Composer<_$UserDb, $GoalTicksTable> {
  $$GoalTicksTableFilterComposer({
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

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
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
}

class $$GoalTicksTableOrderingComposer
    extends Composer<_$UserDb, $GoalTicksTable> {
  $$GoalTicksTableOrderingComposer({
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

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
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
}

class $$GoalTicksTableAnnotationComposer
    extends Composer<_$UserDb, $GoalTicksTable> {
  $$GoalTicksTableAnnotationComposer({
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

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$GoalTicksTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $GoalTicksTable,
          GoalTick,
          $$GoalTicksTableFilterComposer,
          $$GoalTicksTableOrderingComposer,
          $$GoalTicksTableAnnotationComposer,
          $$GoalTicksTableCreateCompanionBuilder,
          $$GoalTicksTableUpdateCompanionBuilder,
          (GoalTick, BaseReferences<_$UserDb, $GoalTicksTable, GoalTick>),
          GoalTick,
          PrefetchHooks Function()
        > {
  $$GoalTicksTableTableManager(_$UserDb db, $GoalTicksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalTicksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalTicksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalTicksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalTicksCompanion(
                id: id,
                goalId: goalId,
                localDate: localDate,
                source: source,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String localDate,
                required String source,
                required DateTime at,
                Value<int> rowid = const Value.absent(),
              }) => GoalTicksCompanion.insert(
                id: id,
                goalId: goalId,
                localDate: localDate,
                source: source,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalTicksTable, GoalTick>(table),
                  BaseReferences<_$UserDb, $GoalTicksTable, GoalTick>(
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

typedef $$GoalTicksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $GoalTicksTable,
      GoalTick,
      $$GoalTicksTableFilterComposer,
      $$GoalTicksTableOrderingComposer,
      $$GoalTicksTableAnnotationComposer,
      $$GoalTicksTableCreateCompanionBuilder,
      $$GoalTicksTableUpdateCompanionBuilder,
      (GoalTick, BaseReferences<_$UserDb, $GoalTicksTable, GoalTick>),
      GoalTick,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      required String id,
      required ReminderTarget targetType,
      required String targetId,
      required ReminderMode mode,
      Value<String?> anchor,
      Value<int?> offsetMin,
      Value<String?> timeHhmm,
      Value<int> daysMask,
      Value<String?> slotOverride,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<String> id,
      Value<ReminderTarget> targetType,
      Value<String> targetId,
      Value<ReminderMode> mode,
      Value<String?> anchor,
      Value<int?> offsetMin,
      Value<String?> timeHhmm,
      Value<int> daysMask,
      Value<String?> slotOverride,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$UserDb, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnWithTypeConverterFilters<ReminderTarget, ReminderTarget, String>
  get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReminderMode, ReminderMode, String> get mode =>
      $composableBuilder(
        column: $table.mode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMin => $composableBuilder(
    column: $table.offsetMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeHhmm => $composableBuilder(
    column: $table.timeHhmm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysMask => $composableBuilder(
    column: $table.daysMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slotOverride => $composableBuilder(
    column: $table.slotOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$UserDb, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMin => $composableBuilder(
    column: $table.offsetMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeHhmm => $composableBuilder(
    column: $table.timeHhmm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysMask => $composableBuilder(
    column: $table.daysMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slotOverride => $composableBuilder(
    column: $table.slotOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$UserDb, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReminderTarget, String> get targetType =>
      $composableBuilder(
        column: $table.targetType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReminderMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get anchor =>
      $composableBuilder(column: $table.anchor, builder: (column) => column);

  GeneratedColumn<int> get offsetMin =>
      $composableBuilder(column: $table.offsetMin, builder: (column) => column);

  GeneratedColumn<String> get timeHhmm =>
      $composableBuilder(column: $table.timeHhmm, builder: (column) => column);

  GeneratedColumn<int> get daysMask =>
      $composableBuilder(column: $table.daysMask, builder: (column) => column);

  GeneratedColumn<String> get slotOverride => $composableBuilder(
    column: $table.slotOverride,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, BaseReferences<_$UserDb, $RemindersTable, Reminder>),
          Reminder,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$UserDb db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<ReminderTarget> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<ReminderMode> mode = const Value.absent(),
                Value<String?> anchor = const Value.absent(),
                Value<int?> offsetMin = const Value.absent(),
                Value<String?> timeHhmm = const Value.absent(),
                Value<int> daysMask = const Value.absent(),
                Value<String?> slotOverride = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                targetType: targetType,
                targetId: targetId,
                mode: mode,
                anchor: anchor,
                offsetMin: offsetMin,
                timeHhmm: timeHhmm,
                daysMask: daysMask,
                slotOverride: slotOverride,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required ReminderTarget targetType,
                required String targetId,
                required ReminderMode mode,
                Value<String?> anchor = const Value.absent(),
                Value<int?> offsetMin = const Value.absent(),
                Value<String?> timeHhmm = const Value.absent(),
                Value<int> daysMask = const Value.absent(),
                Value<String?> slotOverride = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                targetType: targetType,
                targetId: targetId,
                mode: mode,
                anchor: anchor,
                offsetMin: offsetMin,
                timeHhmm: timeHhmm,
                daysMask: daysMask,
                slotOverride: slotOverride,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, Reminder>(table),
                  BaseReferences<_$UserDb, $RemindersTable, Reminder>(
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

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, BaseReferences<_$UserDb, $RemindersTable, Reminder>),
      Reminder,
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
  $$GoalTicksTableTableManager get goalTicks =>
      $$GoalTicksTableTableManager(_db, _db.goalTicks);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$GraceDaysTableTableManager get graceDays =>
      $$GraceDaysTableTableManager(_db, _db.graceDays);
  $$EventReminderOverridesTableTableManager get eventReminderOverrides =>
      $$EventReminderOverridesTableTableManager(
        _db,
        _db.eventReminderOverrides,
      );
}
