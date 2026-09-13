// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_db.dart';

// ignore_for_file: type=lint
class $SourcesTable extends Sources with TableInfo<$SourcesTable, SourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _licenceMeta = const VerificationMeta(
    'licence',
  );
  @override
  late final GeneratedColumn<String> licence = GeneratedColumn<String>(
    'licence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publisherMeta = const VerificationMeta(
    'publisher',
  );
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
    'publisher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pubDateMeta = const VerificationMeta(
    'pubDate',
  );
  @override
  late final GeneratedColumn<String> pubDate = GeneratedColumn<String>(
    'pub_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    author,
    kind,
    licence,
    url,
    notes,
    publisher,
    pubDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('licence')) {
      context.handle(
        _licenceMeta,
        licence.isAcceptableOrUnknown(data['licence']!, _licenceMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('publisher')) {
      context.handle(
        _publisherMeta,
        publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta),
      );
    }
    if (data.containsKey('pub_date')) {
      context.handle(
        _pubDateMeta,
        pubDate.isAcceptableOrUnknown(data['pub_date']!, _pubDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      licence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}licence'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      publisher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publisher'],
      ),
      pubDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pub_date'],
      ),
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class SourceRow extends DataClass implements Insertable<SourceRow> {
  final String id;
  final String name;
  final String? author;
  final String kind;
  final String? licence;
  final String? url;
  final String? notes;
  final String? publisher;
  final String? pubDate;
  const SourceRow({
    required this.id,
    required this.name,
    this.author,
    required this.kind,
    this.licence,
    this.url,
    this.notes,
    this.publisher,
    this.pubDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || licence != null) {
      map['licence'] = Variable<String>(licence);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || publisher != null) {
      map['publisher'] = Variable<String>(publisher);
    }
    if (!nullToAbsent || pubDate != null) {
      map['pub_date'] = Variable<String>(pubDate);
    }
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      name: Value(name),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      kind: Value(kind),
      licence: licence == null && nullToAbsent
          ? const Value.absent()
          : Value(licence),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      publisher: publisher == null && nullToAbsent
          ? const Value.absent()
          : Value(publisher),
      pubDate: pubDate == null && nullToAbsent
          ? const Value.absent()
          : Value(pubDate),
    );
  }

  factory SourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      author: serializer.fromJson<String?>(json['author']),
      kind: serializer.fromJson<String>(json['kind']),
      licence: serializer.fromJson<String?>(json['licence']),
      url: serializer.fromJson<String?>(json['url']),
      notes: serializer.fromJson<String?>(json['notes']),
      publisher: serializer.fromJson<String?>(json['publisher']),
      pubDate: serializer.fromJson<String?>(json['pubDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'author': serializer.toJson<String?>(author),
      'kind': serializer.toJson<String>(kind),
      'licence': serializer.toJson<String?>(licence),
      'url': serializer.toJson<String?>(url),
      'notes': serializer.toJson<String?>(notes),
      'publisher': serializer.toJson<String?>(publisher),
      'pubDate': serializer.toJson<String?>(pubDate),
    };
  }

  SourceRow copyWith({
    String? id,
    String? name,
    Value<String?> author = const Value.absent(),
    String? kind,
    Value<String?> licence = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> publisher = const Value.absent(),
    Value<String?> pubDate = const Value.absent(),
  }) => SourceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    author: author.present ? author.value : this.author,
    kind: kind ?? this.kind,
    licence: licence.present ? licence.value : this.licence,
    url: url.present ? url.value : this.url,
    notes: notes.present ? notes.value : this.notes,
    publisher: publisher.present ? publisher.value : this.publisher,
    pubDate: pubDate.present ? pubDate.value : this.pubDate,
  );
  SourceRow copyWithCompanion(SourcesCompanion data) {
    return SourceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      author: data.author.present ? data.author.value : this.author,
      kind: data.kind.present ? data.kind.value : this.kind,
      licence: data.licence.present ? data.licence.value : this.licence,
      url: data.url.present ? data.url.value : this.url,
      notes: data.notes.present ? data.notes.value : this.notes,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      pubDate: data.pubDate.present ? data.pubDate.value : this.pubDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('kind: $kind, ')
          ..write('licence: $licence, ')
          ..write('url: $url, ')
          ..write('notes: $notes, ')
          ..write('publisher: $publisher, ')
          ..write('pubDate: $pubDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    author,
    kind,
    licence,
    url,
    notes,
    publisher,
    pubDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.author == this.author &&
          other.kind == this.kind &&
          other.licence == this.licence &&
          other.url == this.url &&
          other.notes == this.notes &&
          other.publisher == this.publisher &&
          other.pubDate == this.pubDate);
}

class SourcesCompanion extends UpdateCompanion<SourceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> author;
  final Value<String> kind;
  final Value<String?> licence;
  final Value<String?> url;
  final Value<String?> notes;
  final Value<String?> publisher;
  final Value<String?> pubDate;
  final Value<int> rowid;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.author = const Value.absent(),
    this.kind = const Value.absent(),
    this.licence = const Value.absent(),
    this.url = const Value.absent(),
    this.notes = const Value.absent(),
    this.publisher = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcesCompanion.insert({
    required String id,
    required String name,
    this.author = const Value.absent(),
    required String kind,
    this.licence = const Value.absent(),
    this.url = const Value.absent(),
    this.notes = const Value.absent(),
    this.publisher = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind);
  static Insertable<SourceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? author,
    Expression<String>? kind,
    Expression<String>? licence,
    Expression<String>? url,
    Expression<String>? notes,
    Expression<String>? publisher,
    Expression<String>? pubDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (author != null) 'author': author,
      if (kind != null) 'kind': kind,
      if (licence != null) 'licence': licence,
      if (url != null) 'url': url,
      if (notes != null) 'notes': notes,
      if (publisher != null) 'publisher': publisher,
      if (pubDate != null) 'pub_date': pubDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? author,
    Value<String>? kind,
    Value<String?>? licence,
    Value<String?>? url,
    Value<String?>? notes,
    Value<String?>? publisher,
    Value<String?>? pubDate,
    Value<int>? rowid,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      kind: kind ?? this.kind,
      licence: licence ?? this.licence,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      publisher: publisher ?? this.publisher,
      pubDate: pubDate ?? this.pubDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (licence.present) {
      map['licence'] = Variable<String>(licence.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (pubDate.present) {
      map['pub_date'] = Variable<String>(pubDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('kind: $kind, ')
          ..write('licence: $licence, ')
          ..write('url: $url, ')
          ..write('notes: $notes, ')
          ..write('publisher: $publisher, ')
          ..write('pubDate: $pubDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BanisTable extends Banis with TableInfo<$BanisTable, BaniRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BanisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namePaMeta = const VerificationMeta('namePa');
  @override
  late final GeneratedColumn<String> namePa = GeneratedColumn<String>(
    'name_pa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameHiMeta = const VerificationMeta('nameHi');
  @override
  late final GeneratedColumn<String> nameHi = GeneratedColumn<String>(
    'name_hi',
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
  static const VerificationMeta _defaultSlotMeta = const VerificationMeta(
    'defaultSlot',
  );
  @override
  late final GeneratedColumn<String> defaultSlot = GeneratedColumn<String>(
    'default_slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estMinutesMeta = const VerificationMeta(
    'estMinutes',
  );
  @override
  late final GeneratedColumn<int> estMinutes = GeneratedColumn<int>(
    'est_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorEnMeta = const VerificationMeta(
    'authorEn',
  );
  @override
  late final GeneratedColumn<String> authorEn = GeneratedColumn<String>(
    'author_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasTextMeta = const VerificationMeta(
    'hasText',
  );
  @override
  late final GeneratedColumn<bool> hasText = GeneratedColumn<bool>(
    'has_text',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_text" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    slug,
    nameEn,
    namePa,
    nameHi,
    category,
    defaultSlot,
    sort,
    estMinutes,
    authorEn,
    hasText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bani';
  @override
  VerificationContext validateIntegrity(
    Insertable<BaniRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_pa')) {
      context.handle(
        _namePaMeta,
        namePa.isAcceptableOrUnknown(data['name_pa']!, _namePaMeta),
      );
    } else if (isInserting) {
      context.missing(_namePaMeta);
    }
    if (data.containsKey('name_hi')) {
      context.handle(
        _nameHiMeta,
        nameHi.isAcceptableOrUnknown(data['name_hi']!, _nameHiMeta),
      );
    } else if (isInserting) {
      context.missing(_nameHiMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('default_slot')) {
      context.handle(
        _defaultSlotMeta,
        defaultSlot.isAcceptableOrUnknown(
          data['default_slot']!,
          _defaultSlotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultSlotMeta);
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    } else if (isInserting) {
      context.missing(_sortMeta);
    }
    if (data.containsKey('est_minutes')) {
      context.handle(
        _estMinutesMeta,
        estMinutes.isAcceptableOrUnknown(data['est_minutes']!, _estMinutesMeta),
      );
    } else if (isInserting) {
      context.missing(_estMinutesMeta);
    }
    if (data.containsKey('author_en')) {
      context.handle(
        _authorEnMeta,
        authorEn.isAcceptableOrUnknown(data['author_en']!, _authorEnMeta),
      );
    }
    if (data.containsKey('has_text')) {
      context.handle(
        _hasTextMeta,
        hasText.isAcceptableOrUnknown(data['has_text']!, _hasTextMeta),
      );
    } else if (isInserting) {
      context.missing(_hasTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BaniRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BaniRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      namePa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_pa'],
      )!,
      nameHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_hi'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      defaultSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_slot'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
      estMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}est_minutes'],
      )!,
      authorEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_en'],
      ),
      hasText: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_text'],
      )!,
    );
  }

  @override
  $BanisTable createAlias(String alias) {
    return $BanisTable(attachedDatabase, alias);
  }
}

class BaniRow extends DataClass implements Insertable<BaniRow> {
  final String id;
  final String slug;
  final String nameEn;
  final String namePa;
  final String nameHi;
  final String category;
  final String defaultSlot;
  final int sort;
  final int estMinutes;
  final String? authorEn;
  final bool hasText;
  const BaniRow({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.namePa,
    required this.nameHi,
    required this.category,
    required this.defaultSlot,
    required this.sort,
    required this.estMinutes,
    this.authorEn,
    required this.hasText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['slug'] = Variable<String>(slug);
    map['name_en'] = Variable<String>(nameEn);
    map['name_pa'] = Variable<String>(namePa);
    map['name_hi'] = Variable<String>(nameHi);
    map['category'] = Variable<String>(category);
    map['default_slot'] = Variable<String>(defaultSlot);
    map['sort'] = Variable<int>(sort);
    map['est_minutes'] = Variable<int>(estMinutes);
    if (!nullToAbsent || authorEn != null) {
      map['author_en'] = Variable<String>(authorEn);
    }
    map['has_text'] = Variable<bool>(hasText);
    return map;
  }

  BanisCompanion toCompanion(bool nullToAbsent) {
    return BanisCompanion(
      id: Value(id),
      slug: Value(slug),
      nameEn: Value(nameEn),
      namePa: Value(namePa),
      nameHi: Value(nameHi),
      category: Value(category),
      defaultSlot: Value(defaultSlot),
      sort: Value(sort),
      estMinutes: Value(estMinutes),
      authorEn: authorEn == null && nullToAbsent
          ? const Value.absent()
          : Value(authorEn),
      hasText: Value(hasText),
    );
  }

  factory BaniRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BaniRow(
      id: serializer.fromJson<String>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      namePa: serializer.fromJson<String>(json['namePa']),
      nameHi: serializer.fromJson<String>(json['nameHi']),
      category: serializer.fromJson<String>(json['category']),
      defaultSlot: serializer.fromJson<String>(json['defaultSlot']),
      sort: serializer.fromJson<int>(json['sort']),
      estMinutes: serializer.fromJson<int>(json['estMinutes']),
      authorEn: serializer.fromJson<String?>(json['authorEn']),
      hasText: serializer.fromJson<bool>(json['hasText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'slug': serializer.toJson<String>(slug),
      'nameEn': serializer.toJson<String>(nameEn),
      'namePa': serializer.toJson<String>(namePa),
      'nameHi': serializer.toJson<String>(nameHi),
      'category': serializer.toJson<String>(category),
      'defaultSlot': serializer.toJson<String>(defaultSlot),
      'sort': serializer.toJson<int>(sort),
      'estMinutes': serializer.toJson<int>(estMinutes),
      'authorEn': serializer.toJson<String?>(authorEn),
      'hasText': serializer.toJson<bool>(hasText),
    };
  }

  BaniRow copyWith({
    String? id,
    String? slug,
    String? nameEn,
    String? namePa,
    String? nameHi,
    String? category,
    String? defaultSlot,
    int? sort,
    int? estMinutes,
    Value<String?> authorEn = const Value.absent(),
    bool? hasText,
  }) => BaniRow(
    id: id ?? this.id,
    slug: slug ?? this.slug,
    nameEn: nameEn ?? this.nameEn,
    namePa: namePa ?? this.namePa,
    nameHi: nameHi ?? this.nameHi,
    category: category ?? this.category,
    defaultSlot: defaultSlot ?? this.defaultSlot,
    sort: sort ?? this.sort,
    estMinutes: estMinutes ?? this.estMinutes,
    authorEn: authorEn.present ? authorEn.value : this.authorEn,
    hasText: hasText ?? this.hasText,
  );
  BaniRow copyWithCompanion(BanisCompanion data) {
    return BaniRow(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      namePa: data.namePa.present ? data.namePa.value : this.namePa,
      nameHi: data.nameHi.present ? data.nameHi.value : this.nameHi,
      category: data.category.present ? data.category.value : this.category,
      defaultSlot: data.defaultSlot.present
          ? data.defaultSlot.value
          : this.defaultSlot,
      sort: data.sort.present ? data.sort.value : this.sort,
      estMinutes: data.estMinutes.present
          ? data.estMinutes.value
          : this.estMinutes,
      authorEn: data.authorEn.present ? data.authorEn.value : this.authorEn,
      hasText: data.hasText.present ? data.hasText.value : this.hasText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BaniRow(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('nameEn: $nameEn, ')
          ..write('namePa: $namePa, ')
          ..write('nameHi: $nameHi, ')
          ..write('category: $category, ')
          ..write('defaultSlot: $defaultSlot, ')
          ..write('sort: $sort, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('authorEn: $authorEn, ')
          ..write('hasText: $hasText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    slug,
    nameEn,
    namePa,
    nameHi,
    category,
    defaultSlot,
    sort,
    estMinutes,
    authorEn,
    hasText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BaniRow &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.nameEn == this.nameEn &&
          other.namePa == this.namePa &&
          other.nameHi == this.nameHi &&
          other.category == this.category &&
          other.defaultSlot == this.defaultSlot &&
          other.sort == this.sort &&
          other.estMinutes == this.estMinutes &&
          other.authorEn == this.authorEn &&
          other.hasText == this.hasText);
}

class BanisCompanion extends UpdateCompanion<BaniRow> {
  final Value<String> id;
  final Value<String> slug;
  final Value<String> nameEn;
  final Value<String> namePa;
  final Value<String> nameHi;
  final Value<String> category;
  final Value<String> defaultSlot;
  final Value<int> sort;
  final Value<int> estMinutes;
  final Value<String?> authorEn;
  final Value<bool> hasText;
  final Value<int> rowid;
  const BanisCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.namePa = const Value.absent(),
    this.nameHi = const Value.absent(),
    this.category = const Value.absent(),
    this.defaultSlot = const Value.absent(),
    this.sort = const Value.absent(),
    this.estMinutes = const Value.absent(),
    this.authorEn = const Value.absent(),
    this.hasText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BanisCompanion.insert({
    required String id,
    required String slug,
    required String nameEn,
    required String namePa,
    required String nameHi,
    required String category,
    required String defaultSlot,
    required int sort,
    required int estMinutes,
    this.authorEn = const Value.absent(),
    required bool hasText,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       slug = Value(slug),
       nameEn = Value(nameEn),
       namePa = Value(namePa),
       nameHi = Value(nameHi),
       category = Value(category),
       defaultSlot = Value(defaultSlot),
       sort = Value(sort),
       estMinutes = Value(estMinutes),
       hasText = Value(hasText);
  static Insertable<BaniRow> custom({
    Expression<String>? id,
    Expression<String>? slug,
    Expression<String>? nameEn,
    Expression<String>? namePa,
    Expression<String>? nameHi,
    Expression<String>? category,
    Expression<String>? defaultSlot,
    Expression<int>? sort,
    Expression<int>? estMinutes,
    Expression<String>? authorEn,
    Expression<bool>? hasText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (nameEn != null) 'name_en': nameEn,
      if (namePa != null) 'name_pa': namePa,
      if (nameHi != null) 'name_hi': nameHi,
      if (category != null) 'category': category,
      if (defaultSlot != null) 'default_slot': defaultSlot,
      if (sort != null) 'sort': sort,
      if (estMinutes != null) 'est_minutes': estMinutes,
      if (authorEn != null) 'author_en': authorEn,
      if (hasText != null) 'has_text': hasText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BanisCompanion copyWith({
    Value<String>? id,
    Value<String>? slug,
    Value<String>? nameEn,
    Value<String>? namePa,
    Value<String>? nameHi,
    Value<String>? category,
    Value<String>? defaultSlot,
    Value<int>? sort,
    Value<int>? estMinutes,
    Value<String?>? authorEn,
    Value<bool>? hasText,
    Value<int>? rowid,
  }) {
    return BanisCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      nameEn: nameEn ?? this.nameEn,
      namePa: namePa ?? this.namePa,
      nameHi: nameHi ?? this.nameHi,
      category: category ?? this.category,
      defaultSlot: defaultSlot ?? this.defaultSlot,
      sort: sort ?? this.sort,
      estMinutes: estMinutes ?? this.estMinutes,
      authorEn: authorEn ?? this.authorEn,
      hasText: hasText ?? this.hasText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (namePa.present) {
      map['name_pa'] = Variable<String>(namePa.value);
    }
    if (nameHi.present) {
      map['name_hi'] = Variable<String>(nameHi.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (defaultSlot.present) {
      map['default_slot'] = Variable<String>(defaultSlot.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (estMinutes.present) {
      map['est_minutes'] = Variable<int>(estMinutes.value);
    }
    if (authorEn.present) {
      map['author_en'] = Variable<String>(authorEn.value);
    }
    if (hasText.present) {
      map['has_text'] = Variable<bool>(hasText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BanisCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('nameEn: $nameEn, ')
          ..write('namePa: $namePa, ')
          ..write('nameHi: $nameHi, ')
          ..write('category: $category, ')
          ..write('defaultSlot: $defaultSlot, ')
          ..write('sort: $sort, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('authorEn: $authorEn, ')
          ..write('hasText: $hasText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BaniVersionsTable extends BaniVersions
    with TableInfo<$BaniVersionsTable, BaniVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BaniVersionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelEnMeta = const VerificationMeta(
    'labelEn',
  );
  @override
  late final GeneratedColumn<String> labelEn = GeneratedColumn<String>(
    'label_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelPaMeta = const VerificationMeta(
    'labelPa',
  );
  @override
  late final GeneratedColumn<String> labelPa = GeneratedColumn<String>(
    'label_pa',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelHiMeta = const VerificationMeta(
    'labelHi',
  );
  @override
  late final GeneratedColumn<String> labelHi = GeneratedColumn<String>(
    'label_hi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lineCountMeta = const VerificationMeta(
    'lineCount',
  );
  @override
  late final GeneratedColumn<int> lineCount = GeneratedColumn<int>(
    'line_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    baniId,
    code,
    labelEn,
    labelPa,
    labelHi,
    isDefault,
    lineCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bani_version';
  @override
  VerificationContext validateIntegrity(
    Insertable<BaniVersionRow> instance, {
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
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('label_en')) {
      context.handle(
        _labelEnMeta,
        labelEn.isAcceptableOrUnknown(data['label_en']!, _labelEnMeta),
      );
    }
    if (data.containsKey('label_pa')) {
      context.handle(
        _labelPaMeta,
        labelPa.isAcceptableOrUnknown(data['label_pa']!, _labelPaMeta),
      );
    }
    if (data.containsKey('label_hi')) {
      context.handle(
        _labelHiMeta,
        labelHi.isAcceptableOrUnknown(data['label_hi']!, _labelHiMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    } else if (isInserting) {
      context.missing(_isDefaultMeta);
    }
    if (data.containsKey('line_count')) {
      context.handle(
        _lineCountMeta,
        lineCount.isAcceptableOrUnknown(data['line_count']!, _lineCountMeta),
      );
    } else if (isInserting) {
      context.missing(_lineCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BaniVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BaniVersionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      baniId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bani_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      labelEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_en'],
      ),
      labelPa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_pa'],
      ),
      labelHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_hi'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      lineCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_count'],
      )!,
    );
  }

  @override
  $BaniVersionsTable createAlias(String alias) {
    return $BaniVersionsTable(attachedDatabase, alias);
  }
}

class BaniVersionRow extends DataClass implements Insertable<BaniVersionRow> {
  final String id;
  final String baniId;
  final String code;
  final String? labelEn;
  final String? labelPa;
  final String? labelHi;
  final bool isDefault;
  final int lineCount;
  const BaniVersionRow({
    required this.id,
    required this.baniId,
    required this.code,
    this.labelEn,
    this.labelPa,
    this.labelHi,
    required this.isDefault,
    required this.lineCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bani_id'] = Variable<String>(baniId);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || labelEn != null) {
      map['label_en'] = Variable<String>(labelEn);
    }
    if (!nullToAbsent || labelPa != null) {
      map['label_pa'] = Variable<String>(labelPa);
    }
    if (!nullToAbsent || labelHi != null) {
      map['label_hi'] = Variable<String>(labelHi);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['line_count'] = Variable<int>(lineCount);
    return map;
  }

  BaniVersionsCompanion toCompanion(bool nullToAbsent) {
    return BaniVersionsCompanion(
      id: Value(id),
      baniId: Value(baniId),
      code: Value(code),
      labelEn: labelEn == null && nullToAbsent
          ? const Value.absent()
          : Value(labelEn),
      labelPa: labelPa == null && nullToAbsent
          ? const Value.absent()
          : Value(labelPa),
      labelHi: labelHi == null && nullToAbsent
          ? const Value.absent()
          : Value(labelHi),
      isDefault: Value(isDefault),
      lineCount: Value(lineCount),
    );
  }

  factory BaniVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BaniVersionRow(
      id: serializer.fromJson<String>(json['id']),
      baniId: serializer.fromJson<String>(json['baniId']),
      code: serializer.fromJson<String>(json['code']),
      labelEn: serializer.fromJson<String?>(json['labelEn']),
      labelPa: serializer.fromJson<String?>(json['labelPa']),
      labelHi: serializer.fromJson<String?>(json['labelHi']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      lineCount: serializer.fromJson<int>(json['lineCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'baniId': serializer.toJson<String>(baniId),
      'code': serializer.toJson<String>(code),
      'labelEn': serializer.toJson<String?>(labelEn),
      'labelPa': serializer.toJson<String?>(labelPa),
      'labelHi': serializer.toJson<String?>(labelHi),
      'isDefault': serializer.toJson<bool>(isDefault),
      'lineCount': serializer.toJson<int>(lineCount),
    };
  }

  BaniVersionRow copyWith({
    String? id,
    String? baniId,
    String? code,
    Value<String?> labelEn = const Value.absent(),
    Value<String?> labelPa = const Value.absent(),
    Value<String?> labelHi = const Value.absent(),
    bool? isDefault,
    int? lineCount,
  }) => BaniVersionRow(
    id: id ?? this.id,
    baniId: baniId ?? this.baniId,
    code: code ?? this.code,
    labelEn: labelEn.present ? labelEn.value : this.labelEn,
    labelPa: labelPa.present ? labelPa.value : this.labelPa,
    labelHi: labelHi.present ? labelHi.value : this.labelHi,
    isDefault: isDefault ?? this.isDefault,
    lineCount: lineCount ?? this.lineCount,
  );
  BaniVersionRow copyWithCompanion(BaniVersionsCompanion data) {
    return BaniVersionRow(
      id: data.id.present ? data.id.value : this.id,
      baniId: data.baniId.present ? data.baniId.value : this.baniId,
      code: data.code.present ? data.code.value : this.code,
      labelEn: data.labelEn.present ? data.labelEn.value : this.labelEn,
      labelPa: data.labelPa.present ? data.labelPa.value : this.labelPa,
      labelHi: data.labelHi.present ? data.labelHi.value : this.labelHi,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      lineCount: data.lineCount.present ? data.lineCount.value : this.lineCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BaniVersionRow(')
          ..write('id: $id, ')
          ..write('baniId: $baniId, ')
          ..write('code: $code, ')
          ..write('labelEn: $labelEn, ')
          ..write('labelPa: $labelPa, ')
          ..write('labelHi: $labelHi, ')
          ..write('isDefault: $isDefault, ')
          ..write('lineCount: $lineCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    baniId,
    code,
    labelEn,
    labelPa,
    labelHi,
    isDefault,
    lineCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BaniVersionRow &&
          other.id == this.id &&
          other.baniId == this.baniId &&
          other.code == this.code &&
          other.labelEn == this.labelEn &&
          other.labelPa == this.labelPa &&
          other.labelHi == this.labelHi &&
          other.isDefault == this.isDefault &&
          other.lineCount == this.lineCount);
}

class BaniVersionsCompanion extends UpdateCompanion<BaniVersionRow> {
  final Value<String> id;
  final Value<String> baniId;
  final Value<String> code;
  final Value<String?> labelEn;
  final Value<String?> labelPa;
  final Value<String?> labelHi;
  final Value<bool> isDefault;
  final Value<int> lineCount;
  final Value<int> rowid;
  const BaniVersionsCompanion({
    this.id = const Value.absent(),
    this.baniId = const Value.absent(),
    this.code = const Value.absent(),
    this.labelEn = const Value.absent(),
    this.labelPa = const Value.absent(),
    this.labelHi = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.lineCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BaniVersionsCompanion.insert({
    required String id,
    required String baniId,
    required String code,
    this.labelEn = const Value.absent(),
    this.labelPa = const Value.absent(),
    this.labelHi = const Value.absent(),
    required bool isDefault,
    required int lineCount,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       baniId = Value(baniId),
       code = Value(code),
       isDefault = Value(isDefault),
       lineCount = Value(lineCount);
  static Insertable<BaniVersionRow> custom({
    Expression<String>? id,
    Expression<String>? baniId,
    Expression<String>? code,
    Expression<String>? labelEn,
    Expression<String>? labelPa,
    Expression<String>? labelHi,
    Expression<bool>? isDefault,
    Expression<int>? lineCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baniId != null) 'bani_id': baniId,
      if (code != null) 'code': code,
      if (labelEn != null) 'label_en': labelEn,
      if (labelPa != null) 'label_pa': labelPa,
      if (labelHi != null) 'label_hi': labelHi,
      if (isDefault != null) 'is_default': isDefault,
      if (lineCount != null) 'line_count': lineCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BaniVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? baniId,
    Value<String>? code,
    Value<String?>? labelEn,
    Value<String?>? labelPa,
    Value<String?>? labelHi,
    Value<bool>? isDefault,
    Value<int>? lineCount,
    Value<int>? rowid,
  }) {
    return BaniVersionsCompanion(
      id: id ?? this.id,
      baniId: baniId ?? this.baniId,
      code: code ?? this.code,
      labelEn: labelEn ?? this.labelEn,
      labelPa: labelPa ?? this.labelPa,
      labelHi: labelHi ?? this.labelHi,
      isDefault: isDefault ?? this.isDefault,
      lineCount: lineCount ?? this.lineCount,
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
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (labelEn.present) {
      map['label_en'] = Variable<String>(labelEn.value);
    }
    if (labelPa.present) {
      map['label_pa'] = Variable<String>(labelPa.value);
    }
    if (labelHi.present) {
      map['label_hi'] = Variable<String>(labelHi.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (lineCount.present) {
      map['line_count'] = Variable<int>(lineCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BaniVersionsCompanion(')
          ..write('id: $id, ')
          ..write('baniId: $baniId, ')
          ..write('code: $code, ')
          ..write('labelEn: $labelEn, ')
          ..write('labelPa: $labelPa, ')
          ..write('labelHi: $labelHi, ')
          ..write('isDefault: $isDefault, ')
          ..write('lineCount: $lineCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LinesTable extends Lines with TableInfo<$LinesTable, LineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
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
  static const VerificationMeta _idxMeta = const VerificationMeta('idx');
  @override
  late final GeneratedColumn<int> idx = GeneratedColumn<int>(
    'idx',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionLabelEnMeta = const VerificationMeta(
    'sectionLabelEn',
  );
  @override
  late final GeneratedColumn<String> sectionLabelEn = GeneratedColumn<String>(
    'section_label_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sectionLabelPaMeta = const VerificationMeta(
    'sectionLabelPa',
  );
  @override
  late final GeneratedColumn<String> sectionLabelPa = GeneratedColumn<String>(
    'section_label_pa',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sectionLabelHiMeta = const VerificationMeta(
    'sectionLabelHi',
  );
  @override
  late final GeneratedColumn<String> sectionLabelHi = GeneratedColumn<String>(
    'section_label_hi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _gurmukhiMeta = const VerificationMeta(
    'gurmukhi',
  );
  @override
  late final GeneratedColumn<String> gurmukhi = GeneratedColumn<String>(
    'gurmukhi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _devanagariMeta = const VerificationMeta(
    'devanagari',
  );
  @override
  late final GeneratedColumn<String> devanagari = GeneratedColumn<String>(
    'devanagari',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _romanMeta = const VerificationMeta('roman');
  @override
  late final GeneratedColumn<String> roman = GeneratedColumn<String>(
    'roman',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visraamJsonMeta = const VerificationMeta(
    'visraamJson',
  );
  @override
  late final GeneratedColumn<String> visraamJson = GeneratedColumn<String>(
    'visraam_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
    'word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordAlignMeta = const VerificationMeta(
    'wordAlign',
  );
  @override
  late final GeneratedColumn<bool> wordAlign = GeneratedColumn<bool>(
    'word_align',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("word_align" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceRefMeta = const VerificationMeta(
    'sourceRef',
  );
  @override
  late final GeneratedColumn<String> sourceRef = GeneratedColumn<String>(
    'source_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pauriMeta = const VerificationMeta('pauri');
  @override
  late final GeneratedColumn<int> pauri = GeneratedColumn<int>(
    'pauri',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endsPauriMeta = const VerificationMeta(
    'endsPauri',
  );
  @override
  late final GeneratedColumn<bool> endsPauri = GeneratedColumn<bool>(
    'ends_pauri',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ends_pauri" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    baniVersionId,
    idx,
    sectionLabelEn,
    sectionLabelPa,
    sectionLabelHi,
    kind,
    gurmukhi,
    devanagari,
    roman,
    visraamJson,
    wordCount,
    wordAlign,
    sourceId,
    sourceRef,
    pauri,
    endsPauri,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'line';
  @override
  VerificationContext validateIntegrity(
    Insertable<LineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    if (data.containsKey('idx')) {
      context.handle(
        _idxMeta,
        idx.isAcceptableOrUnknown(data['idx']!, _idxMeta),
      );
    } else if (isInserting) {
      context.missing(_idxMeta);
    }
    if (data.containsKey('section_label_en')) {
      context.handle(
        _sectionLabelEnMeta,
        sectionLabelEn.isAcceptableOrUnknown(
          data['section_label_en']!,
          _sectionLabelEnMeta,
        ),
      );
    }
    if (data.containsKey('section_label_pa')) {
      context.handle(
        _sectionLabelPaMeta,
        sectionLabelPa.isAcceptableOrUnknown(
          data['section_label_pa']!,
          _sectionLabelPaMeta,
        ),
      );
    }
    if (data.containsKey('section_label_hi')) {
      context.handle(
        _sectionLabelHiMeta,
        sectionLabelHi.isAcceptableOrUnknown(
          data['section_label_hi']!,
          _sectionLabelHiMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('gurmukhi')) {
      context.handle(
        _gurmukhiMeta,
        gurmukhi.isAcceptableOrUnknown(data['gurmukhi']!, _gurmukhiMeta),
      );
    } else if (isInserting) {
      context.missing(_gurmukhiMeta);
    }
    if (data.containsKey('devanagari')) {
      context.handle(
        _devanagariMeta,
        devanagari.isAcceptableOrUnknown(data['devanagari']!, _devanagariMeta),
      );
    } else if (isInserting) {
      context.missing(_devanagariMeta);
    }
    if (data.containsKey('roman')) {
      context.handle(
        _romanMeta,
        roman.isAcceptableOrUnknown(data['roman']!, _romanMeta),
      );
    } else if (isInserting) {
      context.missing(_romanMeta);
    }
    if (data.containsKey('visraam_json')) {
      context.handle(
        _visraamJsonMeta,
        visraamJson.isAcceptableOrUnknown(
          data['visraam_json']!,
          _visraamJsonMeta,
        ),
      );
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    } else if (isInserting) {
      context.missing(_wordCountMeta);
    }
    if (data.containsKey('word_align')) {
      context.handle(
        _wordAlignMeta,
        wordAlign.isAcceptableOrUnknown(data['word_align']!, _wordAlignMeta),
      );
    } else if (isInserting) {
      context.missing(_wordAlignMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('source_ref')) {
      context.handle(
        _sourceRefMeta,
        sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta),
      );
    }
    if (data.containsKey('pauri')) {
      context.handle(
        _pauriMeta,
        pauri.isAcceptableOrUnknown(data['pauri']!, _pauriMeta),
      );
    }
    if (data.containsKey('ends_pauri')) {
      context.handle(
        _endsPauriMeta,
        endsPauri.isAcceptableOrUnknown(data['ends_pauri']!, _endsPauriMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      baniVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bani_version_id'],
      )!,
      idx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}idx'],
      )!,
      sectionLabelEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_label_en'],
      ),
      sectionLabelPa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_label_pa'],
      ),
      sectionLabelHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_label_hi'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      gurmukhi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gurmukhi'],
      )!,
      devanagari: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devanagari'],
      )!,
      roman: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roman'],
      )!,
      visraamJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visraam_json'],
      ),
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_count'],
      )!,
      wordAlign: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}word_align'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      sourceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_ref'],
      ),
      pauri: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pauri'],
      ),
      endsPauri: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ends_pauri'],
      ),
    );
  }

  @override
  $LinesTable createAlias(String alias) {
    return $LinesTable(attachedDatabase, alias);
  }
}

class LineRow extends DataClass implements Insertable<LineRow> {
  final int id;
  final String baniVersionId;
  final int idx;
  final String? sectionLabelEn;
  final String? sectionLabelPa;
  final String? sectionLabelHi;
  final String kind;
  final String gurmukhi;
  final String devanagari;
  final String roman;
  final String? visraamJson;
  final int wordCount;
  final bool wordAlign;
  final String? sourceId;
  final String? sourceRef;
  final int? pauri;
  final bool? endsPauri;
  const LineRow({
    required this.id,
    required this.baniVersionId,
    required this.idx,
    this.sectionLabelEn,
    this.sectionLabelPa,
    this.sectionLabelHi,
    required this.kind,
    required this.gurmukhi,
    required this.devanagari,
    required this.roman,
    this.visraamJson,
    required this.wordCount,
    required this.wordAlign,
    this.sourceId,
    this.sourceRef,
    this.pauri,
    this.endsPauri,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bani_version_id'] = Variable<String>(baniVersionId);
    map['idx'] = Variable<int>(idx);
    if (!nullToAbsent || sectionLabelEn != null) {
      map['section_label_en'] = Variable<String>(sectionLabelEn);
    }
    if (!nullToAbsent || sectionLabelPa != null) {
      map['section_label_pa'] = Variable<String>(sectionLabelPa);
    }
    if (!nullToAbsent || sectionLabelHi != null) {
      map['section_label_hi'] = Variable<String>(sectionLabelHi);
    }
    map['kind'] = Variable<String>(kind);
    map['gurmukhi'] = Variable<String>(gurmukhi);
    map['devanagari'] = Variable<String>(devanagari);
    map['roman'] = Variable<String>(roman);
    if (!nullToAbsent || visraamJson != null) {
      map['visraam_json'] = Variable<String>(visraamJson);
    }
    map['word_count'] = Variable<int>(wordCount);
    map['word_align'] = Variable<bool>(wordAlign);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || sourceRef != null) {
      map['source_ref'] = Variable<String>(sourceRef);
    }
    if (!nullToAbsent || pauri != null) {
      map['pauri'] = Variable<int>(pauri);
    }
    if (!nullToAbsent || endsPauri != null) {
      map['ends_pauri'] = Variable<bool>(endsPauri);
    }
    return map;
  }

  LinesCompanion toCompanion(bool nullToAbsent) {
    return LinesCompanion(
      id: Value(id),
      baniVersionId: Value(baniVersionId),
      idx: Value(idx),
      sectionLabelEn: sectionLabelEn == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionLabelEn),
      sectionLabelPa: sectionLabelPa == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionLabelPa),
      sectionLabelHi: sectionLabelHi == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionLabelHi),
      kind: Value(kind),
      gurmukhi: Value(gurmukhi),
      devanagari: Value(devanagari),
      roman: Value(roman),
      visraamJson: visraamJson == null && nullToAbsent
          ? const Value.absent()
          : Value(visraamJson),
      wordCount: Value(wordCount),
      wordAlign: Value(wordAlign),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      sourceRef: sourceRef == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRef),
      pauri: pauri == null && nullToAbsent
          ? const Value.absent()
          : Value(pauri),
      endsPauri: endsPauri == null && nullToAbsent
          ? const Value.absent()
          : Value(endsPauri),
    );
  }

  factory LineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LineRow(
      id: serializer.fromJson<int>(json['id']),
      baniVersionId: serializer.fromJson<String>(json['baniVersionId']),
      idx: serializer.fromJson<int>(json['idx']),
      sectionLabelEn: serializer.fromJson<String?>(json['sectionLabelEn']),
      sectionLabelPa: serializer.fromJson<String?>(json['sectionLabelPa']),
      sectionLabelHi: serializer.fromJson<String?>(json['sectionLabelHi']),
      kind: serializer.fromJson<String>(json['kind']),
      gurmukhi: serializer.fromJson<String>(json['gurmukhi']),
      devanagari: serializer.fromJson<String>(json['devanagari']),
      roman: serializer.fromJson<String>(json['roman']),
      visraamJson: serializer.fromJson<String?>(json['visraamJson']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      wordAlign: serializer.fromJson<bool>(json['wordAlign']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      sourceRef: serializer.fromJson<String?>(json['sourceRef']),
      pauri: serializer.fromJson<int?>(json['pauri']),
      endsPauri: serializer.fromJson<bool?>(json['endsPauri']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'baniVersionId': serializer.toJson<String>(baniVersionId),
      'idx': serializer.toJson<int>(idx),
      'sectionLabelEn': serializer.toJson<String?>(sectionLabelEn),
      'sectionLabelPa': serializer.toJson<String?>(sectionLabelPa),
      'sectionLabelHi': serializer.toJson<String?>(sectionLabelHi),
      'kind': serializer.toJson<String>(kind),
      'gurmukhi': serializer.toJson<String>(gurmukhi),
      'devanagari': serializer.toJson<String>(devanagari),
      'roman': serializer.toJson<String>(roman),
      'visraamJson': serializer.toJson<String?>(visraamJson),
      'wordCount': serializer.toJson<int>(wordCount),
      'wordAlign': serializer.toJson<bool>(wordAlign),
      'sourceId': serializer.toJson<String?>(sourceId),
      'sourceRef': serializer.toJson<String?>(sourceRef),
      'pauri': serializer.toJson<int?>(pauri),
      'endsPauri': serializer.toJson<bool?>(endsPauri),
    };
  }

  LineRow copyWith({
    int? id,
    String? baniVersionId,
    int? idx,
    Value<String?> sectionLabelEn = const Value.absent(),
    Value<String?> sectionLabelPa = const Value.absent(),
    Value<String?> sectionLabelHi = const Value.absent(),
    String? kind,
    String? gurmukhi,
    String? devanagari,
    String? roman,
    Value<String?> visraamJson = const Value.absent(),
    int? wordCount,
    bool? wordAlign,
    Value<String?> sourceId = const Value.absent(),
    Value<String?> sourceRef = const Value.absent(),
    Value<int?> pauri = const Value.absent(),
    Value<bool?> endsPauri = const Value.absent(),
  }) => LineRow(
    id: id ?? this.id,
    baniVersionId: baniVersionId ?? this.baniVersionId,
    idx: idx ?? this.idx,
    sectionLabelEn: sectionLabelEn.present
        ? sectionLabelEn.value
        : this.sectionLabelEn,
    sectionLabelPa: sectionLabelPa.present
        ? sectionLabelPa.value
        : this.sectionLabelPa,
    sectionLabelHi: sectionLabelHi.present
        ? sectionLabelHi.value
        : this.sectionLabelHi,
    kind: kind ?? this.kind,
    gurmukhi: gurmukhi ?? this.gurmukhi,
    devanagari: devanagari ?? this.devanagari,
    roman: roman ?? this.roman,
    visraamJson: visraamJson.present ? visraamJson.value : this.visraamJson,
    wordCount: wordCount ?? this.wordCount,
    wordAlign: wordAlign ?? this.wordAlign,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    sourceRef: sourceRef.present ? sourceRef.value : this.sourceRef,
    pauri: pauri.present ? pauri.value : this.pauri,
    endsPauri: endsPauri.present ? endsPauri.value : this.endsPauri,
  );
  LineRow copyWithCompanion(LinesCompanion data) {
    return LineRow(
      id: data.id.present ? data.id.value : this.id,
      baniVersionId: data.baniVersionId.present
          ? data.baniVersionId.value
          : this.baniVersionId,
      idx: data.idx.present ? data.idx.value : this.idx,
      sectionLabelEn: data.sectionLabelEn.present
          ? data.sectionLabelEn.value
          : this.sectionLabelEn,
      sectionLabelPa: data.sectionLabelPa.present
          ? data.sectionLabelPa.value
          : this.sectionLabelPa,
      sectionLabelHi: data.sectionLabelHi.present
          ? data.sectionLabelHi.value
          : this.sectionLabelHi,
      kind: data.kind.present ? data.kind.value : this.kind,
      gurmukhi: data.gurmukhi.present ? data.gurmukhi.value : this.gurmukhi,
      devanagari: data.devanagari.present
          ? data.devanagari.value
          : this.devanagari,
      roman: data.roman.present ? data.roman.value : this.roman,
      visraamJson: data.visraamJson.present
          ? data.visraamJson.value
          : this.visraamJson,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      wordAlign: data.wordAlign.present ? data.wordAlign.value : this.wordAlign,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
      pauri: data.pauri.present ? data.pauri.value : this.pauri,
      endsPauri: data.endsPauri.present ? data.endsPauri.value : this.endsPauri,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LineRow(')
          ..write('id: $id, ')
          ..write('baniVersionId: $baniVersionId, ')
          ..write('idx: $idx, ')
          ..write('sectionLabelEn: $sectionLabelEn, ')
          ..write('sectionLabelPa: $sectionLabelPa, ')
          ..write('sectionLabelHi: $sectionLabelHi, ')
          ..write('kind: $kind, ')
          ..write('gurmukhi: $gurmukhi, ')
          ..write('devanagari: $devanagari, ')
          ..write('roman: $roman, ')
          ..write('visraamJson: $visraamJson, ')
          ..write('wordCount: $wordCount, ')
          ..write('wordAlign: $wordAlign, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('pauri: $pauri, ')
          ..write('endsPauri: $endsPauri')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    baniVersionId,
    idx,
    sectionLabelEn,
    sectionLabelPa,
    sectionLabelHi,
    kind,
    gurmukhi,
    devanagari,
    roman,
    visraamJson,
    wordCount,
    wordAlign,
    sourceId,
    sourceRef,
    pauri,
    endsPauri,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LineRow &&
          other.id == this.id &&
          other.baniVersionId == this.baniVersionId &&
          other.idx == this.idx &&
          other.sectionLabelEn == this.sectionLabelEn &&
          other.sectionLabelPa == this.sectionLabelPa &&
          other.sectionLabelHi == this.sectionLabelHi &&
          other.kind == this.kind &&
          other.gurmukhi == this.gurmukhi &&
          other.devanagari == this.devanagari &&
          other.roman == this.roman &&
          other.visraamJson == this.visraamJson &&
          other.wordCount == this.wordCount &&
          other.wordAlign == this.wordAlign &&
          other.sourceId == this.sourceId &&
          other.sourceRef == this.sourceRef &&
          other.pauri == this.pauri &&
          other.endsPauri == this.endsPauri);
}

class LinesCompanion extends UpdateCompanion<LineRow> {
  final Value<int> id;
  final Value<String> baniVersionId;
  final Value<int> idx;
  final Value<String?> sectionLabelEn;
  final Value<String?> sectionLabelPa;
  final Value<String?> sectionLabelHi;
  final Value<String> kind;
  final Value<String> gurmukhi;
  final Value<String> devanagari;
  final Value<String> roman;
  final Value<String?> visraamJson;
  final Value<int> wordCount;
  final Value<bool> wordAlign;
  final Value<String?> sourceId;
  final Value<String?> sourceRef;
  final Value<int?> pauri;
  final Value<bool?> endsPauri;
  const LinesCompanion({
    this.id = const Value.absent(),
    this.baniVersionId = const Value.absent(),
    this.idx = const Value.absent(),
    this.sectionLabelEn = const Value.absent(),
    this.sectionLabelPa = const Value.absent(),
    this.sectionLabelHi = const Value.absent(),
    this.kind = const Value.absent(),
    this.gurmukhi = const Value.absent(),
    this.devanagari = const Value.absent(),
    this.roman = const Value.absent(),
    this.visraamJson = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.wordAlign = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.pauri = const Value.absent(),
    this.endsPauri = const Value.absent(),
  });
  LinesCompanion.insert({
    this.id = const Value.absent(),
    required String baniVersionId,
    required int idx,
    this.sectionLabelEn = const Value.absent(),
    this.sectionLabelPa = const Value.absent(),
    this.sectionLabelHi = const Value.absent(),
    required String kind,
    required String gurmukhi,
    required String devanagari,
    required String roman,
    this.visraamJson = const Value.absent(),
    required int wordCount,
    required bool wordAlign,
    this.sourceId = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.pauri = const Value.absent(),
    this.endsPauri = const Value.absent(),
  }) : baniVersionId = Value(baniVersionId),
       idx = Value(idx),
       kind = Value(kind),
       gurmukhi = Value(gurmukhi),
       devanagari = Value(devanagari),
       roman = Value(roman),
       wordCount = Value(wordCount),
       wordAlign = Value(wordAlign);
  static Insertable<LineRow> custom({
    Expression<int>? id,
    Expression<String>? baniVersionId,
    Expression<int>? idx,
    Expression<String>? sectionLabelEn,
    Expression<String>? sectionLabelPa,
    Expression<String>? sectionLabelHi,
    Expression<String>? kind,
    Expression<String>? gurmukhi,
    Expression<String>? devanagari,
    Expression<String>? roman,
    Expression<String>? visraamJson,
    Expression<int>? wordCount,
    Expression<bool>? wordAlign,
    Expression<String>? sourceId,
    Expression<String>? sourceRef,
    Expression<int>? pauri,
    Expression<bool>? endsPauri,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baniVersionId != null) 'bani_version_id': baniVersionId,
      if (idx != null) 'idx': idx,
      if (sectionLabelEn != null) 'section_label_en': sectionLabelEn,
      if (sectionLabelPa != null) 'section_label_pa': sectionLabelPa,
      if (sectionLabelHi != null) 'section_label_hi': sectionLabelHi,
      if (kind != null) 'kind': kind,
      if (gurmukhi != null) 'gurmukhi': gurmukhi,
      if (devanagari != null) 'devanagari': devanagari,
      if (roman != null) 'roman': roman,
      if (visraamJson != null) 'visraam_json': visraamJson,
      if (wordCount != null) 'word_count': wordCount,
      if (wordAlign != null) 'word_align': wordAlign,
      if (sourceId != null) 'source_id': sourceId,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (pauri != null) 'pauri': pauri,
      if (endsPauri != null) 'ends_pauri': endsPauri,
    });
  }

  LinesCompanion copyWith({
    Value<int>? id,
    Value<String>? baniVersionId,
    Value<int>? idx,
    Value<String?>? sectionLabelEn,
    Value<String?>? sectionLabelPa,
    Value<String?>? sectionLabelHi,
    Value<String>? kind,
    Value<String>? gurmukhi,
    Value<String>? devanagari,
    Value<String>? roman,
    Value<String?>? visraamJson,
    Value<int>? wordCount,
    Value<bool>? wordAlign,
    Value<String?>? sourceId,
    Value<String?>? sourceRef,
    Value<int?>? pauri,
    Value<bool?>? endsPauri,
  }) {
    return LinesCompanion(
      id: id ?? this.id,
      baniVersionId: baniVersionId ?? this.baniVersionId,
      idx: idx ?? this.idx,
      sectionLabelEn: sectionLabelEn ?? this.sectionLabelEn,
      sectionLabelPa: sectionLabelPa ?? this.sectionLabelPa,
      sectionLabelHi: sectionLabelHi ?? this.sectionLabelHi,
      kind: kind ?? this.kind,
      gurmukhi: gurmukhi ?? this.gurmukhi,
      devanagari: devanagari ?? this.devanagari,
      roman: roman ?? this.roman,
      visraamJson: visraamJson ?? this.visraamJson,
      wordCount: wordCount ?? this.wordCount,
      wordAlign: wordAlign ?? this.wordAlign,
      sourceId: sourceId ?? this.sourceId,
      sourceRef: sourceRef ?? this.sourceRef,
      pauri: pauri ?? this.pauri,
      endsPauri: endsPauri ?? this.endsPauri,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (baniVersionId.present) {
      map['bani_version_id'] = Variable<String>(baniVersionId.value);
    }
    if (idx.present) {
      map['idx'] = Variable<int>(idx.value);
    }
    if (sectionLabelEn.present) {
      map['section_label_en'] = Variable<String>(sectionLabelEn.value);
    }
    if (sectionLabelPa.present) {
      map['section_label_pa'] = Variable<String>(sectionLabelPa.value);
    }
    if (sectionLabelHi.present) {
      map['section_label_hi'] = Variable<String>(sectionLabelHi.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (gurmukhi.present) {
      map['gurmukhi'] = Variable<String>(gurmukhi.value);
    }
    if (devanagari.present) {
      map['devanagari'] = Variable<String>(devanagari.value);
    }
    if (roman.present) {
      map['roman'] = Variable<String>(roman.value);
    }
    if (visraamJson.present) {
      map['visraam_json'] = Variable<String>(visraamJson.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (wordAlign.present) {
      map['word_align'] = Variable<bool>(wordAlign.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<String>(sourceRef.value);
    }
    if (pauri.present) {
      map['pauri'] = Variable<int>(pauri.value);
    }
    if (endsPauri.present) {
      map['ends_pauri'] = Variable<bool>(endsPauri.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LinesCompanion(')
          ..write('id: $id, ')
          ..write('baniVersionId: $baniVersionId, ')
          ..write('idx: $idx, ')
          ..write('sectionLabelEn: $sectionLabelEn, ')
          ..write('sectionLabelPa: $sectionLabelPa, ')
          ..write('sectionLabelHi: $sectionLabelHi, ')
          ..write('kind: $kind, ')
          ..write('gurmukhi: $gurmukhi, ')
          ..write('devanagari: $devanagari, ')
          ..write('roman: $roman, ')
          ..write('visraamJson: $visraamJson, ')
          ..write('wordCount: $wordCount, ')
          ..write('wordAlign: $wordAlign, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('pauri: $pauri, ')
          ..write('endsPauri: $endsPauri')
          ..write(')'))
        .toString();
  }
}

class $MeaningsTable extends Meanings
    with TableInfo<$MeaningsTable, MeaningRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeaningsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lineIdMeta = const VerificationMeta('lineId');
  @override
  late final GeneratedColumn<int> lineId = GeneratedColumn<int>(
    'line_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAltMeta = const VerificationMeta('isAlt');
  @override
  late final GeneratedColumn<bool> isAlt = GeneratedColumn<bool>(
    'is_alt',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_alt" IN (0, 1))',
    ),
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lineId,
    lang,
    body,
    sourceId,
    isAlt,
    kind,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meaning';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeaningRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('line_id')) {
      context.handle(
        _lineIdMeta,
        lineId.isAcceptableOrUnknown(data['line_id']!, _lineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lineIdMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('is_alt')) {
      context.handle(
        _isAltMeta,
        isAlt.isAcceptableOrUnknown(data['is_alt']!, _isAltMeta),
      );
    } else if (isInserting) {
      context.missing(_isAltMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lineId, lang, isAlt};
  @override
  MeaningRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeaningRow(
      lineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      isAlt: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_alt'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $MeaningsTable createAlias(String alias) {
    return $MeaningsTable(attachedDatabase, alias);
  }
}

class MeaningRow extends DataClass implements Insertable<MeaningRow> {
  final int lineId;
  final String lang;
  final String body;
  final String? sourceId;
  final bool isAlt;
  final String kind;
  final String? note;
  const MeaningRow({
    required this.lineId,
    required this.lang,
    required this.body,
    this.sourceId,
    required this.isAlt,
    required this.kind,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['line_id'] = Variable<int>(lineId);
    map['lang'] = Variable<String>(lang);
    map['text'] = Variable<String>(body);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['is_alt'] = Variable<bool>(isAlt);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  MeaningsCompanion toCompanion(bool nullToAbsent) {
    return MeaningsCompanion(
      lineId: Value(lineId),
      lang: Value(lang),
      body: Value(body),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      isAlt: Value(isAlt),
      kind: Value(kind),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory MeaningRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeaningRow(
      lineId: serializer.fromJson<int>(json['lineId']),
      lang: serializer.fromJson<String>(json['lang']),
      body: serializer.fromJson<String>(json['body']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      isAlt: serializer.fromJson<bool>(json['isAlt']),
      kind: serializer.fromJson<String>(json['kind']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lineId': serializer.toJson<int>(lineId),
      'lang': serializer.toJson<String>(lang),
      'body': serializer.toJson<String>(body),
      'sourceId': serializer.toJson<String?>(sourceId),
      'isAlt': serializer.toJson<bool>(isAlt),
      'kind': serializer.toJson<String>(kind),
      'note': serializer.toJson<String?>(note),
    };
  }

  MeaningRow copyWith({
    int? lineId,
    String? lang,
    String? body,
    Value<String?> sourceId = const Value.absent(),
    bool? isAlt,
    String? kind,
    Value<String?> note = const Value.absent(),
  }) => MeaningRow(
    lineId: lineId ?? this.lineId,
    lang: lang ?? this.lang,
    body: body ?? this.body,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    isAlt: isAlt ?? this.isAlt,
    kind: kind ?? this.kind,
    note: note.present ? note.value : this.note,
  );
  MeaningRow copyWithCompanion(MeaningsCompanion data) {
    return MeaningRow(
      lineId: data.lineId.present ? data.lineId.value : this.lineId,
      lang: data.lang.present ? data.lang.value : this.lang,
      body: data.body.present ? data.body.value : this.body,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      isAlt: data.isAlt.present ? data.isAlt.value : this.isAlt,
      kind: data.kind.present ? data.kind.value : this.kind,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeaningRow(')
          ..write('lineId: $lineId, ')
          ..write('lang: $lang, ')
          ..write('body: $body, ')
          ..write('sourceId: $sourceId, ')
          ..write('isAlt: $isAlt, ')
          ..write('kind: $kind, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(lineId, lang, body, sourceId, isAlt, kind, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeaningRow &&
          other.lineId == this.lineId &&
          other.lang == this.lang &&
          other.body == this.body &&
          other.sourceId == this.sourceId &&
          other.isAlt == this.isAlt &&
          other.kind == this.kind &&
          other.note == this.note);
}

class MeaningsCompanion extends UpdateCompanion<MeaningRow> {
  final Value<int> lineId;
  final Value<String> lang;
  final Value<String> body;
  final Value<String?> sourceId;
  final Value<bool> isAlt;
  final Value<String> kind;
  final Value<String?> note;
  final Value<int> rowid;
  const MeaningsCompanion({
    this.lineId = const Value.absent(),
    this.lang = const Value.absent(),
    this.body = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.isAlt = const Value.absent(),
    this.kind = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeaningsCompanion.insert({
    required int lineId,
    required String lang,
    required String body,
    this.sourceId = const Value.absent(),
    required bool isAlt,
    required String kind,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lineId = Value(lineId),
       lang = Value(lang),
       body = Value(body),
       isAlt = Value(isAlt),
       kind = Value(kind);
  static Insertable<MeaningRow> custom({
    Expression<int>? lineId,
    Expression<String>? lang,
    Expression<String>? body,
    Expression<String>? sourceId,
    Expression<bool>? isAlt,
    Expression<String>? kind,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lineId != null) 'line_id': lineId,
      if (lang != null) 'lang': lang,
      if (body != null) 'text': body,
      if (sourceId != null) 'source_id': sourceId,
      if (isAlt != null) 'is_alt': isAlt,
      if (kind != null) 'kind': kind,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeaningsCompanion copyWith({
    Value<int>? lineId,
    Value<String>? lang,
    Value<String>? body,
    Value<String?>? sourceId,
    Value<bool>? isAlt,
    Value<String>? kind,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return MeaningsCompanion(
      lineId: lineId ?? this.lineId,
      lang: lang ?? this.lang,
      body: body ?? this.body,
      sourceId: sourceId ?? this.sourceId,
      isAlt: isAlt ?? this.isAlt,
      kind: kind ?? this.kind,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lineId.present) {
      map['line_id'] = Variable<int>(lineId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (isAlt.present) {
      map['is_alt'] = Variable<bool>(isAlt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeaningsCompanion(')
          ..write('lineId: $lineId, ')
          ..write('lang: $lang, ')
          ..write('body: $body, ')
          ..write('sourceId: $sourceId, ')
          ..write('isAlt: $isAlt, ')
          ..write('kind: $kind, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoicesTable extends Voices with TableInfo<$VoicesTable, VoiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creditEnMeta = const VerificationMeta(
    'creditEn',
  );
  @override
  late final GeneratedColumn<String> creditEn = GeneratedColumn<String>(
    'credit_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creditPaMeta = const VerificationMeta(
    'creditPa',
  );
  @override
  late final GeneratedColumn<String> creditPa = GeneratedColumn<String>(
    'credit_pa',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creditHiMeta = const VerificationMeta(
    'creditHi',
  );
  @override
  late final GeneratedColumn<String> creditHi = GeneratedColumn<String>(
    'credit_hi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    creditEn,
    creditPa,
    creditHi,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoiceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('credit_en')) {
      context.handle(
        _creditEnMeta,
        creditEn.isAcceptableOrUnknown(data['credit_en']!, _creditEnMeta),
      );
    }
    if (data.containsKey('credit_pa')) {
      context.handle(
        _creditPaMeta,
        creditPa.isAcceptableOrUnknown(data['credit_pa']!, _creditPaMeta),
      );
    }
    if (data.containsKey('credit_hi')) {
      context.handle(
        _creditHiMeta,
        creditHi.isAcceptableOrUnknown(data['credit_hi']!, _creditHiMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      creditEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_en'],
      ),
      creditPa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_pa'],
      ),
      creditHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_hi'],
      ),
    );
  }

  @override
  $VoicesTable createAlias(String alias) {
    return $VoicesTable(attachedDatabase, alias);
  }
}

class VoiceRow extends DataClass implements Insertable<VoiceRow> {
  final String id;
  final String? name;
  final String? creditEn;
  final String? creditPa;
  final String? creditHi;
  const VoiceRow({
    required this.id,
    this.name,
    this.creditEn,
    this.creditPa,
    this.creditHi,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || creditEn != null) {
      map['credit_en'] = Variable<String>(creditEn);
    }
    if (!nullToAbsent || creditPa != null) {
      map['credit_pa'] = Variable<String>(creditPa);
    }
    if (!nullToAbsent || creditHi != null) {
      map['credit_hi'] = Variable<String>(creditHi);
    }
    return map;
  }

  VoicesCompanion toCompanion(bool nullToAbsent) {
    return VoicesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      creditEn: creditEn == null && nullToAbsent
          ? const Value.absent()
          : Value(creditEn),
      creditPa: creditPa == null && nullToAbsent
          ? const Value.absent()
          : Value(creditPa),
      creditHi: creditHi == null && nullToAbsent
          ? const Value.absent()
          : Value(creditHi),
    );
  }

  factory VoiceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      creditEn: serializer.fromJson<String?>(json['creditEn']),
      creditPa: serializer.fromJson<String?>(json['creditPa']),
      creditHi: serializer.fromJson<String?>(json['creditHi']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'creditEn': serializer.toJson<String?>(creditEn),
      'creditPa': serializer.toJson<String?>(creditPa),
      'creditHi': serializer.toJson<String?>(creditHi),
    };
  }

  VoiceRow copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> creditEn = const Value.absent(),
    Value<String?> creditPa = const Value.absent(),
    Value<String?> creditHi = const Value.absent(),
  }) => VoiceRow(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    creditEn: creditEn.present ? creditEn.value : this.creditEn,
    creditPa: creditPa.present ? creditPa.value : this.creditPa,
    creditHi: creditHi.present ? creditHi.value : this.creditHi,
  );
  VoiceRow copyWithCompanion(VoicesCompanion data) {
    return VoiceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      creditEn: data.creditEn.present ? data.creditEn.value : this.creditEn,
      creditPa: data.creditPa.present ? data.creditPa.value : this.creditPa,
      creditHi: data.creditHi.present ? data.creditHi.value : this.creditHi,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('creditEn: $creditEn, ')
          ..write('creditPa: $creditPa, ')
          ..write('creditHi: $creditHi')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, creditEn, creditPa, creditHi);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.creditEn == this.creditEn &&
          other.creditPa == this.creditPa &&
          other.creditHi == this.creditHi);
}

class VoicesCompanion extends UpdateCompanion<VoiceRow> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> creditEn;
  final Value<String?> creditPa;
  final Value<String?> creditHi;
  final Value<int> rowid;
  const VoicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.creditEn = const Value.absent(),
    this.creditPa = const Value.absent(),
    this.creditHi = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoicesCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.creditEn = const Value.absent(),
    this.creditPa = const Value.absent(),
    this.creditHi = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<VoiceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? creditEn,
    Expression<String>? creditPa,
    Expression<String>? creditHi,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (creditEn != null) 'credit_en': creditEn,
      if (creditPa != null) 'credit_pa': creditPa,
      if (creditHi != null) 'credit_hi': creditHi,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoicesCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? creditEn,
    Value<String?>? creditPa,
    Value<String?>? creditHi,
    Value<int>? rowid,
  }) {
    return VoicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      creditEn: creditEn ?? this.creditEn,
      creditPa: creditPa ?? this.creditPa,
      creditHi: creditHi ?? this.creditHi,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (creditEn.present) {
      map['credit_en'] = Variable<String>(creditEn.value);
    }
    if (creditPa.present) {
      map['credit_pa'] = Variable<String>(creditPa.value);
    }
    if (creditHi.present) {
      map['credit_hi'] = Variable<String>(creditHi.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoicesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('creditEn: $creditEn, ')
          ..write('creditPa: $creditPa, ')
          ..write('creditHi: $creditHi, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudioTracksTable extends AudioTracks
    with TableInfo<$AudioTracksTable, AudioTrackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _voiceIdMeta = const VerificationMeta(
    'voiceId',
  );
  @override
  late final GeneratedColumn<String> voiceId = GeneratedColumn<String>(
    'voice_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packMeta = const VerificationMeta('pack');
  @override
  late final GeneratedColumn<String> pack = GeneratedColumn<String>(
    'pack',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileMeta = const VerificationMeta('file');
  @override
  late final GeneratedColumn<String> file = GeneratedColumn<String>(
    'file',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    baniVersionId,
    voiceId,
    pack,
    file,
    durationMs,
    bytes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_track';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioTrackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
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
    if (data.containsKey('voice_id')) {
      context.handle(
        _voiceIdMeta,
        voiceId.isAcceptableOrUnknown(data['voice_id']!, _voiceIdMeta),
      );
    }
    if (data.containsKey('pack')) {
      context.handle(
        _packMeta,
        pack.isAcceptableOrUnknown(data['pack']!, _packMeta),
      );
    } else if (isInserting) {
      context.missing(_packMeta);
    }
    if (data.containsKey('file')) {
      context.handle(
        _fileMeta,
        file.isAcceptableOrUnknown(data['file']!, _fileMeta),
      );
    } else if (isInserting) {
      context.missing(_fileMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioTrackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioTrackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      baniVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bani_version_id'],
      )!,
      voiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_id'],
      ),
      pack: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack'],
      )!,
      file: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      ),
    );
  }

  @override
  $AudioTracksTable createAlias(String alias) {
    return $AudioTracksTable(attachedDatabase, alias);
  }
}

class AudioTrackRow extends DataClass implements Insertable<AudioTrackRow> {
  final String id;
  final String baniVersionId;
  final String? voiceId;
  final String pack;
  final String file;
  final int? durationMs;
  final int? bytes;
  const AudioTrackRow({
    required this.id,
    required this.baniVersionId,
    this.voiceId,
    required this.pack,
    required this.file,
    this.durationMs,
    this.bytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bani_version_id'] = Variable<String>(baniVersionId);
    if (!nullToAbsent || voiceId != null) {
      map['voice_id'] = Variable<String>(voiceId);
    }
    map['pack'] = Variable<String>(pack);
    map['file'] = Variable<String>(file);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || bytes != null) {
      map['bytes'] = Variable<int>(bytes);
    }
    return map;
  }

  AudioTracksCompanion toCompanion(bool nullToAbsent) {
    return AudioTracksCompanion(
      id: Value(id),
      baniVersionId: Value(baniVersionId),
      voiceId: voiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceId),
      pack: Value(pack),
      file: Value(file),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      bytes: bytes == null && nullToAbsent
          ? const Value.absent()
          : Value(bytes),
    );
  }

  factory AudioTrackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioTrackRow(
      id: serializer.fromJson<String>(json['id']),
      baniVersionId: serializer.fromJson<String>(json['baniVersionId']),
      voiceId: serializer.fromJson<String?>(json['voiceId']),
      pack: serializer.fromJson<String>(json['pack']),
      file: serializer.fromJson<String>(json['file']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      bytes: serializer.fromJson<int?>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'baniVersionId': serializer.toJson<String>(baniVersionId),
      'voiceId': serializer.toJson<String?>(voiceId),
      'pack': serializer.toJson<String>(pack),
      'file': serializer.toJson<String>(file),
      'durationMs': serializer.toJson<int?>(durationMs),
      'bytes': serializer.toJson<int?>(bytes),
    };
  }

  AudioTrackRow copyWith({
    String? id,
    String? baniVersionId,
    Value<String?> voiceId = const Value.absent(),
    String? pack,
    String? file,
    Value<int?> durationMs = const Value.absent(),
    Value<int?> bytes = const Value.absent(),
  }) => AudioTrackRow(
    id: id ?? this.id,
    baniVersionId: baniVersionId ?? this.baniVersionId,
    voiceId: voiceId.present ? voiceId.value : this.voiceId,
    pack: pack ?? this.pack,
    file: file ?? this.file,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    bytes: bytes.present ? bytes.value : this.bytes,
  );
  AudioTrackRow copyWithCompanion(AudioTracksCompanion data) {
    return AudioTrackRow(
      id: data.id.present ? data.id.value : this.id,
      baniVersionId: data.baniVersionId.present
          ? data.baniVersionId.value
          : this.baniVersionId,
      voiceId: data.voiceId.present ? data.voiceId.value : this.voiceId,
      pack: data.pack.present ? data.pack.value : this.pack,
      file: data.file.present ? data.file.value : this.file,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioTrackRow(')
          ..write('id: $id, ')
          ..write('baniVersionId: $baniVersionId, ')
          ..write('voiceId: $voiceId, ')
          ..write('pack: $pack, ')
          ..write('file: $file, ')
          ..write('durationMs: $durationMs, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, baniVersionId, voiceId, pack, file, durationMs, bytes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioTrackRow &&
          other.id == this.id &&
          other.baniVersionId == this.baniVersionId &&
          other.voiceId == this.voiceId &&
          other.pack == this.pack &&
          other.file == this.file &&
          other.durationMs == this.durationMs &&
          other.bytes == this.bytes);
}

class AudioTracksCompanion extends UpdateCompanion<AudioTrackRow> {
  final Value<String> id;
  final Value<String> baniVersionId;
  final Value<String?> voiceId;
  final Value<String> pack;
  final Value<String> file;
  final Value<int?> durationMs;
  final Value<int?> bytes;
  final Value<int> rowid;
  const AudioTracksCompanion({
    this.id = const Value.absent(),
    this.baniVersionId = const Value.absent(),
    this.voiceId = const Value.absent(),
    this.pack = const Value.absent(),
    this.file = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.bytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioTracksCompanion.insert({
    required String id,
    required String baniVersionId,
    this.voiceId = const Value.absent(),
    required String pack,
    required String file,
    this.durationMs = const Value.absent(),
    this.bytes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       baniVersionId = Value(baniVersionId),
       pack = Value(pack),
       file = Value(file);
  static Insertable<AudioTrackRow> custom({
    Expression<String>? id,
    Expression<String>? baniVersionId,
    Expression<String>? voiceId,
    Expression<String>? pack,
    Expression<String>? file,
    Expression<int>? durationMs,
    Expression<int>? bytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baniVersionId != null) 'bani_version_id': baniVersionId,
      if (voiceId != null) 'voice_id': voiceId,
      if (pack != null) 'pack': pack,
      if (file != null) 'file': file,
      if (durationMs != null) 'duration_ms': durationMs,
      if (bytes != null) 'bytes': bytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioTracksCompanion copyWith({
    Value<String>? id,
    Value<String>? baniVersionId,
    Value<String?>? voiceId,
    Value<String>? pack,
    Value<String>? file,
    Value<int?>? durationMs,
    Value<int?>? bytes,
    Value<int>? rowid,
  }) {
    return AudioTracksCompanion(
      id: id ?? this.id,
      baniVersionId: baniVersionId ?? this.baniVersionId,
      voiceId: voiceId ?? this.voiceId,
      pack: pack ?? this.pack,
      file: file ?? this.file,
      durationMs: durationMs ?? this.durationMs,
      bytes: bytes ?? this.bytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (baniVersionId.present) {
      map['bani_version_id'] = Variable<String>(baniVersionId.value);
    }
    if (voiceId.present) {
      map['voice_id'] = Variable<String>(voiceId.value);
    }
    if (pack.present) {
      map['pack'] = Variable<String>(pack.value);
    }
    if (file.present) {
      map['file'] = Variable<String>(file.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioTracksCompanion(')
          ..write('id: $id, ')
          ..write('baniVersionId: $baniVersionId, ')
          ..write('voiceId: $voiceId, ')
          ..write('pack: $pack, ')
          ..write('file: $file, ')
          ..write('durationMs: $durationMs, ')
          ..write('bytes: $bytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimingsTable extends Timings with TableInfo<$TimingsTable, TimingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _audioTrackIdMeta = const VerificationMeta(
    'audioTrackId',
  );
  @override
  late final GeneratedColumn<String> audioTrackId = GeneratedColumn<String>(
    'audio_track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [audioTrackId, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timing';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('audio_track_id')) {
      context.handle(
        _audioTrackIdMeta,
        audioTrackId.isAcceptableOrUnknown(
          data['audio_track_id']!,
          _audioTrackIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_audioTrackIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {audioTrackId};
  @override
  TimingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimingRow(
      audioTrackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_track_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $TimingsTable createAlias(String alias) {
    return $TimingsTable(attachedDatabase, alias);
  }
}

class TimingRow extends DataClass implements Insertable<TimingRow> {
  final String audioTrackId;
  final String json;
  const TimingRow({required this.audioTrackId, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['audio_track_id'] = Variable<String>(audioTrackId);
    map['json'] = Variable<String>(json);
    return map;
  }

  TimingsCompanion toCompanion(bool nullToAbsent) {
    return TimingsCompanion(
      audioTrackId: Value(audioTrackId),
      json: Value(json),
    );
  }

  factory TimingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimingRow(
      audioTrackId: serializer.fromJson<String>(json['audioTrackId']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'audioTrackId': serializer.toJson<String>(audioTrackId),
      'json': serializer.toJson<String>(json),
    };
  }

  TimingRow copyWith({String? audioTrackId, String? json}) => TimingRow(
    audioTrackId: audioTrackId ?? this.audioTrackId,
    json: json ?? this.json,
  );
  TimingRow copyWithCompanion(TimingsCompanion data) {
    return TimingRow(
      audioTrackId: data.audioTrackId.present
          ? data.audioTrackId.value
          : this.audioTrackId,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimingRow(')
          ..write('audioTrackId: $audioTrackId, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(audioTrackId, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimingRow &&
          other.audioTrackId == this.audioTrackId &&
          other.json == this.json);
}

class TimingsCompanion extends UpdateCompanion<TimingRow> {
  final Value<String> audioTrackId;
  final Value<String> json;
  final Value<int> rowid;
  const TimingsCompanion({
    this.audioTrackId = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimingsCompanion.insert({
    required String audioTrackId,
    required String json,
    this.rowid = const Value.absent(),
  }) : audioTrackId = Value(audioTrackId),
       json = Value(json);
  static Insertable<TimingRow> custom({
    Expression<String>? audioTrackId,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (audioTrackId != null) 'audio_track_id': audioTrackId,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimingsCompanion copyWith({
    Value<String>? audioTrackId,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return TimingsCompanion(
      audioTrackId: audioTrackId ?? this.audioTrackId,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (audioTrackId.present) {
      map['audio_track_id'] = Variable<String>(audioTrackId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimingsCompanion(')
          ..write('audioTrackId: $audioTrackId, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NanakshahiMonthsTable extends NanakshahiMonths
    with TableInfo<$NanakshahiMonthsTable, NanakshahiMonthRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NanakshahiMonthsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nsYearMeta = const VerificationMeta('nsYear');
  @override
  late final GeneratedColumn<int> nsYear = GeneratedColumn<int>(
    'ns_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idxMeta = const VerificationMeta('idx');
  @override
  late final GeneratedColumn<int> idx = GeneratedColumn<int>(
    'idx',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namePaMeta = const VerificationMeta('namePa');
  @override
  late final GeneratedColumn<String> namePa = GeneratedColumn<String>(
    'name_pa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameHiMeta = const VerificationMeta('nameHi');
  @override
  late final GeneratedColumn<String> nameHi = GeneratedColumn<String>(
    'name_hi',
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
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<int> days = GeneratedColumn<int>(
    'days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    nsYear,
    idx,
    nameEn,
    namePa,
    nameHi,
    startDate,
    days,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nanakshahi_month';
  @override
  VerificationContext validateIntegrity(
    Insertable<NanakshahiMonthRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ns_year')) {
      context.handle(
        _nsYearMeta,
        nsYear.isAcceptableOrUnknown(data['ns_year']!, _nsYearMeta),
      );
    } else if (isInserting) {
      context.missing(_nsYearMeta);
    }
    if (data.containsKey('idx')) {
      context.handle(
        _idxMeta,
        idx.isAcceptableOrUnknown(data['idx']!, _idxMeta),
      );
    } else if (isInserting) {
      context.missing(_idxMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_pa')) {
      context.handle(
        _namePaMeta,
        namePa.isAcceptableOrUnknown(data['name_pa']!, _namePaMeta),
      );
    } else if (isInserting) {
      context.missing(_namePaMeta);
    }
    if (data.containsKey('name_hi')) {
      context.handle(
        _nameHiMeta,
        nameHi.isAcceptableOrUnknown(data['name_hi']!, _nameHiMeta),
      );
    } else if (isInserting) {
      context.missing(_nameHiMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('days')) {
      context.handle(
        _daysMeta,
        days.isAcceptableOrUnknown(data['days']!, _daysMeta),
      );
    } else if (isInserting) {
      context.missing(_daysMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nsYear, idx};
  @override
  NanakshahiMonthRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NanakshahiMonthRow(
      nsYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ns_year'],
      )!,
      idx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}idx'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      namePa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_pa'],
      )!,
      nameHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_hi'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      days: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days'],
      )!,
    );
  }

  @override
  $NanakshahiMonthsTable createAlias(String alias) {
    return $NanakshahiMonthsTable(attachedDatabase, alias);
  }
}

class NanakshahiMonthRow extends DataClass
    implements Insertable<NanakshahiMonthRow> {
  final int nsYear;
  final int idx;
  final String nameEn;
  final String namePa;
  final String nameHi;
  final String startDate;
  final int days;
  const NanakshahiMonthRow({
    required this.nsYear,
    required this.idx,
    required this.nameEn,
    required this.namePa,
    required this.nameHi,
    required this.startDate,
    required this.days,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ns_year'] = Variable<int>(nsYear);
    map['idx'] = Variable<int>(idx);
    map['name_en'] = Variable<String>(nameEn);
    map['name_pa'] = Variable<String>(namePa);
    map['name_hi'] = Variable<String>(nameHi);
    map['start_date'] = Variable<String>(startDate);
    map['days'] = Variable<int>(days);
    return map;
  }

  NanakshahiMonthsCompanion toCompanion(bool nullToAbsent) {
    return NanakshahiMonthsCompanion(
      nsYear: Value(nsYear),
      idx: Value(idx),
      nameEn: Value(nameEn),
      namePa: Value(namePa),
      nameHi: Value(nameHi),
      startDate: Value(startDate),
      days: Value(days),
    );
  }

  factory NanakshahiMonthRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NanakshahiMonthRow(
      nsYear: serializer.fromJson<int>(json['nsYear']),
      idx: serializer.fromJson<int>(json['idx']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      namePa: serializer.fromJson<String>(json['namePa']),
      nameHi: serializer.fromJson<String>(json['nameHi']),
      startDate: serializer.fromJson<String>(json['startDate']),
      days: serializer.fromJson<int>(json['days']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nsYear': serializer.toJson<int>(nsYear),
      'idx': serializer.toJson<int>(idx),
      'nameEn': serializer.toJson<String>(nameEn),
      'namePa': serializer.toJson<String>(namePa),
      'nameHi': serializer.toJson<String>(nameHi),
      'startDate': serializer.toJson<String>(startDate),
      'days': serializer.toJson<int>(days),
    };
  }

  NanakshahiMonthRow copyWith({
    int? nsYear,
    int? idx,
    String? nameEn,
    String? namePa,
    String? nameHi,
    String? startDate,
    int? days,
  }) => NanakshahiMonthRow(
    nsYear: nsYear ?? this.nsYear,
    idx: idx ?? this.idx,
    nameEn: nameEn ?? this.nameEn,
    namePa: namePa ?? this.namePa,
    nameHi: nameHi ?? this.nameHi,
    startDate: startDate ?? this.startDate,
    days: days ?? this.days,
  );
  NanakshahiMonthRow copyWithCompanion(NanakshahiMonthsCompanion data) {
    return NanakshahiMonthRow(
      nsYear: data.nsYear.present ? data.nsYear.value : this.nsYear,
      idx: data.idx.present ? data.idx.value : this.idx,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      namePa: data.namePa.present ? data.namePa.value : this.namePa,
      nameHi: data.nameHi.present ? data.nameHi.value : this.nameHi,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      days: data.days.present ? data.days.value : this.days,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NanakshahiMonthRow(')
          ..write('nsYear: $nsYear, ')
          ..write('idx: $idx, ')
          ..write('nameEn: $nameEn, ')
          ..write('namePa: $namePa, ')
          ..write('nameHi: $nameHi, ')
          ..write('startDate: $startDate, ')
          ..write('days: $days')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(nsYear, idx, nameEn, namePa, nameHi, startDate, days);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NanakshahiMonthRow &&
          other.nsYear == this.nsYear &&
          other.idx == this.idx &&
          other.nameEn == this.nameEn &&
          other.namePa == this.namePa &&
          other.nameHi == this.nameHi &&
          other.startDate == this.startDate &&
          other.days == this.days);
}

class NanakshahiMonthsCompanion extends UpdateCompanion<NanakshahiMonthRow> {
  final Value<int> nsYear;
  final Value<int> idx;
  final Value<String> nameEn;
  final Value<String> namePa;
  final Value<String> nameHi;
  final Value<String> startDate;
  final Value<int> days;
  final Value<int> rowid;
  const NanakshahiMonthsCompanion({
    this.nsYear = const Value.absent(),
    this.idx = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.namePa = const Value.absent(),
    this.nameHi = const Value.absent(),
    this.startDate = const Value.absent(),
    this.days = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NanakshahiMonthsCompanion.insert({
    required int nsYear,
    required int idx,
    required String nameEn,
    required String namePa,
    required String nameHi,
    required String startDate,
    required int days,
    this.rowid = const Value.absent(),
  }) : nsYear = Value(nsYear),
       idx = Value(idx),
       nameEn = Value(nameEn),
       namePa = Value(namePa),
       nameHi = Value(nameHi),
       startDate = Value(startDate),
       days = Value(days);
  static Insertable<NanakshahiMonthRow> custom({
    Expression<int>? nsYear,
    Expression<int>? idx,
    Expression<String>? nameEn,
    Expression<String>? namePa,
    Expression<String>? nameHi,
    Expression<String>? startDate,
    Expression<int>? days,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nsYear != null) 'ns_year': nsYear,
      if (idx != null) 'idx': idx,
      if (nameEn != null) 'name_en': nameEn,
      if (namePa != null) 'name_pa': namePa,
      if (nameHi != null) 'name_hi': nameHi,
      if (startDate != null) 'start_date': startDate,
      if (days != null) 'days': days,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NanakshahiMonthsCompanion copyWith({
    Value<int>? nsYear,
    Value<int>? idx,
    Value<String>? nameEn,
    Value<String>? namePa,
    Value<String>? nameHi,
    Value<String>? startDate,
    Value<int>? days,
    Value<int>? rowid,
  }) {
    return NanakshahiMonthsCompanion(
      nsYear: nsYear ?? this.nsYear,
      idx: idx ?? this.idx,
      nameEn: nameEn ?? this.nameEn,
      namePa: namePa ?? this.namePa,
      nameHi: nameHi ?? this.nameHi,
      startDate: startDate ?? this.startDate,
      days: days ?? this.days,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nsYear.present) {
      map['ns_year'] = Variable<int>(nsYear.value);
    }
    if (idx.present) {
      map['idx'] = Variable<int>(idx.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (namePa.present) {
      map['name_pa'] = Variable<String>(namePa.value);
    }
    if (nameHi.present) {
      map['name_hi'] = Variable<String>(nameHi.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (days.present) {
      map['days'] = Variable<int>(days.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NanakshahiMonthsCompanion(')
          ..write('nsYear: $nsYear, ')
          ..write('idx: $idx, ')
          ..write('nameEn: $nameEn, ')
          ..write('namePa: $namePa, ')
          ..write('nameHi: $nameHi, ')
          ..write('startDate: $startDate, ')
          ..write('days: $days, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarEventsTable extends CalendarEvents
    with TableInfo<$CalendarEventsTable, CalendarEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nsYearMeta = const VerificationMeta('nsYear');
  @override
  late final GeneratedColumn<int> nsYear = GeneratedColumn<int>(
    'ns_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
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
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namePaMeta = const VerificationMeta('namePa');
  @override
  late final GeneratedColumn<String> namePa = GeneratedColumn<String>(
    'name_pa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameHiMeta = const VerificationMeta('nameHi');
  @override
  late final GeneratedColumn<String> nameHi = GeneratedColumn<String>(
    'name_hi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nsLabelMeta = const VerificationMeta(
    'nsLabel',
  );
  @override
  late final GeneratedColumn<String> nsLabel = GeneratedColumn<String>(
    'ns_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultRemindMeta = const VerificationMeta(
    'defaultRemind',
  );
  @override
  late final GeneratedColumn<bool> defaultRemind = GeneratedColumn<bool>(
    'default_remind',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("default_remind" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nsYear,
    date,
    kind,
    nameEn,
    namePa,
    nameHi,
    nsLabel,
    defaultRemind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_event';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ns_year')) {
      context.handle(
        _nsYearMeta,
        nsYear.isAcceptableOrUnknown(data['ns_year']!, _nsYearMeta),
      );
    } else if (isInserting) {
      context.missing(_nsYearMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_pa')) {
      context.handle(
        _namePaMeta,
        namePa.isAcceptableOrUnknown(data['name_pa']!, _namePaMeta),
      );
    } else if (isInserting) {
      context.missing(_namePaMeta);
    }
    if (data.containsKey('name_hi')) {
      context.handle(
        _nameHiMeta,
        nameHi.isAcceptableOrUnknown(data['name_hi']!, _nameHiMeta),
      );
    } else if (isInserting) {
      context.missing(_nameHiMeta);
    }
    if (data.containsKey('ns_label')) {
      context.handle(
        _nsLabelMeta,
        nsLabel.isAcceptableOrUnknown(data['ns_label']!, _nsLabelMeta),
      );
    }
    if (data.containsKey('default_remind')) {
      context.handle(
        _defaultRemindMeta,
        defaultRemind.isAcceptableOrUnknown(
          data['default_remind']!,
          _defaultRemindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultRemindMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nsYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ns_year'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      namePa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_pa'],
      )!,
      nameHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_hi'],
      )!,
      nsLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ns_label'],
      ),
      defaultRemind: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}default_remind'],
      )!,
    );
  }

  @override
  $CalendarEventsTable createAlias(String alias) {
    return $CalendarEventsTable(attachedDatabase, alias);
  }
}

class CalendarEventRow extends DataClass
    implements Insertable<CalendarEventRow> {
  final String id;
  final int nsYear;
  final String date;
  final String kind;
  final String nameEn;
  final String namePa;
  final String nameHi;
  final String? nsLabel;
  final bool defaultRemind;
  const CalendarEventRow({
    required this.id,
    required this.nsYear,
    required this.date,
    required this.kind,
    required this.nameEn,
    required this.namePa,
    required this.nameHi,
    this.nsLabel,
    required this.defaultRemind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ns_year'] = Variable<int>(nsYear);
    map['date'] = Variable<String>(date);
    map['kind'] = Variable<String>(kind);
    map['name_en'] = Variable<String>(nameEn);
    map['name_pa'] = Variable<String>(namePa);
    map['name_hi'] = Variable<String>(nameHi);
    if (!nullToAbsent || nsLabel != null) {
      map['ns_label'] = Variable<String>(nsLabel);
    }
    map['default_remind'] = Variable<bool>(defaultRemind);
    return map;
  }

  CalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return CalendarEventsCompanion(
      id: Value(id),
      nsYear: Value(nsYear),
      date: Value(date),
      kind: Value(kind),
      nameEn: Value(nameEn),
      namePa: Value(namePa),
      nameHi: Value(nameHi),
      nsLabel: nsLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(nsLabel),
      defaultRemind: Value(defaultRemind),
    );
  }

  factory CalendarEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEventRow(
      id: serializer.fromJson<String>(json['id']),
      nsYear: serializer.fromJson<int>(json['nsYear']),
      date: serializer.fromJson<String>(json['date']),
      kind: serializer.fromJson<String>(json['kind']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      namePa: serializer.fromJson<String>(json['namePa']),
      nameHi: serializer.fromJson<String>(json['nameHi']),
      nsLabel: serializer.fromJson<String?>(json['nsLabel']),
      defaultRemind: serializer.fromJson<bool>(json['defaultRemind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nsYear': serializer.toJson<int>(nsYear),
      'date': serializer.toJson<String>(date),
      'kind': serializer.toJson<String>(kind),
      'nameEn': serializer.toJson<String>(nameEn),
      'namePa': serializer.toJson<String>(namePa),
      'nameHi': serializer.toJson<String>(nameHi),
      'nsLabel': serializer.toJson<String?>(nsLabel),
      'defaultRemind': serializer.toJson<bool>(defaultRemind),
    };
  }

  CalendarEventRow copyWith({
    String? id,
    int? nsYear,
    String? date,
    String? kind,
    String? nameEn,
    String? namePa,
    String? nameHi,
    Value<String?> nsLabel = const Value.absent(),
    bool? defaultRemind,
  }) => CalendarEventRow(
    id: id ?? this.id,
    nsYear: nsYear ?? this.nsYear,
    date: date ?? this.date,
    kind: kind ?? this.kind,
    nameEn: nameEn ?? this.nameEn,
    namePa: namePa ?? this.namePa,
    nameHi: nameHi ?? this.nameHi,
    nsLabel: nsLabel.present ? nsLabel.value : this.nsLabel,
    defaultRemind: defaultRemind ?? this.defaultRemind,
  );
  CalendarEventRow copyWithCompanion(CalendarEventsCompanion data) {
    return CalendarEventRow(
      id: data.id.present ? data.id.value : this.id,
      nsYear: data.nsYear.present ? data.nsYear.value : this.nsYear,
      date: data.date.present ? data.date.value : this.date,
      kind: data.kind.present ? data.kind.value : this.kind,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      namePa: data.namePa.present ? data.namePa.value : this.namePa,
      nameHi: data.nameHi.present ? data.nameHi.value : this.nameHi,
      nsLabel: data.nsLabel.present ? data.nsLabel.value : this.nsLabel,
      defaultRemind: data.defaultRemind.present
          ? data.defaultRemind.value
          : this.defaultRemind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventRow(')
          ..write('id: $id, ')
          ..write('nsYear: $nsYear, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('nameEn: $nameEn, ')
          ..write('namePa: $namePa, ')
          ..write('nameHi: $nameHi, ')
          ..write('nsLabel: $nsLabel, ')
          ..write('defaultRemind: $defaultRemind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nsYear,
    date,
    kind,
    nameEn,
    namePa,
    nameHi,
    nsLabel,
    defaultRemind,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEventRow &&
          other.id == this.id &&
          other.nsYear == this.nsYear &&
          other.date == this.date &&
          other.kind == this.kind &&
          other.nameEn == this.nameEn &&
          other.namePa == this.namePa &&
          other.nameHi == this.nameHi &&
          other.nsLabel == this.nsLabel &&
          other.defaultRemind == this.defaultRemind);
}

class CalendarEventsCompanion extends UpdateCompanion<CalendarEventRow> {
  final Value<String> id;
  final Value<int> nsYear;
  final Value<String> date;
  final Value<String> kind;
  final Value<String> nameEn;
  final Value<String> namePa;
  final Value<String> nameHi;
  final Value<String?> nsLabel;
  final Value<bool> defaultRemind;
  final Value<int> rowid;
  const CalendarEventsCompanion({
    this.id = const Value.absent(),
    this.nsYear = const Value.absent(),
    this.date = const Value.absent(),
    this.kind = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.namePa = const Value.absent(),
    this.nameHi = const Value.absent(),
    this.nsLabel = const Value.absent(),
    this.defaultRemind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarEventsCompanion.insert({
    required String id,
    required int nsYear,
    required String date,
    required String kind,
    required String nameEn,
    required String namePa,
    required String nameHi,
    this.nsLabel = const Value.absent(),
    required bool defaultRemind,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nsYear = Value(nsYear),
       date = Value(date),
       kind = Value(kind),
       nameEn = Value(nameEn),
       namePa = Value(namePa),
       nameHi = Value(nameHi),
       defaultRemind = Value(defaultRemind);
  static Insertable<CalendarEventRow> custom({
    Expression<String>? id,
    Expression<int>? nsYear,
    Expression<String>? date,
    Expression<String>? kind,
    Expression<String>? nameEn,
    Expression<String>? namePa,
    Expression<String>? nameHi,
    Expression<String>? nsLabel,
    Expression<bool>? defaultRemind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nsYear != null) 'ns_year': nsYear,
      if (date != null) 'date': date,
      if (kind != null) 'kind': kind,
      if (nameEn != null) 'name_en': nameEn,
      if (namePa != null) 'name_pa': namePa,
      if (nameHi != null) 'name_hi': nameHi,
      if (nsLabel != null) 'ns_label': nsLabel,
      if (defaultRemind != null) 'default_remind': defaultRemind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarEventsCompanion copyWith({
    Value<String>? id,
    Value<int>? nsYear,
    Value<String>? date,
    Value<String>? kind,
    Value<String>? nameEn,
    Value<String>? namePa,
    Value<String>? nameHi,
    Value<String?>? nsLabel,
    Value<bool>? defaultRemind,
    Value<int>? rowid,
  }) {
    return CalendarEventsCompanion(
      id: id ?? this.id,
      nsYear: nsYear ?? this.nsYear,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      nameEn: nameEn ?? this.nameEn,
      namePa: namePa ?? this.namePa,
      nameHi: nameHi ?? this.nameHi,
      nsLabel: nsLabel ?? this.nsLabel,
      defaultRemind: defaultRemind ?? this.defaultRemind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nsYear.present) {
      map['ns_year'] = Variable<int>(nsYear.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (namePa.present) {
      map['name_pa'] = Variable<String>(namePa.value);
    }
    if (nameHi.present) {
      map['name_hi'] = Variable<String>(nameHi.value);
    }
    if (nsLabel.present) {
      map['ns_label'] = Variable<String>(nsLabel.value);
    }
    if (defaultRemind.present) {
      map['default_remind'] = Variable<bool>(defaultRemind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('nsYear: $nsYear, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('nameEn: $nameEn, ')
          ..write('namePa: $namePa, ')
          ..write('nameHi: $nameHi, ')
          ..write('nsLabel: $nsLabel, ')
          ..write('defaultRemind: $defaultRemind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CitiesTable extends Cities with TableInfo<$CitiesTable, CityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namePaMeta = const VerificationMeta('namePa');
  @override
  late final GeneratedColumn<String> namePa = GeneratedColumn<String>(
    'name_pa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameHiMeta = const VerificationMeta('nameHi');
  @override
  late final GeneratedColumn<String> nameHi = GeneratedColumn<String>(
    'name_hi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryCodeMeta = const VerificationMeta(
    'countryCode',
  );
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzMeta = const VerificationMeta('tz');
  @override
  late final GeneratedColumn<String> tz = GeneratedColumn<String>(
    'tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameEn,
    namePa,
    nameHi,
    countryCode,
    lat,
    lon,
    tz,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'city';
  @override
  VerificationContext validateIntegrity(
    Insertable<CityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_pa')) {
      context.handle(
        _namePaMeta,
        namePa.isAcceptableOrUnknown(data['name_pa']!, _namePaMeta),
      );
    } else if (isInserting) {
      context.missing(_namePaMeta);
    }
    if (data.containsKey('name_hi')) {
      context.handle(
        _nameHiMeta,
        nameHi.isAcceptableOrUnknown(data['name_hi']!, _nameHiMeta),
      );
    } else if (isInserting) {
      context.missing(_nameHiMeta);
    }
    if (data.containsKey('country_code')) {
      context.handle(
        _countryCodeMeta,
        countryCode.isAcceptableOrUnknown(
          data['country_code']!,
          _countryCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countryCodeMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('tz')) {
      context.handle(_tzMeta, tz.isAcceptableOrUnknown(data['tz']!, _tzMeta));
    } else if (isInserting) {
      context.missing(_tzMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      namePa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_pa'],
      )!,
      nameHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_hi'],
      )!,
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      tz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tz'],
      )!,
    );
  }

  @override
  $CitiesTable createAlias(String alias) {
    return $CitiesTable(attachedDatabase, alias);
  }
}

class CityRow extends DataClass implements Insertable<CityRow> {
  final String id;
  final String nameEn;
  final String namePa;
  final String nameHi;
  final String countryCode;
  final double lat;
  final double lon;
  final String tz;
  const CityRow({
    required this.id,
    required this.nameEn,
    required this.namePa,
    required this.nameHi,
    required this.countryCode,
    required this.lat,
    required this.lon,
    required this.tz,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name_en'] = Variable<String>(nameEn);
    map['name_pa'] = Variable<String>(namePa);
    map['name_hi'] = Variable<String>(nameHi);
    map['country_code'] = Variable<String>(countryCode);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['tz'] = Variable<String>(tz);
    return map;
  }

  CitiesCompanion toCompanion(bool nullToAbsent) {
    return CitiesCompanion(
      id: Value(id),
      nameEn: Value(nameEn),
      namePa: Value(namePa),
      nameHi: Value(nameHi),
      countryCode: Value(countryCode),
      lat: Value(lat),
      lon: Value(lon),
      tz: Value(tz),
    );
  }

  factory CityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CityRow(
      id: serializer.fromJson<String>(json['id']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      namePa: serializer.fromJson<String>(json['namePa']),
      nameHi: serializer.fromJson<String>(json['nameHi']),
      countryCode: serializer.fromJson<String>(json['countryCode']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      tz: serializer.fromJson<String>(json['tz']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nameEn': serializer.toJson<String>(nameEn),
      'namePa': serializer.toJson<String>(namePa),
      'nameHi': serializer.toJson<String>(nameHi),
      'countryCode': serializer.toJson<String>(countryCode),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'tz': serializer.toJson<String>(tz),
    };
  }

  CityRow copyWith({
    String? id,
    String? nameEn,
    String? namePa,
    String? nameHi,
    String? countryCode,
    double? lat,
    double? lon,
    String? tz,
  }) => CityRow(
    id: id ?? this.id,
    nameEn: nameEn ?? this.nameEn,
    namePa: namePa ?? this.namePa,
    nameHi: nameHi ?? this.nameHi,
    countryCode: countryCode ?? this.countryCode,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    tz: tz ?? this.tz,
  );
  CityRow copyWithCompanion(CitiesCompanion data) {
    return CityRow(
      id: data.id.present ? data.id.value : this.id,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      namePa: data.namePa.present ? data.namePa.value : this.namePa,
      nameHi: data.nameHi.present ? data.nameHi.value : this.nameHi,
      countryCode: data.countryCode.present
          ? data.countryCode.value
          : this.countryCode,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      tz: data.tz.present ? data.tz.value : this.tz,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CityRow(')
          ..write('id: $id, ')
          ..write('nameEn: $nameEn, ')
          ..write('namePa: $namePa, ')
          ..write('nameHi: $nameHi, ')
          ..write('countryCode: $countryCode, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('tz: $tz')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nameEn, namePa, nameHi, countryCode, lat, lon, tz);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CityRow &&
          other.id == this.id &&
          other.nameEn == this.nameEn &&
          other.namePa == this.namePa &&
          other.nameHi == this.nameHi &&
          other.countryCode == this.countryCode &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.tz == this.tz);
}

class CitiesCompanion extends UpdateCompanion<CityRow> {
  final Value<String> id;
  final Value<String> nameEn;
  final Value<String> namePa;
  final Value<String> nameHi;
  final Value<String> countryCode;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String> tz;
  final Value<int> rowid;
  const CitiesCompanion({
    this.id = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.namePa = const Value.absent(),
    this.nameHi = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.tz = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CitiesCompanion.insert({
    required String id,
    required String nameEn,
    required String namePa,
    required String nameHi,
    required String countryCode,
    required double lat,
    required double lon,
    required String tz,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nameEn = Value(nameEn),
       namePa = Value(namePa),
       nameHi = Value(nameHi),
       countryCode = Value(countryCode),
       lat = Value(lat),
       lon = Value(lon),
       tz = Value(tz);
  static Insertable<CityRow> custom({
    Expression<String>? id,
    Expression<String>? nameEn,
    Expression<String>? namePa,
    Expression<String>? nameHi,
    Expression<String>? countryCode,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? tz,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameEn != null) 'name_en': nameEn,
      if (namePa != null) 'name_pa': namePa,
      if (nameHi != null) 'name_hi': nameHi,
      if (countryCode != null) 'country_code': countryCode,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (tz != null) 'tz': tz,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? nameEn,
    Value<String>? namePa,
    Value<String>? nameHi,
    Value<String>? countryCode,
    Value<double>? lat,
    Value<double>? lon,
    Value<String>? tz,
    Value<int>? rowid,
  }) {
    return CitiesCompanion(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      namePa: namePa ?? this.namePa,
      nameHi: nameHi ?? this.nameHi,
      countryCode: countryCode ?? this.countryCode,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      tz: tz ?? this.tz,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (namePa.present) {
      map['name_pa'] = Variable<String>(namePa.value);
    }
    if (nameHi.present) {
      map['name_hi'] = Variable<String>(nameHi.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (tz.present) {
      map['tz'] = Variable<String>(tz.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CitiesCompanion(')
          ..write('id: $id, ')
          ..write('nameEn: $nameEn, ')
          ..write('namePa: $namePa, ')
          ..write('nameHi: $nameHi, ')
          ..write('countryCode: $countryCode, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('tz: $tz, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuotesTable extends Quotes with TableInfo<$QuotesTable, QuoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gurmukhiMeta = const VerificationMeta(
    'gurmukhi',
  );
  @override
  late final GeneratedColumn<String> gurmukhi = GeneratedColumn<String>(
    'gurmukhi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _devanagariMeta = const VerificationMeta(
    'devanagari',
  );
  @override
  late final GeneratedColumn<String> devanagari = GeneratedColumn<String>(
    'devanagari',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _romanMeta = const VerificationMeta('roman');
  @override
  late final GeneratedColumn<String> roman = GeneratedColumn<String>(
    'roman',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attributionEnMeta = const VerificationMeta(
    'attributionEn',
  );
  @override
  late final GeneratedColumn<String> attributionEn = GeneratedColumn<String>(
    'attribution_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attributionPaMeta = const VerificationMeta(
    'attributionPa',
  );
  @override
  late final GeneratedColumn<String> attributionPa = GeneratedColumn<String>(
    'attribution_pa',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attributionHiMeta = const VerificationMeta(
    'attributionHi',
  );
  @override
  late final GeneratedColumn<String> attributionHi = GeneratedColumn<String>(
    'attribution_hi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gurmukhi,
    devanagari,
    roman,
    attributionEn,
    attributionPa,
    attributionHi,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quote';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('gurmukhi')) {
      context.handle(
        _gurmukhiMeta,
        gurmukhi.isAcceptableOrUnknown(data['gurmukhi']!, _gurmukhiMeta),
      );
    } else if (isInserting) {
      context.missing(_gurmukhiMeta);
    }
    if (data.containsKey('devanagari')) {
      context.handle(
        _devanagariMeta,
        devanagari.isAcceptableOrUnknown(data['devanagari']!, _devanagariMeta),
      );
    } else if (isInserting) {
      context.missing(_devanagariMeta);
    }
    if (data.containsKey('roman')) {
      context.handle(
        _romanMeta,
        roman.isAcceptableOrUnknown(data['roman']!, _romanMeta),
      );
    } else if (isInserting) {
      context.missing(_romanMeta);
    }
    if (data.containsKey('attribution_en')) {
      context.handle(
        _attributionEnMeta,
        attributionEn.isAcceptableOrUnknown(
          data['attribution_en']!,
          _attributionEnMeta,
        ),
      );
    }
    if (data.containsKey('attribution_pa')) {
      context.handle(
        _attributionPaMeta,
        attributionPa.isAcceptableOrUnknown(
          data['attribution_pa']!,
          _attributionPaMeta,
        ),
      );
    }
    if (data.containsKey('attribution_hi')) {
      context.handle(
        _attributionHiMeta,
        attributionHi.isAcceptableOrUnknown(
          data['attribution_hi']!,
          _attributionHiMeta,
        ),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      gurmukhi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gurmukhi'],
      )!,
      devanagari: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devanagari'],
      )!,
      roman: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roman'],
      )!,
      attributionEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution_en'],
      ),
      attributionPa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution_pa'],
      ),
      attributionHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution_hi'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
    );
  }

  @override
  $QuotesTable createAlias(String alias) {
    return $QuotesTable(attachedDatabase, alias);
  }
}

class QuoteRow extends DataClass implements Insertable<QuoteRow> {
  final String id;
  final String gurmukhi;
  final String devanagari;
  final String roman;
  final String? attributionEn;
  final String? attributionPa;
  final String? attributionHi;
  final String? sourceId;
  const QuoteRow({
    required this.id,
    required this.gurmukhi,
    required this.devanagari,
    required this.roman,
    this.attributionEn,
    this.attributionPa,
    this.attributionHi,
    this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['gurmukhi'] = Variable<String>(gurmukhi);
    map['devanagari'] = Variable<String>(devanagari);
    map['roman'] = Variable<String>(roman);
    if (!nullToAbsent || attributionEn != null) {
      map['attribution_en'] = Variable<String>(attributionEn);
    }
    if (!nullToAbsent || attributionPa != null) {
      map['attribution_pa'] = Variable<String>(attributionPa);
    }
    if (!nullToAbsent || attributionHi != null) {
      map['attribution_hi'] = Variable<String>(attributionHi);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    return map;
  }

  QuotesCompanion toCompanion(bool nullToAbsent) {
    return QuotesCompanion(
      id: Value(id),
      gurmukhi: Value(gurmukhi),
      devanagari: Value(devanagari),
      roman: Value(roman),
      attributionEn: attributionEn == null && nullToAbsent
          ? const Value.absent()
          : Value(attributionEn),
      attributionPa: attributionPa == null && nullToAbsent
          ? const Value.absent()
          : Value(attributionPa),
      attributionHi: attributionHi == null && nullToAbsent
          ? const Value.absent()
          : Value(attributionHi),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
    );
  }

  factory QuoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuoteRow(
      id: serializer.fromJson<String>(json['id']),
      gurmukhi: serializer.fromJson<String>(json['gurmukhi']),
      devanagari: serializer.fromJson<String>(json['devanagari']),
      roman: serializer.fromJson<String>(json['roman']),
      attributionEn: serializer.fromJson<String?>(json['attributionEn']),
      attributionPa: serializer.fromJson<String?>(json['attributionPa']),
      attributionHi: serializer.fromJson<String?>(json['attributionHi']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'gurmukhi': serializer.toJson<String>(gurmukhi),
      'devanagari': serializer.toJson<String>(devanagari),
      'roman': serializer.toJson<String>(roman),
      'attributionEn': serializer.toJson<String?>(attributionEn),
      'attributionPa': serializer.toJson<String?>(attributionPa),
      'attributionHi': serializer.toJson<String?>(attributionHi),
      'sourceId': serializer.toJson<String?>(sourceId),
    };
  }

  QuoteRow copyWith({
    String? id,
    String? gurmukhi,
    String? devanagari,
    String? roman,
    Value<String?> attributionEn = const Value.absent(),
    Value<String?> attributionPa = const Value.absent(),
    Value<String?> attributionHi = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
  }) => QuoteRow(
    id: id ?? this.id,
    gurmukhi: gurmukhi ?? this.gurmukhi,
    devanagari: devanagari ?? this.devanagari,
    roman: roman ?? this.roman,
    attributionEn: attributionEn.present
        ? attributionEn.value
        : this.attributionEn,
    attributionPa: attributionPa.present
        ? attributionPa.value
        : this.attributionPa,
    attributionHi: attributionHi.present
        ? attributionHi.value
        : this.attributionHi,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
  );
  QuoteRow copyWithCompanion(QuotesCompanion data) {
    return QuoteRow(
      id: data.id.present ? data.id.value : this.id,
      gurmukhi: data.gurmukhi.present ? data.gurmukhi.value : this.gurmukhi,
      devanagari: data.devanagari.present
          ? data.devanagari.value
          : this.devanagari,
      roman: data.roman.present ? data.roman.value : this.roman,
      attributionEn: data.attributionEn.present
          ? data.attributionEn.value
          : this.attributionEn,
      attributionPa: data.attributionPa.present
          ? data.attributionPa.value
          : this.attributionPa,
      attributionHi: data.attributionHi.present
          ? data.attributionHi.value
          : this.attributionHi,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuoteRow(')
          ..write('id: $id, ')
          ..write('gurmukhi: $gurmukhi, ')
          ..write('devanagari: $devanagari, ')
          ..write('roman: $roman, ')
          ..write('attributionEn: $attributionEn, ')
          ..write('attributionPa: $attributionPa, ')
          ..write('attributionHi: $attributionHi, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gurmukhi,
    devanagari,
    roman,
    attributionEn,
    attributionPa,
    attributionHi,
    sourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteRow &&
          other.id == this.id &&
          other.gurmukhi == this.gurmukhi &&
          other.devanagari == this.devanagari &&
          other.roman == this.roman &&
          other.attributionEn == this.attributionEn &&
          other.attributionPa == this.attributionPa &&
          other.attributionHi == this.attributionHi &&
          other.sourceId == this.sourceId);
}

class QuotesCompanion extends UpdateCompanion<QuoteRow> {
  final Value<String> id;
  final Value<String> gurmukhi;
  final Value<String> devanagari;
  final Value<String> roman;
  final Value<String?> attributionEn;
  final Value<String?> attributionPa;
  final Value<String?> attributionHi;
  final Value<String?> sourceId;
  final Value<int> rowid;
  const QuotesCompanion({
    this.id = const Value.absent(),
    this.gurmukhi = const Value.absent(),
    this.devanagari = const Value.absent(),
    this.roman = const Value.absent(),
    this.attributionEn = const Value.absent(),
    this.attributionPa = const Value.absent(),
    this.attributionHi = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuotesCompanion.insert({
    required String id,
    required String gurmukhi,
    required String devanagari,
    required String roman,
    this.attributionEn = const Value.absent(),
    this.attributionPa = const Value.absent(),
    this.attributionHi = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       gurmukhi = Value(gurmukhi),
       devanagari = Value(devanagari),
       roman = Value(roman);
  static Insertable<QuoteRow> custom({
    Expression<String>? id,
    Expression<String>? gurmukhi,
    Expression<String>? devanagari,
    Expression<String>? roman,
    Expression<String>? attributionEn,
    Expression<String>? attributionPa,
    Expression<String>? attributionHi,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gurmukhi != null) 'gurmukhi': gurmukhi,
      if (devanagari != null) 'devanagari': devanagari,
      if (roman != null) 'roman': roman,
      if (attributionEn != null) 'attribution_en': attributionEn,
      if (attributionPa != null) 'attribution_pa': attributionPa,
      if (attributionHi != null) 'attribution_hi': attributionHi,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuotesCompanion copyWith({
    Value<String>? id,
    Value<String>? gurmukhi,
    Value<String>? devanagari,
    Value<String>? roman,
    Value<String?>? attributionEn,
    Value<String?>? attributionPa,
    Value<String?>? attributionHi,
    Value<String?>? sourceId,
    Value<int>? rowid,
  }) {
    return QuotesCompanion(
      id: id ?? this.id,
      gurmukhi: gurmukhi ?? this.gurmukhi,
      devanagari: devanagari ?? this.devanagari,
      roman: roman ?? this.roman,
      attributionEn: attributionEn ?? this.attributionEn,
      attributionPa: attributionPa ?? this.attributionPa,
      attributionHi: attributionHi ?? this.attributionHi,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (gurmukhi.present) {
      map['gurmukhi'] = Variable<String>(gurmukhi.value);
    }
    if (devanagari.present) {
      map['devanagari'] = Variable<String>(devanagari.value);
    }
    if (roman.present) {
      map['roman'] = Variable<String>(roman.value);
    }
    if (attributionEn.present) {
      map['attribution_en'] = Variable<String>(attributionEn.value);
    }
    if (attributionPa.present) {
      map['attribution_pa'] = Variable<String>(attributionPa.value);
    }
    if (attributionHi.present) {
      map['attribution_hi'] = Variable<String>(attributionHi.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuotesCompanion(')
          ..write('id: $id, ')
          ..write('gurmukhi: $gurmukhi, ')
          ..write('devanagari: $devanagari, ')
          ..write('roman: $roman, ')
          ..write('attributionEn: $attributionEn, ')
          ..write('attributionPa: $attributionPa, ')
          ..write('attributionHi: $attributionHi, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetasTable extends Metas with TableInfo<$MetasTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MetasTable createAlias(String alias) {
    return $MetasTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  final String key;
  final String value;
  const MetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetasCompanion toCompanion(bool nullToAbsent) {
    return MetasCompanion(key: Value(key), value: Value(value));
  }

  factory MetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaRow copyWith({String? key, String? value}) =>
      MetaRow(key: key ?? this.key, value: value ?? this.value);
  MetaRow copyWithCompanion(MetasCompanion data) {
    return MetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaRow && other.key == this.key && other.value == this.value);
}

class MetasCompanion extends UpdateCompanion<MetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetasCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetasCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetasCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetasCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetasCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ContentDb extends GeneratedDatabase {
  _$ContentDb(QueryExecutor e) : super(e);
  $ContentDbManager get managers => $ContentDbManager(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $BanisTable banis = $BanisTable(this);
  late final $BaniVersionsTable baniVersions = $BaniVersionsTable(this);
  late final $LinesTable lines = $LinesTable(this);
  late final $MeaningsTable meanings = $MeaningsTable(this);
  late final $VoicesTable voices = $VoicesTable(this);
  late final $AudioTracksTable audioTracks = $AudioTracksTable(this);
  late final $TimingsTable timings = $TimingsTable(this);
  late final $NanakshahiMonthsTable nanakshahiMonths = $NanakshahiMonthsTable(
    this,
  );
  late final $CalendarEventsTable calendarEvents = $CalendarEventsTable(this);
  late final $CitiesTable cities = $CitiesTable(this);
  late final $QuotesTable quotes = $QuotesTable(this);
  late final $MetasTable metas = $MetasTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sources,
    banis,
    baniVersions,
    lines,
    meanings,
    voices,
    audioTracks,
    timings,
    nanakshahiMonths,
    calendarEvents,
    cities,
    quotes,
    metas,
  ];
}

typedef $$SourcesTableCreateCompanionBuilder =
    SourcesCompanion Function({
      required String id,
      required String name,
      Value<String?> author,
      required String kind,
      Value<String?> licence,
      Value<String?> url,
      Value<String?> notes,
      Value<String?> publisher,
      Value<String?> pubDate,
      Value<int> rowid,
    });
typedef $$SourcesTableUpdateCompanionBuilder =
    SourcesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> author,
      Value<String> kind,
      Value<String?> licence,
      Value<String?> url,
      Value<String?> notes,
      Value<String?> publisher,
      Value<String?> pubDate,
      Value<int> rowid,
    });

class $$SourcesTableFilterComposer
    extends Composer<_$ContentDb, $SourcesTable> {
  $$SourcesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get licence => $composableBuilder(
    column: $table.licence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SourcesTableOrderingComposer
    extends Composer<_$ContentDb, $SourcesTable> {
  $$SourcesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get licence => $composableBuilder(
    column: $table.licence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$ContentDb, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get licence =>
      $composableBuilder(column: $table.licence, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<String> get pubDate =>
      $composableBuilder(column: $table.pubDate, builder: (column) => column);
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $SourcesTable,
          SourceRow,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (SourceRow, BaseReferences<_$ContentDb, $SourcesTable, SourceRow>),
          SourceRow,
          PrefetchHooks Function()
        > {
  $$SourcesTableTableManager(_$ContentDb db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> licence = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> pubDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                name: name,
                author: author,
                kind: kind,
                licence: licence,
                url: url,
                notes: notes,
                publisher: publisher,
                pubDate: pubDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> author = const Value.absent(),
                required String kind,
                Value<String?> licence = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> pubDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                name: name,
                author: author,
                kind: kind,
                licence: licence,
                url: url,
                notes: notes,
                publisher: publisher,
                pubDate: pubDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SourcesTable, SourceRow>(table),
                  BaseReferences<_$ContentDb, $SourcesTable, SourceRow>(
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

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $SourcesTable,
      SourceRow,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (SourceRow, BaseReferences<_$ContentDb, $SourcesTable, SourceRow>),
      SourceRow,
      PrefetchHooks Function()
    >;
typedef $$BanisTableCreateCompanionBuilder =
    BanisCompanion Function({
      required String id,
      required String slug,
      required String nameEn,
      required String namePa,
      required String nameHi,
      required String category,
      required String defaultSlot,
      required int sort,
      required int estMinutes,
      Value<String?> authorEn,
      required bool hasText,
      Value<int> rowid,
    });
typedef $$BanisTableUpdateCompanionBuilder =
    BanisCompanion Function({
      Value<String> id,
      Value<String> slug,
      Value<String> nameEn,
      Value<String> namePa,
      Value<String> nameHi,
      Value<String> category,
      Value<String> defaultSlot,
      Value<int> sort,
      Value<int> estMinutes,
      Value<String?> authorEn,
      Value<bool> hasText,
      Value<int> rowid,
    });

class $$BanisTableFilterComposer extends Composer<_$ContentDb, $BanisTable> {
  $$BanisTableFilterComposer({
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

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namePa => $composableBuilder(
    column: $table.namePa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameHi => $composableBuilder(
    column: $table.nameHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultSlot => $composableBuilder(
    column: $table.defaultSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorEn => $composableBuilder(
    column: $table.authorEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasText => $composableBuilder(
    column: $table.hasText,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BanisTableOrderingComposer extends Composer<_$ContentDb, $BanisTable> {
  $$BanisTableOrderingComposer({
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

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namePa => $composableBuilder(
    column: $table.namePa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameHi => $composableBuilder(
    column: $table.nameHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultSlot => $composableBuilder(
    column: $table.defaultSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorEn => $composableBuilder(
    column: $table.authorEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasText => $composableBuilder(
    column: $table.hasText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BanisTableAnnotationComposer
    extends Composer<_$ContentDb, $BanisTable> {
  $$BanisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get namePa =>
      $composableBuilder(column: $table.namePa, builder: (column) => column);

  GeneratedColumn<String> get nameHi =>
      $composableBuilder(column: $table.nameHi, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get defaultSlot => $composableBuilder(
    column: $table.defaultSlot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorEn =>
      $composableBuilder(column: $table.authorEn, builder: (column) => column);

  GeneratedColumn<bool> get hasText =>
      $composableBuilder(column: $table.hasText, builder: (column) => column);
}

class $$BanisTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $BanisTable,
          BaniRow,
          $$BanisTableFilterComposer,
          $$BanisTableOrderingComposer,
          $$BanisTableAnnotationComposer,
          $$BanisTableCreateCompanionBuilder,
          $$BanisTableUpdateCompanionBuilder,
          (BaniRow, BaseReferences<_$ContentDb, $BanisTable, BaniRow>),
          BaniRow,
          PrefetchHooks Function()
        > {
  $$BanisTableTableManager(_$ContentDb db, $BanisTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BanisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BanisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BanisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> namePa = const Value.absent(),
                Value<String> nameHi = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> defaultSlot = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<int> estMinutes = const Value.absent(),
                Value<String?> authorEn = const Value.absent(),
                Value<bool> hasText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BanisCompanion(
                id: id,
                slug: slug,
                nameEn: nameEn,
                namePa: namePa,
                nameHi: nameHi,
                category: category,
                defaultSlot: defaultSlot,
                sort: sort,
                estMinutes: estMinutes,
                authorEn: authorEn,
                hasText: hasText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String slug,
                required String nameEn,
                required String namePa,
                required String nameHi,
                required String category,
                required String defaultSlot,
                required int sort,
                required int estMinutes,
                Value<String?> authorEn = const Value.absent(),
                required bool hasText,
                Value<int> rowid = const Value.absent(),
              }) => BanisCompanion.insert(
                id: id,
                slug: slug,
                nameEn: nameEn,
                namePa: namePa,
                nameHi: nameHi,
                category: category,
                defaultSlot: defaultSlot,
                sort: sort,
                estMinutes: estMinutes,
                authorEn: authorEn,
                hasText: hasText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BanisTable, BaniRow>(table),
                  BaseReferences<_$ContentDb, $BanisTable, BaniRow>(
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

typedef $$BanisTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $BanisTable,
      BaniRow,
      $$BanisTableFilterComposer,
      $$BanisTableOrderingComposer,
      $$BanisTableAnnotationComposer,
      $$BanisTableCreateCompanionBuilder,
      $$BanisTableUpdateCompanionBuilder,
      (BaniRow, BaseReferences<_$ContentDb, $BanisTable, BaniRow>),
      BaniRow,
      PrefetchHooks Function()
    >;
typedef $$BaniVersionsTableCreateCompanionBuilder =
    BaniVersionsCompanion Function({
      required String id,
      required String baniId,
      required String code,
      Value<String?> labelEn,
      Value<String?> labelPa,
      Value<String?> labelHi,
      required bool isDefault,
      required int lineCount,
      Value<int> rowid,
    });
typedef $$BaniVersionsTableUpdateCompanionBuilder =
    BaniVersionsCompanion Function({
      Value<String> id,
      Value<String> baniId,
      Value<String> code,
      Value<String?> labelEn,
      Value<String?> labelPa,
      Value<String?> labelHi,
      Value<bool> isDefault,
      Value<int> lineCount,
      Value<int> rowid,
    });

class $$BaniVersionsTableFilterComposer
    extends Composer<_$ContentDb, $BaniVersionsTable> {
  $$BaniVersionsTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelEn => $composableBuilder(
    column: $table.labelEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelPa => $composableBuilder(
    column: $table.labelPa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelHi => $composableBuilder(
    column: $table.labelHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineCount => $composableBuilder(
    column: $table.lineCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BaniVersionsTableOrderingComposer
    extends Composer<_$ContentDb, $BaniVersionsTable> {
  $$BaniVersionsTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelEn => $composableBuilder(
    column: $table.labelEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelPa => $composableBuilder(
    column: $table.labelPa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelHi => $composableBuilder(
    column: $table.labelHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineCount => $composableBuilder(
    column: $table.lineCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BaniVersionsTableAnnotationComposer
    extends Composer<_$ContentDb, $BaniVersionsTable> {
  $$BaniVersionsTableAnnotationComposer({
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

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get labelEn =>
      $composableBuilder(column: $table.labelEn, builder: (column) => column);

  GeneratedColumn<String> get labelPa =>
      $composableBuilder(column: $table.labelPa, builder: (column) => column);

  GeneratedColumn<String> get labelHi =>
      $composableBuilder(column: $table.labelHi, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get lineCount =>
      $composableBuilder(column: $table.lineCount, builder: (column) => column);
}

class $$BaniVersionsTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $BaniVersionsTable,
          BaniVersionRow,
          $$BaniVersionsTableFilterComposer,
          $$BaniVersionsTableOrderingComposer,
          $$BaniVersionsTableAnnotationComposer,
          $$BaniVersionsTableCreateCompanionBuilder,
          $$BaniVersionsTableUpdateCompanionBuilder,
          (
            BaniVersionRow,
            BaseReferences<_$ContentDb, $BaniVersionsTable, BaniVersionRow>,
          ),
          BaniVersionRow,
          PrefetchHooks Function()
        > {
  $$BaniVersionsTableTableManager(_$ContentDb db, $BaniVersionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BaniVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BaniVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BaniVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> baniId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String?> labelEn = const Value.absent(),
                Value<String?> labelPa = const Value.absent(),
                Value<String?> labelHi = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> lineCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BaniVersionsCompanion(
                id: id,
                baniId: baniId,
                code: code,
                labelEn: labelEn,
                labelPa: labelPa,
                labelHi: labelHi,
                isDefault: isDefault,
                lineCount: lineCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String baniId,
                required String code,
                Value<String?> labelEn = const Value.absent(),
                Value<String?> labelPa = const Value.absent(),
                Value<String?> labelHi = const Value.absent(),
                required bool isDefault,
                required int lineCount,
                Value<int> rowid = const Value.absent(),
              }) => BaniVersionsCompanion.insert(
                id: id,
                baniId: baniId,
                code: code,
                labelEn: labelEn,
                labelPa: labelPa,
                labelHi: labelHi,
                isDefault: isDefault,
                lineCount: lineCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BaniVersionsTable, BaniVersionRow>(table),
                  BaseReferences<
                    _$ContentDb,
                    $BaniVersionsTable,
                    BaniVersionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BaniVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $BaniVersionsTable,
      BaniVersionRow,
      $$BaniVersionsTableFilterComposer,
      $$BaniVersionsTableOrderingComposer,
      $$BaniVersionsTableAnnotationComposer,
      $$BaniVersionsTableCreateCompanionBuilder,
      $$BaniVersionsTableUpdateCompanionBuilder,
      (
        BaniVersionRow,
        BaseReferences<_$ContentDb, $BaniVersionsTable, BaniVersionRow>,
      ),
      BaniVersionRow,
      PrefetchHooks Function()
    >;
typedef $$LinesTableCreateCompanionBuilder =
    LinesCompanion Function({
      Value<int> id,
      required String baniVersionId,
      required int idx,
      Value<String?> sectionLabelEn,
      Value<String?> sectionLabelPa,
      Value<String?> sectionLabelHi,
      required String kind,
      required String gurmukhi,
      required String devanagari,
      required String roman,
      Value<String?> visraamJson,
      required int wordCount,
      required bool wordAlign,
      Value<String?> sourceId,
      Value<String?> sourceRef,
      Value<int?> pauri,
      Value<bool?> endsPauri,
    });
typedef $$LinesTableUpdateCompanionBuilder =
    LinesCompanion Function({
      Value<int> id,
      Value<String> baniVersionId,
      Value<int> idx,
      Value<String?> sectionLabelEn,
      Value<String?> sectionLabelPa,
      Value<String?> sectionLabelHi,
      Value<String> kind,
      Value<String> gurmukhi,
      Value<String> devanagari,
      Value<String> roman,
      Value<String?> visraamJson,
      Value<int> wordCount,
      Value<bool> wordAlign,
      Value<String?> sourceId,
      Value<String?> sourceRef,
      Value<int?> pauri,
      Value<bool?> endsPauri,
    });

class $$LinesTableFilterComposer extends Composer<_$ContentDb, $LinesTable> {
  $$LinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baniVersionId => $composableBuilder(
    column: $table.baniVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get idx => $composableBuilder(
    column: $table.idx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionLabelEn => $composableBuilder(
    column: $table.sectionLabelEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionLabelPa => $composableBuilder(
    column: $table.sectionLabelPa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionLabelHi => $composableBuilder(
    column: $table.sectionLabelHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gurmukhi => $composableBuilder(
    column: $table.gurmukhi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devanagari => $composableBuilder(
    column: $table.devanagari,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roman => $composableBuilder(
    column: $table.roman,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visraamJson => $composableBuilder(
    column: $table.visraamJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wordAlign => $composableBuilder(
    column: $table.wordAlign,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pauri => $composableBuilder(
    column: $table.pauri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get endsPauri => $composableBuilder(
    column: $table.endsPauri,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LinesTableOrderingComposer extends Composer<_$ContentDb, $LinesTable> {
  $$LinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baniVersionId => $composableBuilder(
    column: $table.baniVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idx => $composableBuilder(
    column: $table.idx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionLabelEn => $composableBuilder(
    column: $table.sectionLabelEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionLabelPa => $composableBuilder(
    column: $table.sectionLabelPa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionLabelHi => $composableBuilder(
    column: $table.sectionLabelHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gurmukhi => $composableBuilder(
    column: $table.gurmukhi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devanagari => $composableBuilder(
    column: $table.devanagari,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roman => $composableBuilder(
    column: $table.roman,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visraamJson => $composableBuilder(
    column: $table.visraamJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wordAlign => $composableBuilder(
    column: $table.wordAlign,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pauri => $composableBuilder(
    column: $table.pauri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get endsPauri => $composableBuilder(
    column: $table.endsPauri,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LinesTableAnnotationComposer
    extends Composer<_$ContentDb, $LinesTable> {
  $$LinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baniVersionId => $composableBuilder(
    column: $table.baniVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get idx =>
      $composableBuilder(column: $table.idx, builder: (column) => column);

  GeneratedColumn<String> get sectionLabelEn => $composableBuilder(
    column: $table.sectionLabelEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sectionLabelPa => $composableBuilder(
    column: $table.sectionLabelPa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sectionLabelHi => $composableBuilder(
    column: $table.sectionLabelHi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get gurmukhi =>
      $composableBuilder(column: $table.gurmukhi, builder: (column) => column);

  GeneratedColumn<String> get devanagari => $composableBuilder(
    column: $table.devanagari,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roman =>
      $composableBuilder(column: $table.roman, builder: (column) => column);

  GeneratedColumn<String> get visraamJson => $composableBuilder(
    column: $table.visraamJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<bool> get wordAlign =>
      $composableBuilder(column: $table.wordAlign, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get sourceRef =>
      $composableBuilder(column: $table.sourceRef, builder: (column) => column);

  GeneratedColumn<int> get pauri =>
      $composableBuilder(column: $table.pauri, builder: (column) => column);

  GeneratedColumn<bool> get endsPauri =>
      $composableBuilder(column: $table.endsPauri, builder: (column) => column);
}

class $$LinesTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $LinesTable,
          LineRow,
          $$LinesTableFilterComposer,
          $$LinesTableOrderingComposer,
          $$LinesTableAnnotationComposer,
          $$LinesTableCreateCompanionBuilder,
          $$LinesTableUpdateCompanionBuilder,
          (LineRow, BaseReferences<_$ContentDb, $LinesTable, LineRow>),
          LineRow,
          PrefetchHooks Function()
        > {
  $$LinesTableTableManager(_$ContentDb db, $LinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> baniVersionId = const Value.absent(),
                Value<int> idx = const Value.absent(),
                Value<String?> sectionLabelEn = const Value.absent(),
                Value<String?> sectionLabelPa = const Value.absent(),
                Value<String?> sectionLabelHi = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> gurmukhi = const Value.absent(),
                Value<String> devanagari = const Value.absent(),
                Value<String> roman = const Value.absent(),
                Value<String?> visraamJson = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<bool> wordAlign = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> sourceRef = const Value.absent(),
                Value<int?> pauri = const Value.absent(),
                Value<bool?> endsPauri = const Value.absent(),
              }) => LinesCompanion(
                id: id,
                baniVersionId: baniVersionId,
                idx: idx,
                sectionLabelEn: sectionLabelEn,
                sectionLabelPa: sectionLabelPa,
                sectionLabelHi: sectionLabelHi,
                kind: kind,
                gurmukhi: gurmukhi,
                devanagari: devanagari,
                roman: roman,
                visraamJson: visraamJson,
                wordCount: wordCount,
                wordAlign: wordAlign,
                sourceId: sourceId,
                sourceRef: sourceRef,
                pauri: pauri,
                endsPauri: endsPauri,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String baniVersionId,
                required int idx,
                Value<String?> sectionLabelEn = const Value.absent(),
                Value<String?> sectionLabelPa = const Value.absent(),
                Value<String?> sectionLabelHi = const Value.absent(),
                required String kind,
                required String gurmukhi,
                required String devanagari,
                required String roman,
                Value<String?> visraamJson = const Value.absent(),
                required int wordCount,
                required bool wordAlign,
                Value<String?> sourceId = const Value.absent(),
                Value<String?> sourceRef = const Value.absent(),
                Value<int?> pauri = const Value.absent(),
                Value<bool?> endsPauri = const Value.absent(),
              }) => LinesCompanion.insert(
                id: id,
                baniVersionId: baniVersionId,
                idx: idx,
                sectionLabelEn: sectionLabelEn,
                sectionLabelPa: sectionLabelPa,
                sectionLabelHi: sectionLabelHi,
                kind: kind,
                gurmukhi: gurmukhi,
                devanagari: devanagari,
                roman: roman,
                visraamJson: visraamJson,
                wordCount: wordCount,
                wordAlign: wordAlign,
                sourceId: sourceId,
                sourceRef: sourceRef,
                pauri: pauri,
                endsPauri: endsPauri,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LinesTable, LineRow>(table),
                  BaseReferences<_$ContentDb, $LinesTable, LineRow>(
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

typedef $$LinesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $LinesTable,
      LineRow,
      $$LinesTableFilterComposer,
      $$LinesTableOrderingComposer,
      $$LinesTableAnnotationComposer,
      $$LinesTableCreateCompanionBuilder,
      $$LinesTableUpdateCompanionBuilder,
      (LineRow, BaseReferences<_$ContentDb, $LinesTable, LineRow>),
      LineRow,
      PrefetchHooks Function()
    >;
typedef $$MeaningsTableCreateCompanionBuilder =
    MeaningsCompanion Function({
      required int lineId,
      required String lang,
      required String body,
      Value<String?> sourceId,
      required bool isAlt,
      required String kind,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$MeaningsTableUpdateCompanionBuilder =
    MeaningsCompanion Function({
      Value<int> lineId,
      Value<String> lang,
      Value<String> body,
      Value<String?> sourceId,
      Value<bool> isAlt,
      Value<String> kind,
      Value<String?> note,
      Value<int> rowid,
    });

class $$MeaningsTableFilterComposer
    extends Composer<_$ContentDb, $MeaningsTable> {
  $$MeaningsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get lineId => $composableBuilder(
    column: $table.lineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAlt => $composableBuilder(
    column: $table.isAlt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MeaningsTableOrderingComposer
    extends Composer<_$ContentDb, $MeaningsTable> {
  $$MeaningsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get lineId => $composableBuilder(
    column: $table.lineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAlt => $composableBuilder(
    column: $table.isAlt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MeaningsTableAnnotationComposer
    extends Composer<_$ContentDb, $MeaningsTable> {
  $$MeaningsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get lineId =>
      $composableBuilder(column: $table.lineId, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<bool> get isAlt =>
      $composableBuilder(column: $table.isAlt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$MeaningsTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $MeaningsTable,
          MeaningRow,
          $$MeaningsTableFilterComposer,
          $$MeaningsTableOrderingComposer,
          $$MeaningsTableAnnotationComposer,
          $$MeaningsTableCreateCompanionBuilder,
          $$MeaningsTableUpdateCompanionBuilder,
          (MeaningRow, BaseReferences<_$ContentDb, $MeaningsTable, MeaningRow>),
          MeaningRow,
          PrefetchHooks Function()
        > {
  $$MeaningsTableTableManager(_$ContentDb db, $MeaningsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeaningsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeaningsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeaningsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> lineId = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<bool> isAlt = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeaningsCompanion(
                lineId: lineId,
                lang: lang,
                body: body,
                sourceId: sourceId,
                isAlt: isAlt,
                kind: kind,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int lineId,
                required String lang,
                required String body,
                Value<String?> sourceId = const Value.absent(),
                required bool isAlt,
                required String kind,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeaningsCompanion.insert(
                lineId: lineId,
                lang: lang,
                body: body,
                sourceId: sourceId,
                isAlt: isAlt,
                kind: kind,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MeaningsTable, MeaningRow>(table),
                  BaseReferences<_$ContentDb, $MeaningsTable, MeaningRow>(
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

typedef $$MeaningsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $MeaningsTable,
      MeaningRow,
      $$MeaningsTableFilterComposer,
      $$MeaningsTableOrderingComposer,
      $$MeaningsTableAnnotationComposer,
      $$MeaningsTableCreateCompanionBuilder,
      $$MeaningsTableUpdateCompanionBuilder,
      (MeaningRow, BaseReferences<_$ContentDb, $MeaningsTable, MeaningRow>),
      MeaningRow,
      PrefetchHooks Function()
    >;
typedef $$VoicesTableCreateCompanionBuilder =
    VoicesCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> creditEn,
      Value<String?> creditPa,
      Value<String?> creditHi,
      Value<int> rowid,
    });
typedef $$VoicesTableUpdateCompanionBuilder =
    VoicesCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> creditEn,
      Value<String?> creditPa,
      Value<String?> creditHi,
      Value<int> rowid,
    });

class $$VoicesTableFilterComposer extends Composer<_$ContentDb, $VoicesTable> {
  $$VoicesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creditEn => $composableBuilder(
    column: $table.creditEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creditPa => $composableBuilder(
    column: $table.creditPa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creditHi => $composableBuilder(
    column: $table.creditHi,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VoicesTableOrderingComposer
    extends Composer<_$ContentDb, $VoicesTable> {
  $$VoicesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creditEn => $composableBuilder(
    column: $table.creditEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creditPa => $composableBuilder(
    column: $table.creditPa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creditHi => $composableBuilder(
    column: $table.creditHi,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoicesTableAnnotationComposer
    extends Composer<_$ContentDb, $VoicesTable> {
  $$VoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get creditEn =>
      $composableBuilder(column: $table.creditEn, builder: (column) => column);

  GeneratedColumn<String> get creditPa =>
      $composableBuilder(column: $table.creditPa, builder: (column) => column);

  GeneratedColumn<String> get creditHi =>
      $composableBuilder(column: $table.creditHi, builder: (column) => column);
}

class $$VoicesTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $VoicesTable,
          VoiceRow,
          $$VoicesTableFilterComposer,
          $$VoicesTableOrderingComposer,
          $$VoicesTableAnnotationComposer,
          $$VoicesTableCreateCompanionBuilder,
          $$VoicesTableUpdateCompanionBuilder,
          (VoiceRow, BaseReferences<_$ContentDb, $VoicesTable, VoiceRow>),
          VoiceRow,
          PrefetchHooks Function()
        > {
  $$VoicesTableTableManager(_$ContentDb db, $VoicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> creditEn = const Value.absent(),
                Value<String?> creditPa = const Value.absent(),
                Value<String?> creditHi = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoicesCompanion(
                id: id,
                name: name,
                creditEn: creditEn,
                creditPa: creditPa,
                creditHi: creditHi,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> creditEn = const Value.absent(),
                Value<String?> creditPa = const Value.absent(),
                Value<String?> creditHi = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoicesCompanion.insert(
                id: id,
                name: name,
                creditEn: creditEn,
                creditPa: creditPa,
                creditHi: creditHi,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VoicesTable, VoiceRow>(table),
                  BaseReferences<_$ContentDb, $VoicesTable, VoiceRow>(
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

typedef $$VoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $VoicesTable,
      VoiceRow,
      $$VoicesTableFilterComposer,
      $$VoicesTableOrderingComposer,
      $$VoicesTableAnnotationComposer,
      $$VoicesTableCreateCompanionBuilder,
      $$VoicesTableUpdateCompanionBuilder,
      (VoiceRow, BaseReferences<_$ContentDb, $VoicesTable, VoiceRow>),
      VoiceRow,
      PrefetchHooks Function()
    >;
typedef $$AudioTracksTableCreateCompanionBuilder =
    AudioTracksCompanion Function({
      required String id,
      required String baniVersionId,
      Value<String?> voiceId,
      required String pack,
      required String file,
      Value<int?> durationMs,
      Value<int?> bytes,
      Value<int> rowid,
    });
typedef $$AudioTracksTableUpdateCompanionBuilder =
    AudioTracksCompanion Function({
      Value<String> id,
      Value<String> baniVersionId,
      Value<String?> voiceId,
      Value<String> pack,
      Value<String> file,
      Value<int?> durationMs,
      Value<int?> bytes,
      Value<int> rowid,
    });

class $$AudioTracksTableFilterComposer
    extends Composer<_$ContentDb, $AudioTracksTable> {
  $$AudioTracksTableFilterComposer({
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

  ColumnFilters<String> get baniVersionId => $composableBuilder(
    column: $table.baniVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pack => $composableBuilder(
    column: $table.pack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get file => $composableBuilder(
    column: $table.file,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AudioTracksTableOrderingComposer
    extends Composer<_$ContentDb, $AudioTracksTable> {
  $$AudioTracksTableOrderingComposer({
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

  ColumnOrderings<String> get baniVersionId => $composableBuilder(
    column: $table.baniVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pack => $composableBuilder(
    column: $table.pack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get file => $composableBuilder(
    column: $table.file,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AudioTracksTableAnnotationComposer
    extends Composer<_$ContentDb, $AudioTracksTable> {
  $$AudioTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baniVersionId => $composableBuilder(
    column: $table.baniVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voiceId =>
      $composableBuilder(column: $table.voiceId, builder: (column) => column);

  GeneratedColumn<String> get pack =>
      $composableBuilder(column: $table.pack, builder: (column) => column);

  GeneratedColumn<String> get file =>
      $composableBuilder(column: $table.file, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);
}

class $$AudioTracksTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $AudioTracksTable,
          AudioTrackRow,
          $$AudioTracksTableFilterComposer,
          $$AudioTracksTableOrderingComposer,
          $$AudioTracksTableAnnotationComposer,
          $$AudioTracksTableCreateCompanionBuilder,
          $$AudioTracksTableUpdateCompanionBuilder,
          (
            AudioTrackRow,
            BaseReferences<_$ContentDb, $AudioTracksTable, AudioTrackRow>,
          ),
          AudioTrackRow,
          PrefetchHooks Function()
        > {
  $$AudioTracksTableTableManager(_$ContentDb db, $AudioTracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> baniVersionId = const Value.absent(),
                Value<String?> voiceId = const Value.absent(),
                Value<String> pack = const Value.absent(),
                Value<String> file = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> bytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AudioTracksCompanion(
                id: id,
                baniVersionId: baniVersionId,
                voiceId: voiceId,
                pack: pack,
                file: file,
                durationMs: durationMs,
                bytes: bytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String baniVersionId,
                Value<String?> voiceId = const Value.absent(),
                required String pack,
                required String file,
                Value<int?> durationMs = const Value.absent(),
                Value<int?> bytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AudioTracksCompanion.insert(
                id: id,
                baniVersionId: baniVersionId,
                voiceId: voiceId,
                pack: pack,
                file: file,
                durationMs: durationMs,
                bytes: bytes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AudioTracksTable, AudioTrackRow>(table),
                  BaseReferences<_$ContentDb, $AudioTracksTable, AudioTrackRow>(
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

typedef $$AudioTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $AudioTracksTable,
      AudioTrackRow,
      $$AudioTracksTableFilterComposer,
      $$AudioTracksTableOrderingComposer,
      $$AudioTracksTableAnnotationComposer,
      $$AudioTracksTableCreateCompanionBuilder,
      $$AudioTracksTableUpdateCompanionBuilder,
      (
        AudioTrackRow,
        BaseReferences<_$ContentDb, $AudioTracksTable, AudioTrackRow>,
      ),
      AudioTrackRow,
      PrefetchHooks Function()
    >;
typedef $$TimingsTableCreateCompanionBuilder =
    TimingsCompanion Function({
      required String audioTrackId,
      required String json,
      Value<int> rowid,
    });
typedef $$TimingsTableUpdateCompanionBuilder =
    TimingsCompanion Function({
      Value<String> audioTrackId,
      Value<String> json,
      Value<int> rowid,
    });

class $$TimingsTableFilterComposer
    extends Composer<_$ContentDb, $TimingsTable> {
  $$TimingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get audioTrackId => $composableBuilder(
    column: $table.audioTrackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimingsTableOrderingComposer
    extends Composer<_$ContentDb, $TimingsTable> {
  $$TimingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get audioTrackId => $composableBuilder(
    column: $table.audioTrackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimingsTableAnnotationComposer
    extends Composer<_$ContentDb, $TimingsTable> {
  $$TimingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get audioTrackId => $composableBuilder(
    column: $table.audioTrackId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$TimingsTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $TimingsTable,
          TimingRow,
          $$TimingsTableFilterComposer,
          $$TimingsTableOrderingComposer,
          $$TimingsTableAnnotationComposer,
          $$TimingsTableCreateCompanionBuilder,
          $$TimingsTableUpdateCompanionBuilder,
          (TimingRow, BaseReferences<_$ContentDb, $TimingsTable, TimingRow>),
          TimingRow,
          PrefetchHooks Function()
        > {
  $$TimingsTableTableManager(_$ContentDb db, $TimingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> audioTrackId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimingsCompanion(
                audioTrackId: audioTrackId,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String audioTrackId,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => TimingsCompanion.insert(
                audioTrackId: audioTrackId,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TimingsTable, TimingRow>(table),
                  BaseReferences<_$ContentDb, $TimingsTable, TimingRow>(
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

typedef $$TimingsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $TimingsTable,
      TimingRow,
      $$TimingsTableFilterComposer,
      $$TimingsTableOrderingComposer,
      $$TimingsTableAnnotationComposer,
      $$TimingsTableCreateCompanionBuilder,
      $$TimingsTableUpdateCompanionBuilder,
      (TimingRow, BaseReferences<_$ContentDb, $TimingsTable, TimingRow>),
      TimingRow,
      PrefetchHooks Function()
    >;
typedef $$NanakshahiMonthsTableCreateCompanionBuilder =
    NanakshahiMonthsCompanion Function({
      required int nsYear,
      required int idx,
      required String nameEn,
      required String namePa,
      required String nameHi,
      required String startDate,
      required int days,
      Value<int> rowid,
    });
typedef $$NanakshahiMonthsTableUpdateCompanionBuilder =
    NanakshahiMonthsCompanion Function({
      Value<int> nsYear,
      Value<int> idx,
      Value<String> nameEn,
      Value<String> namePa,
      Value<String> nameHi,
      Value<String> startDate,
      Value<int> days,
      Value<int> rowid,
    });

class $$NanakshahiMonthsTableFilterComposer
    extends Composer<_$ContentDb, $NanakshahiMonthsTable> {
  $$NanakshahiMonthsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get nsYear => $composableBuilder(
    column: $table.nsYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get idx => $composableBuilder(
    column: $table.idx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namePa => $composableBuilder(
    column: $table.namePa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameHi => $composableBuilder(
    column: $table.nameHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NanakshahiMonthsTableOrderingComposer
    extends Composer<_$ContentDb, $NanakshahiMonthsTable> {
  $$NanakshahiMonthsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get nsYear => $composableBuilder(
    column: $table.nsYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idx => $composableBuilder(
    column: $table.idx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namePa => $composableBuilder(
    column: $table.namePa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameHi => $composableBuilder(
    column: $table.nameHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NanakshahiMonthsTableAnnotationComposer
    extends Composer<_$ContentDb, $NanakshahiMonthsTable> {
  $$NanakshahiMonthsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get nsYear =>
      $composableBuilder(column: $table.nsYear, builder: (column) => column);

  GeneratedColumn<int> get idx =>
      $composableBuilder(column: $table.idx, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get namePa =>
      $composableBuilder(column: $table.namePa, builder: (column) => column);

  GeneratedColumn<String> get nameHi =>
      $composableBuilder(column: $table.nameHi, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);
}

class $$NanakshahiMonthsTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $NanakshahiMonthsTable,
          NanakshahiMonthRow,
          $$NanakshahiMonthsTableFilterComposer,
          $$NanakshahiMonthsTableOrderingComposer,
          $$NanakshahiMonthsTableAnnotationComposer,
          $$NanakshahiMonthsTableCreateCompanionBuilder,
          $$NanakshahiMonthsTableUpdateCompanionBuilder,
          (
            NanakshahiMonthRow,
            BaseReferences<
              _$ContentDb,
              $NanakshahiMonthsTable,
              NanakshahiMonthRow
            >,
          ),
          NanakshahiMonthRow,
          PrefetchHooks Function()
        > {
  $$NanakshahiMonthsTableTableManager(
    _$ContentDb db,
    $NanakshahiMonthsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NanakshahiMonthsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NanakshahiMonthsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NanakshahiMonthsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> nsYear = const Value.absent(),
                Value<int> idx = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> namePa = const Value.absent(),
                Value<String> nameHi = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<int> days = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NanakshahiMonthsCompanion(
                nsYear: nsYear,
                idx: idx,
                nameEn: nameEn,
                namePa: namePa,
                nameHi: nameHi,
                startDate: startDate,
                days: days,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int nsYear,
                required int idx,
                required String nameEn,
                required String namePa,
                required String nameHi,
                required String startDate,
                required int days,
                Value<int> rowid = const Value.absent(),
              }) => NanakshahiMonthsCompanion.insert(
                nsYear: nsYear,
                idx: idx,
                nameEn: nameEn,
                namePa: namePa,
                nameHi: nameHi,
                startDate: startDate,
                days: days,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NanakshahiMonthsTable, NanakshahiMonthRow>(
                    table,
                  ),
                  BaseReferences<
                    _$ContentDb,
                    $NanakshahiMonthsTable,
                    NanakshahiMonthRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NanakshahiMonthsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $NanakshahiMonthsTable,
      NanakshahiMonthRow,
      $$NanakshahiMonthsTableFilterComposer,
      $$NanakshahiMonthsTableOrderingComposer,
      $$NanakshahiMonthsTableAnnotationComposer,
      $$NanakshahiMonthsTableCreateCompanionBuilder,
      $$NanakshahiMonthsTableUpdateCompanionBuilder,
      (
        NanakshahiMonthRow,
        BaseReferences<_$ContentDb, $NanakshahiMonthsTable, NanakshahiMonthRow>,
      ),
      NanakshahiMonthRow,
      PrefetchHooks Function()
    >;
typedef $$CalendarEventsTableCreateCompanionBuilder =
    CalendarEventsCompanion Function({
      required String id,
      required int nsYear,
      required String date,
      required String kind,
      required String nameEn,
      required String namePa,
      required String nameHi,
      Value<String?> nsLabel,
      required bool defaultRemind,
      Value<int> rowid,
    });
typedef $$CalendarEventsTableUpdateCompanionBuilder =
    CalendarEventsCompanion Function({
      Value<String> id,
      Value<int> nsYear,
      Value<String> date,
      Value<String> kind,
      Value<String> nameEn,
      Value<String> namePa,
      Value<String> nameHi,
      Value<String?> nsLabel,
      Value<bool> defaultRemind,
      Value<int> rowid,
    });

class $$CalendarEventsTableFilterComposer
    extends Composer<_$ContentDb, $CalendarEventsTable> {
  $$CalendarEventsTableFilterComposer({
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

  ColumnFilters<int> get nsYear => $composableBuilder(
    column: $table.nsYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namePa => $composableBuilder(
    column: $table.namePa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameHi => $composableBuilder(
    column: $table.nameHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nsLabel => $composableBuilder(
    column: $table.nsLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get defaultRemind => $composableBuilder(
    column: $table.defaultRemind,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalendarEventsTableOrderingComposer
    extends Composer<_$ContentDb, $CalendarEventsTable> {
  $$CalendarEventsTableOrderingComposer({
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

  ColumnOrderings<int> get nsYear => $composableBuilder(
    column: $table.nsYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namePa => $composableBuilder(
    column: $table.namePa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameHi => $composableBuilder(
    column: $table.nameHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nsLabel => $composableBuilder(
    column: $table.nsLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get defaultRemind => $composableBuilder(
    column: $table.defaultRemind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarEventsTableAnnotationComposer
    extends Composer<_$ContentDb, $CalendarEventsTable> {
  $$CalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get nsYear =>
      $composableBuilder(column: $table.nsYear, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get namePa =>
      $composableBuilder(column: $table.namePa, builder: (column) => column);

  GeneratedColumn<String> get nameHi =>
      $composableBuilder(column: $table.nameHi, builder: (column) => column);

  GeneratedColumn<String> get nsLabel =>
      $composableBuilder(column: $table.nsLabel, builder: (column) => column);

  GeneratedColumn<bool> get defaultRemind => $composableBuilder(
    column: $table.defaultRemind,
    builder: (column) => column,
  );
}

class $$CalendarEventsTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $CalendarEventsTable,
          CalendarEventRow,
          $$CalendarEventsTableFilterComposer,
          $$CalendarEventsTableOrderingComposer,
          $$CalendarEventsTableAnnotationComposer,
          $$CalendarEventsTableCreateCompanionBuilder,
          $$CalendarEventsTableUpdateCompanionBuilder,
          (
            CalendarEventRow,
            BaseReferences<_$ContentDb, $CalendarEventsTable, CalendarEventRow>,
          ),
          CalendarEventRow,
          PrefetchHooks Function()
        > {
  $$CalendarEventsTableTableManager(_$ContentDb db, $CalendarEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> nsYear = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> namePa = const Value.absent(),
                Value<String> nameHi = const Value.absent(),
                Value<String?> nsLabel = const Value.absent(),
                Value<bool> defaultRemind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion(
                id: id,
                nsYear: nsYear,
                date: date,
                kind: kind,
                nameEn: nameEn,
                namePa: namePa,
                nameHi: nameHi,
                nsLabel: nsLabel,
                defaultRemind: defaultRemind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int nsYear,
                required String date,
                required String kind,
                required String nameEn,
                required String namePa,
                required String nameHi,
                Value<String?> nsLabel = const Value.absent(),
                required bool defaultRemind,
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion.insert(
                id: id,
                nsYear: nsYear,
                date: date,
                kind: kind,
                nameEn: nameEn,
                namePa: namePa,
                nameHi: nameHi,
                nsLabel: nsLabel,
                defaultRemind: defaultRemind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarEventsTable, CalendarEventRow>(table),
                  BaseReferences<
                    _$ContentDb,
                    $CalendarEventsTable,
                    CalendarEventRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $CalendarEventsTable,
      CalendarEventRow,
      $$CalendarEventsTableFilterComposer,
      $$CalendarEventsTableOrderingComposer,
      $$CalendarEventsTableAnnotationComposer,
      $$CalendarEventsTableCreateCompanionBuilder,
      $$CalendarEventsTableUpdateCompanionBuilder,
      (
        CalendarEventRow,
        BaseReferences<_$ContentDb, $CalendarEventsTable, CalendarEventRow>,
      ),
      CalendarEventRow,
      PrefetchHooks Function()
    >;
typedef $$CitiesTableCreateCompanionBuilder =
    CitiesCompanion Function({
      required String id,
      required String nameEn,
      required String namePa,
      required String nameHi,
      required String countryCode,
      required double lat,
      required double lon,
      required String tz,
      Value<int> rowid,
    });
typedef $$CitiesTableUpdateCompanionBuilder =
    CitiesCompanion Function({
      Value<String> id,
      Value<String> nameEn,
      Value<String> namePa,
      Value<String> nameHi,
      Value<String> countryCode,
      Value<double> lat,
      Value<double> lon,
      Value<String> tz,
      Value<int> rowid,
    });

class $$CitiesTableFilterComposer extends Composer<_$ContentDb, $CitiesTable> {
  $$CitiesTableFilterComposer({
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

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namePa => $composableBuilder(
    column: $table.namePa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameHi => $composableBuilder(
    column: $table.nameHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tz => $composableBuilder(
    column: $table.tz,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CitiesTableOrderingComposer
    extends Composer<_$ContentDb, $CitiesTable> {
  $$CitiesTableOrderingComposer({
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

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namePa => $composableBuilder(
    column: $table.namePa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameHi => $composableBuilder(
    column: $table.nameHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tz => $composableBuilder(
    column: $table.tz,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CitiesTableAnnotationComposer
    extends Composer<_$ContentDb, $CitiesTable> {
  $$CitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get namePa =>
      $composableBuilder(column: $table.namePa, builder: (column) => column);

  GeneratedColumn<String> get nameHi =>
      $composableBuilder(column: $table.nameHi, builder: (column) => column);

  GeneratedColumn<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get tz =>
      $composableBuilder(column: $table.tz, builder: (column) => column);
}

class $$CitiesTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $CitiesTable,
          CityRow,
          $$CitiesTableFilterComposer,
          $$CitiesTableOrderingComposer,
          $$CitiesTableAnnotationComposer,
          $$CitiesTableCreateCompanionBuilder,
          $$CitiesTableUpdateCompanionBuilder,
          (CityRow, BaseReferences<_$ContentDb, $CitiesTable, CityRow>),
          CityRow,
          PrefetchHooks Function()
        > {
  $$CitiesTableTableManager(_$ContentDb db, $CitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> namePa = const Value.absent(),
                Value<String> nameHi = const Value.absent(),
                Value<String> countryCode = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<String> tz = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CitiesCompanion(
                id: id,
                nameEn: nameEn,
                namePa: namePa,
                nameHi: nameHi,
                countryCode: countryCode,
                lat: lat,
                lon: lon,
                tz: tz,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nameEn,
                required String namePa,
                required String nameHi,
                required String countryCode,
                required double lat,
                required double lon,
                required String tz,
                Value<int> rowid = const Value.absent(),
              }) => CitiesCompanion.insert(
                id: id,
                nameEn: nameEn,
                namePa: namePa,
                nameHi: nameHi,
                countryCode: countryCode,
                lat: lat,
                lon: lon,
                tz: tz,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CitiesTable, CityRow>(table),
                  BaseReferences<_$ContentDb, $CitiesTable, CityRow>(
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

typedef $$CitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $CitiesTable,
      CityRow,
      $$CitiesTableFilterComposer,
      $$CitiesTableOrderingComposer,
      $$CitiesTableAnnotationComposer,
      $$CitiesTableCreateCompanionBuilder,
      $$CitiesTableUpdateCompanionBuilder,
      (CityRow, BaseReferences<_$ContentDb, $CitiesTable, CityRow>),
      CityRow,
      PrefetchHooks Function()
    >;
typedef $$QuotesTableCreateCompanionBuilder =
    QuotesCompanion Function({
      required String id,
      required String gurmukhi,
      required String devanagari,
      required String roman,
      Value<String?> attributionEn,
      Value<String?> attributionPa,
      Value<String?> attributionHi,
      Value<String?> sourceId,
      Value<int> rowid,
    });
typedef $$QuotesTableUpdateCompanionBuilder =
    QuotesCompanion Function({
      Value<String> id,
      Value<String> gurmukhi,
      Value<String> devanagari,
      Value<String> roman,
      Value<String?> attributionEn,
      Value<String?> attributionPa,
      Value<String?> attributionHi,
      Value<String?> sourceId,
      Value<int> rowid,
    });

class $$QuotesTableFilterComposer extends Composer<_$ContentDb, $QuotesTable> {
  $$QuotesTableFilterComposer({
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

  ColumnFilters<String> get gurmukhi => $composableBuilder(
    column: $table.gurmukhi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devanagari => $composableBuilder(
    column: $table.devanagari,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roman => $composableBuilder(
    column: $table.roman,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attributionEn => $composableBuilder(
    column: $table.attributionEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attributionPa => $composableBuilder(
    column: $table.attributionPa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attributionHi => $composableBuilder(
    column: $table.attributionHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuotesTableOrderingComposer
    extends Composer<_$ContentDb, $QuotesTable> {
  $$QuotesTableOrderingComposer({
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

  ColumnOrderings<String> get gurmukhi => $composableBuilder(
    column: $table.gurmukhi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devanagari => $composableBuilder(
    column: $table.devanagari,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roman => $composableBuilder(
    column: $table.roman,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attributionEn => $composableBuilder(
    column: $table.attributionEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attributionPa => $composableBuilder(
    column: $table.attributionPa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attributionHi => $composableBuilder(
    column: $table.attributionHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuotesTableAnnotationComposer
    extends Composer<_$ContentDb, $QuotesTable> {
  $$QuotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gurmukhi =>
      $composableBuilder(column: $table.gurmukhi, builder: (column) => column);

  GeneratedColumn<String> get devanagari => $composableBuilder(
    column: $table.devanagari,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roman =>
      $composableBuilder(column: $table.roman, builder: (column) => column);

  GeneratedColumn<String> get attributionEn => $composableBuilder(
    column: $table.attributionEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attributionPa => $composableBuilder(
    column: $table.attributionPa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attributionHi => $composableBuilder(
    column: $table.attributionHi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);
}

class $$QuotesTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $QuotesTable,
          QuoteRow,
          $$QuotesTableFilterComposer,
          $$QuotesTableOrderingComposer,
          $$QuotesTableAnnotationComposer,
          $$QuotesTableCreateCompanionBuilder,
          $$QuotesTableUpdateCompanionBuilder,
          (QuoteRow, BaseReferences<_$ContentDb, $QuotesTable, QuoteRow>),
          QuoteRow,
          PrefetchHooks Function()
        > {
  $$QuotesTableTableManager(_$ContentDb db, $QuotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> gurmukhi = const Value.absent(),
                Value<String> devanagari = const Value.absent(),
                Value<String> roman = const Value.absent(),
                Value<String?> attributionEn = const Value.absent(),
                Value<String?> attributionPa = const Value.absent(),
                Value<String?> attributionHi = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuotesCompanion(
                id: id,
                gurmukhi: gurmukhi,
                devanagari: devanagari,
                roman: roman,
                attributionEn: attributionEn,
                attributionPa: attributionPa,
                attributionHi: attributionHi,
                sourceId: sourceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String gurmukhi,
                required String devanagari,
                required String roman,
                Value<String?> attributionEn = const Value.absent(),
                Value<String?> attributionPa = const Value.absent(),
                Value<String?> attributionHi = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuotesCompanion.insert(
                id: id,
                gurmukhi: gurmukhi,
                devanagari: devanagari,
                roman: roman,
                attributionEn: attributionEn,
                attributionPa: attributionPa,
                attributionHi: attributionHi,
                sourceId: sourceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuotesTable, QuoteRow>(table),
                  BaseReferences<_$ContentDb, $QuotesTable, QuoteRow>(
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

typedef $$QuotesTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $QuotesTable,
      QuoteRow,
      $$QuotesTableFilterComposer,
      $$QuotesTableOrderingComposer,
      $$QuotesTableAnnotationComposer,
      $$QuotesTableCreateCompanionBuilder,
      $$QuotesTableUpdateCompanionBuilder,
      (QuoteRow, BaseReferences<_$ContentDb, $QuotesTable, QuoteRow>),
      QuoteRow,
      PrefetchHooks Function()
    >;
typedef $$MetasTableCreateCompanionBuilder =
    MetasCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$MetasTableUpdateCompanionBuilder =
    MetasCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$MetasTableFilterComposer extends Composer<_$ContentDb, $MetasTable> {
  $$MetasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetasTableOrderingComposer extends Composer<_$ContentDb, $MetasTable> {
  $$MetasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetasTableAnnotationComposer
    extends Composer<_$ContentDb, $MetasTable> {
  $$MetasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetasTableTableManager
    extends
        RootTableManager<
          _$ContentDb,
          $MetasTable,
          MetaRow,
          $$MetasTableFilterComposer,
          $$MetasTableOrderingComposer,
          $$MetasTableAnnotationComposer,
          $$MetasTableCreateCompanionBuilder,
          $$MetasTableUpdateCompanionBuilder,
          (MetaRow, BaseReferences<_$ContentDb, $MetasTable, MetaRow>),
          MetaRow,
          PrefetchHooks Function()
        > {
  $$MetasTableTableManager(_$ContentDb db, $MetasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetasCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => MetasCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MetasTable, MetaRow>(table),
                  BaseReferences<_$ContentDb, $MetasTable, MetaRow>(
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

typedef $$MetasTableProcessedTableManager =
    ProcessedTableManager<
      _$ContentDb,
      $MetasTable,
      MetaRow,
      $$MetasTableFilterComposer,
      $$MetasTableOrderingComposer,
      $$MetasTableAnnotationComposer,
      $$MetasTableCreateCompanionBuilder,
      $$MetasTableUpdateCompanionBuilder,
      (MetaRow, BaseReferences<_$ContentDb, $MetasTable, MetaRow>),
      MetaRow,
      PrefetchHooks Function()
    >;

class $ContentDbManager {
  final _$ContentDb _db;
  $ContentDbManager(this._db);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$BanisTableTableManager get banis =>
      $$BanisTableTableManager(_db, _db.banis);
  $$BaniVersionsTableTableManager get baniVersions =>
      $$BaniVersionsTableTableManager(_db, _db.baniVersions);
  $$LinesTableTableManager get lines =>
      $$LinesTableTableManager(_db, _db.lines);
  $$MeaningsTableTableManager get meanings =>
      $$MeaningsTableTableManager(_db, _db.meanings);
  $$VoicesTableTableManager get voices =>
      $$VoicesTableTableManager(_db, _db.voices);
  $$AudioTracksTableTableManager get audioTracks =>
      $$AudioTracksTableTableManager(_db, _db.audioTracks);
  $$TimingsTableTableManager get timings =>
      $$TimingsTableTableManager(_db, _db.timings);
  $$NanakshahiMonthsTableTableManager get nanakshahiMonths =>
      $$NanakshahiMonthsTableTableManager(_db, _db.nanakshahiMonths);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(_db, _db.calendarEvents);
  $$CitiesTableTableManager get cities =>
      $$CitiesTableTableManager(_db, _db.cities);
  $$QuotesTableTableManager get quotes =>
      $$QuotesTableTableManager(_db, _db.quotes);
  $$MetasTableTableManager get metas =>
      $$MetasTableTableManager(_db, _db.metas);
}
