import 'package:notes_v0_2/id.dart';
import 'package:notes_v0_2/stream.dart';
import 'package:test/test.dart';

void main() {
  group('Stream', () {
    final idGen = IdGenerator(DeviceId(123));
    // Helper function to create a valid Id for testing
    Id createTestId(String scope) {
      return idGen.newId(scope);
    }

    test('creates named stream', () {
      final stream = Stream.named('test');
      expect(stream.name, equals('test'));
      expect(stream.id, isNull);
      expect(stream.isNamed, isTrue);
      expect(stream.isId, isFalse);
    });

    test('throws when named stream name is too long', () {
      expect(
        () => Stream.named('this_is_a_very_long_name'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('creates id stream', () {
      final id = createTestId('test');
      final stream = Stream.id(id);
      expect(stream.name, equals(id.toString()));
      expect(stream.id, equals(id));
      expect(stream.isNamed, isFalse);
      expect(stream.isId, isTrue);
    });

    group('fromString factory', () {
      test('creates named stream when no hyphen', () {
        final stream = Stream.fromString('test');
        expect(stream.isNamed, isTrue);
        expect(stream.name, equals('test'));
      });

      test('creates id stream when contains hyphen', () {
        final id = createTestId('test');
        final stream = Stream.fromString(id.toString());
        expect(stream.isId, isTrue);
        expect(stream.name, equals(id.toString()));
      });
    });

    group('isNamedWithName', () {
      test('returns true for matching named stream', () {
        final stream = Stream.named('test');
        expect(stream.isNamedWithName('test'), isTrue);
      });

      test('returns false for non-matching named stream', () {
        final stream = Stream.named('test');
        expect(stream.isNamedWithName('other'), isFalse);
      });

      test('returns false for id stream', () {
        final stream = Stream.id(createTestId('test'));
        expect(stream.isNamedWithName('test'), isFalse);
      });
    });

    group('throwIfNotNamedWithName', () {
      test('throws for id stream', () {
        final stream = Stream.id(createTestId('test'));
        expect(
          () => stream.throwIfNotNamedWithName('test'),
          throwsArgumentError,
        );
      });

      test('throws for non-matching named stream', () {
        final stream = Stream.named('test');
        expect(
          () => stream.throwIfNotNamedWithName('other'),
          throwsArgumentError,
        );
      });

      test('does not throw for matching named stream', () {
        final stream = Stream.named('test');
        expect(() => stream.throwIfNotNamedWithName('test'), returnsNormally);
      });
    });

    group('getIdInScope', () {
      test('returns id for matching scope', () {
        final id = createTestId('test');
        final stream = Stream.id(id);
        expect(stream.getIdInScope('test'), equals(id));
      });

      test('returns null for non-matching scope', () {
        final stream = Stream.id(createTestId('test'));
        expect(stream.getIdInScope('other'), isNull);
      });

      test('returns null for named stream', () {
        final stream = Stream.named('test');
        expect(stream.getIdInScope('test'), isNull);
      });
    });

    group('getIdInScopeOrThrow', () {
      test('returns id for matching scope', () {
        final id = createTestId('test');
        final stream = Stream.id(id);
        expect(stream.getIdInScopeOrThrow('test'), equals(id));
      });

      test('throws for non-matching scope', () {
        final stream = Stream.id(createTestId('test'));
        expect(() => stream.getIdInScopeOrThrow('other'), throwsArgumentError);
      });

      test('throws for named stream', () {
        final stream = Stream.named('test');
        expect(() => stream.getIdInScopeOrThrow('test'), throwsArgumentError);
      });
    });

    group('equality', () {
      test('same named streams are equal', () {
        final stream1 = Stream.named('test');
        final stream2 = Stream.named('test');
        expect(stream1, equals(stream2));
        expect(stream1.hashCode, equals(stream2.hashCode));
      });

      test('different named streams are not equal', () {
        final stream1 = Stream.named('test1');
        final stream2 = Stream.named('test2');
        expect(stream1, isNot(equals(stream2)));
      });

      test('same id streams are equal', () {
        final id = createTestId('test');
        final stream1 = Stream.id(id);
        final stream2 = Stream.id(id);
        expect(stream1, equals(stream2));
        expect(stream1.hashCode, equals(stream2.hashCode));
      });

      test('different id streams are not equal', () {
        final stream1 = Stream.id(createTestId('test'));
        final stream2 = Stream.id(createTestId('test')); // Different timestamp
        expect(stream1, isNot(equals(stream2)));
      });

      test('named and id streams are not equal', () {
        final stream1 = Stream.named('test');
        final stream2 = Stream.id(createTestId('test'));
        expect(stream1, isNot(equals(stream2)));
      });
    });
  });
}
