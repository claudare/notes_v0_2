import 'dart:convert';

import 'package:notes_v0_2/common/id.dart';
import 'package:test/test.dart';
import 'package:notes_v0_2/notes/model_ordering.dart';

void main() {
  final id1 = TestIdGenerator.newIdNumber(0);
  final id2 = TestIdGenerator.newIdNumber(1);
  final id3 = TestIdGenerator.newIdNumber(2);
  group('NoteOrdering', () {
    late NoteOrdering noteOrdering;

    setUp(() {
      noteOrdering = NoteOrdering();
    });

    test('appends', () {
      noteOrdering.append(id1, Category.main);
      expect(noteOrdering.main.single.id, equals(id1));
    });

    test('moves to other category', () {
      noteOrdering.append(id1, Category.main);
      noteOrdering.moveToOtherCategory(id1, Category.pinned);
      expect(noteOrdering.main.isEmpty, isTrue);
      expect(noteOrdering.pinned.single.id, equals(id1));
    });

    test('reorders', () {
      noteOrdering.append(id1, Category.main);
      noteOrdering.append(id2, Category.main);
      noteOrdering.append(id3, Category.main);

      expect(noteOrdering.main.length, equals(3));

      noteOrdering.rearrange(id2, id3);
      expect(noteOrdering.main.map((e) => e.id), equals([id1, id3, id2]));
    });

    test('removes', () {
      final id = id1;

      noteOrdering.append(id, Category.main);
      noteOrdering.remove(id);
      expect(noteOrdering.main.isEmpty, isTrue);
    });

    test('serialization', () {
      final jsonRaw = '''
        {
          "main": ["test-11111111111-111-111", "test-11111111111-111-112"],
          "pinned": []
        }
      ''';
      final jsonCompacted = jsonEncode(jsonDecode(jsonRaw));

      final map = jsonDecode(jsonCompacted);
      final jsonResult = jsonEncode(NoteOrdering.fromJson(map).toJson());

      expect(jsonCompacted, equals(jsonResult));
    });
  });
}
