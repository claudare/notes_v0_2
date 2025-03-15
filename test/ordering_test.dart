import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/common/ordering.dart';
import 'package:test/test.dart';

void main() {
  group('ordering', () {
    final id1 = TestIdGenerator.newIdNumber(0);
    final id2 = TestIdGenerator.newIdNumber(1);
    final id3 = TestIdGenerator.newIdNumber(2);
    final id4 = TestIdGenerator.newIdNumber(3);

    late Ordering<Id> ordering;
    setUp(() {
      ordering =
          Ordering()
            ..append(id1)
            ..append(id2)
            ..append(id3);
    });

    tearDown(() async {
      ordering.clear();
    });

    //
    test('append', () {
      final list = ordering.toListDesc();
      expect(list, equals([id3, id2, id1]));
      expect(ordering.count, equals(3));
    });

    test('remove', () {
      ordering.remove(id2);

      final list = ordering.toListDesc();
      expect(list, equals([id3, id1]));
      expect(ordering.count, equals(2));
    });
    test('remove first', () {
      ordering.remove(id1);

      final list = ordering.toListDesc();
      expect(list, equals([id3, id2]));
      expect(ordering.count, equals(2));
    });
    test('remove last', () {
      ordering.remove(id3);

      final list = ordering.toListDesc();
      expect(list, equals([id2, id1]));
      expect(ordering.count, equals(2));
    });
    test('remove till empty', () {
      ordering.remove(id3);
      ordering.remove(id2);
      ordering.remove(id1);

      final list = ordering.toListDesc();
      expect(list, equals([]));
      expect(ordering.count, equals(0));

      ordering.append(id4);
      expect(ordering.toListDesc(), equals([id4]));
    });

    test('insert', () {
      ordering.insert(id4, id2);

      final list = ordering.toListDesc();
      expect(list, equals([id3, id4, id2, id1]));
      expect(ordering.count, equals(4));
    });
    test('insert first', () {
      ordering.insert(id4, null);

      final list = ordering.toListDesc();
      expect(list, equals([id3, id2, id1, id4]));
      expect(ordering.count, equals(4));
    });
    test('insert last (append)', () {
      ordering.insert(id4, id3);

      final list = ordering.toListDesc();
      expect(list, equals([id4, id3, id2, id1]));
      expect(ordering.count, equals(4));
    });
    test('insert from empty', () {
      final fresh = Ordering();
      fresh.insert(id1, null);
      fresh.insert(id2, id1);

      final list = fresh.toListDesc();
      expect(list, equals([id2, id1]));
      expect(fresh.count, equals(2));
    });

    test('move', () {
      ordering.append(id4);
      ordering.move(id2, id3);

      final list = ordering.toListDesc();
      expect(list, equals([id4, id2, id3, id1]));
      expect(ordering.count, equals(4));
    });
    test('move inplace prohibited', () {
      expect(() => ordering.move(id2, id2), throwsArgumentError);
    });

    test('getAtIndex', () {
      final node = ordering.getAtIndex(1);
      expect(node.id, equals(id2));

      expect(() => ordering.getAtIndex(4), throwsRangeError);
    });
    test('getLast', () {
      final node = ordering.getLast();
      expect(node.id, equals(id1));
    });
  });
}
