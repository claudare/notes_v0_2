import 'dart:math';
import 'dart:typed_data';

class Id implements Comparable<Id> {
  Uint8List bytes;

  Id(this.bytes) {
    if (bytes.length != 12) {
      throw ArgumentError('ID must be exactly 12 bytes');
    }
  }

  Id.fromString(String id) : bytes = Uint8List(12) {
    final parts = id.split('-');
    if (parts.length != 3) {
      throw FormatException("Invalid ID format");
    }

    // Convert components back to integers
    final timestamp = _fromBase58(parts[0]);
    final deviceIdNum = _fromBase58(parts[1]);
    final counter = _fromBase58(parts[2]);

    // Set the values in the byte buffer
    final view = ByteData.view(bytes.buffer);
    view.setUint64(0, timestamp); // 8 bytes for timestamp
    view.setUint16(8, deviceIdNum); // 2 bytes for device ID
    view.setUint16(10, counter); // 2 bytes for counter
  }

  /// Creates a new Id from individual timestamp, device ID, and counter values
  Id.fromParts(int timestamp, int deviceId, int counter)
    : bytes = Uint8List(12) {
    final view = ByteData.view(bytes.buffer);
    view.setUint64(0, timestamp); // 8 bytes for timestamp
    view.setUint16(8, deviceId); // 2 bytes for device ID
    view.setUint16(10, counter); // 2 bytes for counter
  }

  /// Returns the timestamp component as a DateTime object
  DateTime getTimestamp() {
    final view = ByteData.view(bytes.buffer);
    final timestampMs = view.getUint64(0);
    return DateTime.fromMillisecondsSinceEpoch(timestampMs);
  }

  /// Returns the device ID component
  DeviceId getDeviceId() {
    final view = ByteData.view(bytes.buffer);
    final deviceIdNum = view.getUint16(8);
    return DeviceId(deviceIdNum);
  }

  /// Returns the counter component
  int getCounter() {
    final view = ByteData.view(bytes.buffer);
    return view.getUint16(10);
  }

  @override
  String toString() {
    final view = ByteData.view(bytes.buffer);
    final timestamp = view.getUint64(0); // 8 bytes for timestamp
    final deviceIdNum = view.getUint16(8); // 2 bytes for device ID
    final counter = view.getUint16(10); // 2 bytes for counter

    final timestampStr = _toBase58(timestamp, _timestampSize);
    final deviceIdStr = _toBase58(deviceIdNum, _deviceIdSize);
    final counterStr = _toBase58(counter, _counterSize);

    return "$timestampStr-$deviceIdStr-$counterStr";
  }

  /// Equality operator to compare two IDs
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Id) return false;

    for (int i = 0; i < 12; i++) {
      if (bytes[i] != other.bytes[i]) return false;
    }
    return true;
  }

  /// Hash code implementation for using Id in collections
  /// TODO: check me
  @override
  int get hashCode {
    int result = 17;
    for (int i = 0; i < bytes.length; i++) {
      result = 37 * result + bytes[i];
    }
    return result;
  }

  @override
  int compareTo(Id other) {
    for (int i = 0; i < 12; i++) {
      final self = bytes[i];
      final that = other.bytes[i];
      if (self > that) {
        return 1;
      } else if (self < that) {
        return -1;
      }
    }
    return 0;
  }
}

class DeviceId {
  final int value; // hmmm

  DeviceId(this.value) {
    if (value < 0 || value >= _maxCounterValue) {
      throw ArgumentError(
        'Device ID must be between 0 and ${_maxCounterValue - 1}',
      );
    }
  }

  /// Creates a DeviceId from its Base58 string representation
  DeviceId.fromString(String valueStr) : value = _fromBase58(valueStr) {
    if (value >= _maxCounterValue) {
      throw FormatException('Device ID value exceeds maximum allowed value');
    }
  }

  /// Creates a DeviceId with a random value
  DeviceId.random() : value = Random.secure().nextInt(_maxCounterValue);

  /// Converts the DeviceId to its Base58 string representation
  @override
  String toString() => _toBase58(value, _deviceIdSize);

  /// Equality operator to compare two DeviceIds
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DeviceId) return false;
    return value == other.value;
  }

  /// Hash code implementation for using DeviceId in collections
  @override
  int get hashCode => value.hashCode;
}

class IdGenerator {
  final DeviceId deviceId;
  int _counter = 0;

  /// Creates an IdGenerator with the specified device ID and optional counter start value
  IdGenerator(this.deviceId, {int counter = 0}) : _counter = counter {
    // If no counter provided, start with a random value to reduce collision potential
    if (counter == 0) {
      _counter = Random.secure().nextInt(_maxDeviceIdValue);
    } else if (counter < 0 || counter >= _maxDeviceIdValue) {
      throw ArgumentError(
        'Counter must be between 0 and ${_maxDeviceIdValue - 1}',
      );
    }
  }

  Id newId() {
    // Get current timestamp in milliseconds
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final currentCount = _getAndIncrementCounter();
    return Id.fromParts(timestamp, deviceId.value, currentCount);
  }

  /// Increment counter and store the new value
  int _getAndIncrementCounter() {
    int current = _counter;
    _counter = (_counter + 1) % _maxDeviceIdValue;
    return current;
  }

  /// Returns the current counter value
  int get counter => _counter;

  /// Sets the counter to a specific value
  set counter(int value) {
    if (value < 0 || value >= _maxDeviceIdValue) {
      throw ArgumentError(
        'Counter must be between 0 and ${_maxDeviceIdValue - 1}',
      );
    }
    _counter = value;
  }
}

// Constants for Base58 encoding
const String _base58Chars =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
const int _base58Radix = 58;

const int _timestampSize =
    11; // u64 value, valid until 292,277,026,596 AD, at 20:10:55 UTC
const int _deviceIdSize = 3; // Can represent 58³ = 195,112 devices
const int _counterSize = 3; // Can handle up to 195,112 IDs per millisecond

// Maximum values for device ID and counter components (2^16)
const int _maxDeviceIdValue = 65536; // u16
const int _maxCounterValue = 65536;

/// Converts a number to a Base58 string with fixed length
String _toBase58(int number, int length) {
  if (number < 0) {
    throw ArgumentError('Number must be non-negative');
  }

  // Handle zero case
  if (number == 0) {
    return '1'.padLeft(length, '1'); // '1' is the zero character in Base58
  }

  // Convert to Base58
  String result = '';
  int remaining = number;

  while (remaining > 0) {
    result = _base58Chars[remaining % _base58Radix] + result;
    remaining = remaining ~/ _base58Radix;
  }

  // Pad with leading '1' (the zero character in Base58) to ensure fixed length
  return result.padLeft(length, '1');
}

/// Parses a Base58 string back to an integer
int _fromBase58(String str) {
  int result = 0;

  for (int i = 0; i < str.length; i++) {
    final char = str[i];
    final value = _base58Chars.indexOf(char);
    if (value == -1) {
      throw FormatException('Invalid Base58 character: $char');
    }
    result = result * _base58Radix + value;
  }

  return result;
}
