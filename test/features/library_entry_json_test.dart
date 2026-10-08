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

  test('an unknown kind reads as an article', () {
    expect(LibraryEntry.fromJson({'id': 'a', 'title': 't', 'kind': 'zz'})!.kind,
        EntryKind.article);
  });
}
