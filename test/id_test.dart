import 'dart:typed_data';
import 'package:test/test.dart';

import 'package:notes_v0_2/id.dart';

// currently there are no base58 tests...
// but it works as all of this works

void main() {
  group('DeviceId', () {
    test('Should create DeviceId with valid value', () {
      final deviceId = DeviceId(12345);
      expect(deviceId.value, equals(12345));
    });

    test('Should reject DeviceId with invalid value', () {
      expect(() => DeviceId(-1), throwsA(isA<AssertionError>()));
      expect(() => DeviceId(70000), throwsA(isA<AssertionError>()));
    });

    test('Should create DeviceId from string', () {
      final deviceId = DeviceId.fromString('4fr');
      expect(deviceId.value, equals(12345));
    });

    test('Should convert DeviceId to string', () {
      final deviceId = DeviceId(12345);
      expect(deviceId.toString(), equals('4fr'));
    });

    test('Should create random DeviceId within valid range', () {
      for (int i = 0; i < 100; i++) {
        final deviceId = DeviceId.random();
        expect(deviceId.value, greaterThanOrEqualTo(0));
        expect(deviceId.value, lessThan(65536));
      }
    });

    test('Should implement equality correctly', () {
      final deviceId1 = DeviceId(12345);
      final deviceId2 = DeviceId(12345);
      final deviceId3 = DeviceId(54321);

      expect(deviceId1 == deviceId2, isTrue);
      expect(deviceId1 == deviceId3, isFalse);
      expect(deviceId1.hashCode == deviceId2.hashCode, isTrue);
    });
  });

  group('Id', () {
    test('Should create Id from parts', () {
      final scope = 'test';
      final timestamp = 1678901234567;
      final deviceIdValue = 12345;
      final counter = 678;

      final id = Id.fromParts(scope, timestamp, deviceIdValue, counter);

      expect(
        id.getTimestamp(),
        equals(DateTime.fromMillisecondsSinceEpoch(timestamp)),
      );
      expect(id.getDeviceId().value, equals(deviceIdValue));
      expect(id.getCounter(), equals(counter));
    });

    test('Should convert Id to string and back', () {
      final scope = 'test';
      final timestamp = 1678901234567;
      final deviceIdValue = 12345;
      final counter = 678;

      final id = Id.fromParts(scope, timestamp, deviceIdValue, counter);
      final idStr = id.toString();
      final idFromStr = Id.fromString(idStr);

      expect(idFromStr.getTimestamp(), equals(id.getTimestamp()));
      expect(idFromStr.getDeviceId().value, equals(id.getDeviceId().value));
      expect(idFromStr.getCounter(), equals(id.getCounter()));
    });

    test('Should reject invalid byte length', () {
      expect(() {
        Id(Uint8List(10));
      }, throwsA(isA<AssertionError>()));
    });

    test('Should reject invalid string format', () {
      // Test empty string
      expect(() => Id.fromString(''), throwsFormatException);

      // Test invalid number of parts
      expect(() => Id.fromString('test'), throwsFormatException);
      expect(() => Id.fromString('test-part2'), throwsFormatException);
      expect(() => Id.fromString('test-part2-part3'), throwsFormatException);
      expect(
        () => Id.fromString('test-part2-part3-part4-part5'),
        throwsFormatException,
      );

      // Test scope length validation (max 4 chars)
      expect(
        () => Id.fromString('toolong-11111111111-111-111'),
        throwsFormatException,
        reason: 'Scope longer than 4 characters should be rejected',
      );

      // Test empty scope
      expect(
        () => Id.fromString('-11111111111-111-111'),
        throwsFormatException,
        reason: 'Empty scope should be rejected',
      );

      // TODO?
      // Test invalid characters in scope (should only allow ASCII)
      // expect(
      //   () => Id.fromString('tèst-11111111111-111-111'),
      //   throwsFormatException,
      //   reason: 'Non-ASCII characters in scope should be rejected',
      // );

      // Test invalid base58 characters in components
      expect(
        () => Id.fromString(
          'test-0000000000O-111-111',
        ), // 'O' is not valid base58
        throwsFormatException,
        reason: 'Invalid base58 characters should be rejected',
      );

      // Test invalid lengths for timestamp, device, and counter components
      expect(
        () => Id.fromString('test-1111-111-111'), // timestamp too short
        throwsFormatException,
        reason: 'Timestamp component should be 11 characters',
      );

      expect(
        () => Id.fromString('test-11111111111-1-111'), // device id too short
        throwsFormatException,
        reason: 'Device ID component should be 3 characters',
      );

      expect(
        () => Id.fromString('test-11111111111-111-1'), // counter too short
        throwsFormatException,
        reason: 'Counter component should be 3 characters',
      );
    });

    test('Should implement equality correctly', () {
      final id1 = Id.fromParts('eq', 1678901234567, 12345, 678);
      final id2 = Id.fromParts('eq', 1678901234567, 12345, 678);
      final id3 = Id.fromParts('eq', 1678901234567, 12345, 679);

      expect(id1 == id2, isTrue);
      expect(id1 == id3, isFalse);
      expect(id1.hashCode == id2.hashCode, isTrue);
    });

    test('Should implement Comparable properly', () {
      final id1 = Id.fromParts('eq', 1678901234567, 12345, 678);
      // device Id is a tiebreaker, this is intentional!
      final id2 = Id.fromParts('eq', 1678901234900, 20000, 678);
      final id3 = Id.fromParts('eq', 1678901234900, 12345, 678);

      expect(id1.compareTo(id2), equals(-1));
      expect(id2.compareTo(id3), equals(1));
      expect(id1.compareTo(id1), equals(0));
    });
  });

  group('IdGenerator', () {
    test('Should generate unique IDs', () {
      final generator = IdGenerator(DeviceId(12345));
      final ids = <Id>{};

      // Generate multiple IDs and ensure they're all unique
      for (int i = 0; i < 100; i++) {
        final id = generator.newUId('test');
        expect(ids.contains(id), isFalse);
        ids.add(id);
      }
    });

    test('Should generate IDs with correct device ID', () {
      final deviceId = DeviceId(54321);
      final generator = IdGenerator(deviceId);

      for (int i = 0; i < 10; i++) {
        final id = generator.newUId('test');
        expect(id.getDeviceId(), equals(deviceId));
      }
    });

    test('Should increment counter correctly', () {
      final generator = IdGenerator(DeviceId(12345), counter: 100);

      expect(generator.counter, equals(100));
      final id1 = generator.newUId('test');
      expect(id1.getCounter(), equals(100));
      expect(generator.counter, equals(101));

      final id2 = generator.newUId('test');
      expect(id2.getCounter(), equals(101));
      expect(generator.counter, equals(102));
    });

    test('Should wrap counter correctly', () {
      final generator = IdGenerator(DeviceId(12345), counter: 65535 - 2);

      final id1 = generator.newUId('test');
      expect(id1.getCounter(), equals(65535 - 2));

      final id2 = generator.newUId('test');
      expect(id2.getCounter(), equals(65535 - 1));

      final id3 = generator.newUId('test');
      expect(id3.getCounter(), equals(0));
    });

    test('Should reject invalid counter values', () {
      expect(
        () => IdGenerator(DeviceId(12345), counter: -1),
        throwsArgumentError,
      );
      expect(
        () => IdGenerator(DeviceId(12345), counter: 70000),
        throwsArgumentError,
      );

      final generator = IdGenerator(DeviceId(12345));
      expect(() => generator.counter = -1, throwsArgumentError);
      expect(() => generator.counter = 70000, throwsArgumentError);
    });
  });

  group('End-to-end tests', () {
    test('Should create and parse ID across different instances', () {
      // Generate an ID
      final generator = IdGenerator(DeviceId(12345));
      final id = generator.newUId('test');
      final idStr = id.toString();

      // Parse it back in a different context
      final parsedId = Id.fromString(idStr);

      // Verify all components match
      expect(parsedId.getTimestamp(), equals(id.getTimestamp()));
      expect(parsedId.getDeviceId().value, equals(id.getDeviceId().value));
      expect(parsedId.getCounter(), equals(id.getCounter()));
    });

    test('Should generate unique IDs across different generators', () {
      // Create multiple generators with different device IDs
      final generator1 = IdGenerator(DeviceId(1), counter: 10);
      final generator2 = IdGenerator(DeviceId(2), counter: 10);

      // Generate IDs from each
      final id1 = generator1.newUId('test');
      final id2 = generator2.newUId('test');

      // Verify they're all different
      expect(id1 == id2, isFalse);

      // Check their device IDs match what we expect
      expect(id1.getDeviceId().value, equals(1));
      expect(id2.getDeviceId().value, equals(2));
    });

    test('Should handle stress test with many IDs', () {
      final generator = IdGenerator(DeviceId.random());
      final idSet = <String>{};

      // Generate a large number of IDs and check for duplicates
      for (int i = 0; i < 10000; i++) {
        final id = generator.newUId('test');
        final idStr = id.toString();
        expect(idSet.contains(idStr), isFalse);
        idSet.add(idStr);
      }
    });

    test('Should generate ID with predictable format', () {
      final scope = 'fmt';
      final timestamp = 1678901234567;
      final deviceIdValue = 12345;
      final counter = 678;

      // Mock the current time for predictable test
      // In a real implementation, you'd use a clock abstraction that can be mocked
      final id = Id.fromParts(scope, timestamp, deviceIdValue, counter);
      final idStr = id.toString();
      expect(idStr.length, equals(23)); // as fmt is used

      // Verify string format (specific values will depend on Base58 encoding)
      final parts = idStr.split('-');
      expect(parts.length, equals(4));

      // Check lengths of components
      expect(parts[0].length, equals(3));
      expect(parts[1].length, equals(11));
      expect(parts[2].length, equals(3));
      expect(parts[3].length, equals(3));
    });
  });

  // skipped as its kinda useless
  group('Performance tests', () {
    test('Should generate IDs quickly', () {
      final generator = IdGenerator(DeviceId.random());
      final count = 100000;

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < count; i++) {
        generator.newUId('test');
      }
      stopwatch.stop();

      final timePerIdMicros = stopwatch.elapsedMicroseconds / count;
      print(
        'Generated $count IDs in ${stopwatch.elapsedMilliseconds}ms '
        '(${timePerIdMicros.toStringAsFixed(2)}μs per ID)',
      );

      expect(timePerIdMicros < 50, isTrue);
    });
  }, skip: true);
}
