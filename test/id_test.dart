import 'dart:typed_data';
import 'package:test/test.dart';

import 'package:notes_v0_2/id.dart';

// currently there are no base58 tests...
// but it works as all of this works

void main() {
  group('DeviceId', () {
    test('Should create DeviceId with valid value', () {
      final deviceId = DeviceUid(12345);
      expect(deviceId.value, equals(12345));
    });

    test('Should reject DeviceId with invalid value', () {
      expect(() => DeviceUid(-1), throwsArgumentError);
      expect(() => DeviceUid(70000), throwsArgumentError);
    });

    test('Should create DeviceId from string', () {
      final deviceId = DeviceUid.fromString('4fr');
      expect(deviceId.value, equals(12345));
    });

    test('Should convert DeviceId to string', () {
      final deviceId = DeviceUid(12345);
      expect(deviceId.toString(), equals('4fr'));
    });

    test('Should create random DeviceId within valid range', () {
      for (int i = 0; i < 100; i++) {
        final deviceId = DeviceUid.random();
        expect(deviceId.value, greaterThanOrEqualTo(0));
        expect(deviceId.value, lessThan(65536));
      }
    });

    test('Should implement equality correctly', () {
      final deviceId1 = DeviceUid(12345);
      final deviceId2 = DeviceUid(12345);
      final deviceId3 = DeviceUid(54321);

      expect(deviceId1 == deviceId2, isTrue);
      expect(deviceId1 == deviceId3, isFalse);
      expect(deviceId1.hashCode == deviceId2.hashCode, isTrue);
    });
  });

  group('Id', () {
    test('Should create Id from parts', () {
      final timestamp = 1678901234567;
      final deviceIdValue = 12345;
      final counter = 678;

      final id = Uid.fromParts(timestamp, deviceIdValue, counter);

      expect(
        id.getTimestamp(),
        equals(DateTime.fromMillisecondsSinceEpoch(timestamp)),
      );
      expect(id.getDeviceId().value, equals(deviceIdValue));
      expect(id.getCounter(), equals(counter));
    });

    test('Should convert Id to string and back', () {
      final timestamp = 1678901234567;
      final deviceIdValue = 12345;
      final counter = 678;

      final id = Uid.fromParts(timestamp, deviceIdValue, counter);
      final idStr = id.toString();
      final idFromStr = Uid.fromString(idStr);

      expect(idFromStr.getTimestamp(), equals(id.getTimestamp()));
      expect(idFromStr.getDeviceId().value, equals(id.getDeviceId().value));
      expect(idFromStr.getCounter(), equals(id.getCounter()));
    });

    test('Should reject invalid byte length', () {
      expect(() => Uid(Uint8List(10)), throwsArgumentError);
    });

    test('Should reject invalid string format', () {
      expect(() => Uid.fromString('invalid'), throwsFormatException);
      expect(() => Uid.fromString('part1-part2'), throwsFormatException);
      expect(
        () => Uid.fromString('part1-part2-part3-part4'),
        throwsFormatException,
      );
    });

    test('Should implement equality correctly', () {
      final id1 = Uid.fromParts(1678901234567, 12345, 678);
      final id2 = Uid.fromParts(1678901234567, 12345, 678);
      final id3 = Uid.fromParts(1678901234567, 12345, 679);

      expect(id1 == id2, isTrue);
      expect(id1 == id3, isFalse);
      expect(id1.hashCode == id2.hashCode, isTrue);
    });

    test('Should implement Comparable properly', () {
      final id1 = Uid.fromParts(1678901234567, 12345, 678);
      // device Id is a tiebreaker, this is intentional!
      final id2 = Uid.fromParts(1678901234900, 20000, 678);
      final id3 = Uid.fromParts(1678901234900, 12345, 678);

      expect(id1.compareTo(id2), equals(-1));
      expect(id2.compareTo(id3), equals(1));
      expect(id1.compareTo(id1), equals(0));
    });
  });

  group('IdGenerator', () {
    test('Should generate unique IDs', () {
      final generator = UidGenerator(DeviceUid(12345));
      final ids = <Uid>{};

      // Generate multiple IDs and ensure they're all unique
      for (int i = 0; i < 100; i++) {
        final id = generator.newUId();
        expect(ids.contains(id), isFalse);
        ids.add(id);
      }
    });

    test('Should generate IDs with correct device ID', () {
      final deviceId = DeviceUid(54321);
      final generator = UidGenerator(deviceId);

      for (int i = 0; i < 10; i++) {
        final id = generator.newUId();
        expect(id.getDeviceId(), equals(deviceId));
      }
    });

    test('Should increment counter correctly', () {
      final generator = UidGenerator(DeviceUid(12345), counter: 100);

      expect(generator.counter, equals(100));
      final id1 = generator.newUId();
      expect(id1.getCounter(), equals(100));
      expect(generator.counter, equals(101));

      final id2 = generator.newUId();
      expect(id2.getCounter(), equals(101));
      expect(generator.counter, equals(102));
    });

    test('Should wrap counter correctly', () {
      final generator = UidGenerator(DeviceUid(12345), counter: 65536 - 2);

      final id1 = generator.newUId();
      expect(id1.getCounter(), equals(65536 - 2));

      final id2 = generator.newUId();
      expect(id2.getCounter(), equals(65536 - 1));

      final id3 = generator.newUId();
      expect(id3.getCounter(), equals(0));
    });

    test('Should reject invalid counter values', () {
      expect(
        () => UidGenerator(DeviceUid(12345), counter: -1),
        throwsArgumentError,
      );
      expect(
        () => UidGenerator(DeviceUid(12345), counter: 70000),
        throwsArgumentError,
      );

      final generator = UidGenerator(DeviceUid(12345));
      expect(() => generator.counter = -1, throwsArgumentError);
      expect(() => generator.counter = 70000, throwsArgumentError);
    });
  });

  group('End-to-end tests', () {
    test('Should create and parse ID across different instances', () {
      // Generate an ID
      final generator = UidGenerator(DeviceUid(12345));
      final id = generator.newUId();
      final idStr = id.toString();

      // Parse it back in a different context
      final parsedId = Uid.fromString(idStr);

      // Verify all components match
      expect(parsedId.getTimestamp(), equals(id.getTimestamp()));
      expect(parsedId.getDeviceId().value, equals(id.getDeviceId().value));
      expect(parsedId.getCounter(), equals(id.getCounter()));
    });

    test('Should generate unique IDs across different generators', () {
      // Create multiple generators with different device IDs
      final generator1 = UidGenerator(DeviceUid(1), counter: 10);
      final generator2 = UidGenerator(DeviceUid(2), counter: 10);

      // Generate IDs from each
      final id1 = generator1.newUId();
      final id2 = generator2.newUId();

      // Verify they're all different
      expect(id1 == id2, isFalse);

      // Check their device IDs match what we expect
      expect(id1.getDeviceId().value, equals(1));
      expect(id2.getDeviceId().value, equals(2));
    });

    test('Should handle stress test with many IDs', () {
      final generator = UidGenerator(DeviceUid.random());
      final idSet = <String>{};

      // Generate a large number of IDs and check for duplicates
      for (int i = 0; i < 10000; i++) {
        final id = generator.newUId();
        final idStr = id.toString();
        expect(idSet.contains(idStr), isFalse);
        idSet.add(idStr);
      }
    });

    test('Should generate ID with predictable format', () {
      final timestamp = 1678901234567;
      final deviceIdValue = 12345;
      final counter = 678;

      // Mock the current time for predictable test
      // In a real implementation, you'd use a clock abstraction that can be mocked
      final id = Uid.fromParts(timestamp, deviceIdValue, counter);
      final idStr = id.toString();
      expect(idStr.length, equals(19));

      // Verify string format (specific values will depend on Base58 encoding)
      final parts = idStr.split('-');
      expect(parts.length, equals(3));

      // Check lengths of components
      expect(parts[0].length, equals(11));
      expect(parts[1].length, equals(3));
      expect(parts[2].length, equals(3));
    });
  });

  // skipped as its kinda useless
  group('Performance tests', () {
    test('Should generate IDs quickly', () {
      final generator = UidGenerator(DeviceUid.random());
      final count = 100000;

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < count; i++) {
        generator.newUId();
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
