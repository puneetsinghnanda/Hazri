import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/library/domain/library_entry.dart';

void main() {
  test('an entry from the API keeps the order of its facts', () {
    final e = LibraryEntry.fromJson({
      'id': 'harmandir',
      'title': ' Sri Harmandir Sahib ',
      'kind': 'gurdwara',
      'summary': 's',
      'body': 'b',
      'minutes': 4,
      'place': 'Amritsar',
      'facts': [
        {'label': 'Where', 'value': 'Amritsar'},
        {'label': 'Langar', 'value': 'Always'},
      ],
    })!;
    expect(e.title, 'Sri Harmandir Sahib');
    expect(e.kind, EntryKind.gurdwara);
    expect(e.facts.keys.toList(), ['Where', 'Langar']);
  });

  test('an entry without an id or a title is dropped, not shown blank', () {
    expect(LibraryEntry.fromJson({'title': 'x'}), isNull);
    expect(LibraryEntry.fromJson({'id': 'x', 'title': '  '}), isNull);
  });

  test('tags and dates come through; unknown tags and bad dates do not', () {
    final e = LibraryEntry.fromJson({
      'id': 'h',
      'title': 't',
      'kind': 'gurdwara',
      'tags': ['gurdwara', 'guru', 'article', 'zz'],
      'dates': ['2027-01-14', '2026-07-05', '14 Jan'],
    })!;
    expect(e.tags, {EntryKind.gurdwara, EntryKind.guru});
    expect(e.dates, ['2026-07-05', '2027-01-14']);
    expect(e.nextDate('2026-10-19'), '2027-01-14');
    expect(e.nextDate('2027-02-01'), isNull);
  });

  test('Sikh days lists every entry; another topic only what is tagged or of its kind', () {
    const tagged = LibraryEntry(id: 'a', kind: EntryKind.guru, title: 'a', tags: {EntryKind.guru, EntryKind.bani});
    const plain = LibraryEntry(id: 'b', kind: EntryKind.gurdwara, title: 'b');
    const article = LibraryEntry(id: 'c', kind: EntryKind.article, title: 'c');
    expect([tagged, plain, article].every((e) => e.listedUnder(EntryKind.day)), isTrue);
    expect(tagged.listedUnder(EntryKind.bani), isTrue);
    expect(tagged.listedUnder(EntryKind.gurdwara), isFalse);
    expect(plain.listedUnder(EntryKind.gurdwara), isTrue);
    expect(article.listedUnder(EntryKind.guru), isFalse);
  });

  test('an unknown kind reads as an article', () {
    expect(LibraryEntry.fromJson({'id': 'a', 'title': 't', 'kind': 'zz'})!.kind,
        EntryKind.article);
  });
}
