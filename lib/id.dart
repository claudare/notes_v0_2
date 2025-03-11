import 'dart:math';
import 'dart:typed_data';

class Sequence {
  int value;

  Sequence(this.value) {
    // assert(value < 1, "sequences must start at 1");
    if (value < 0) {
      throw ArgumentError("sequences must be positive");
    }
  }

  int next() {
    value += 1;
    return value;
  }
}

/// I dont think this should be used
@Deprecated("dont use")
class StreamId {
  String name;
  Uid id;

  StreamId(this.name, this.id) {
    // TODO: only ascci allowed!
    if (name.length > 4) {
      throw ArgumentError("stream name cannot be longer then 4");
    }

    // pad it to correct length
    name.padRight(4, '_');
  }

  // is this really needed?
  Uint8List getBytes() {
    final bytes = Uint8List(16);
    for (var i = 0; i < 4; i++) {
      bytes[i] = name.codeUnitAt(i);
    }
    for (var i = 4; i < 16; i++) {
      bytes[i] = id.bytes[i - 4];
    }
    return bytes;
  }

  @override
  String toString() {
    final idStr = id.toString();
    return "$name-$idStr";
  }
}

/// id is globally unique lexicographically sortable id
/// binary length is 12
/// text length is 19
/// i need to add a prefix. if 4 bytes then
/// binary length is 16 and text length is 24 nice.
/// but where does it go?
/// 1) $ts-$dev-$pre-$count
/// this is globally unique things in order, but then pre has very little meaning
/// 2) $pre-$ts-$dev-$count
/// this removes global uniqueness, but groups things by the stream name
/// 4 characters is really short though, but $ts-$dev-$count is a unique value
class Uid implements Comparable<Uid> {
  Uint8List bytes;

  Uid(this.bytes) {
    if (bytes.length != 12) {
      throw ArgumentError('ID must be exactly 12 bytes');
    }
  }

  Uid.fromString(String id) : bytes = Uint8List(12) {
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
  Uid.fromParts(int timestamp, int deviceId, int counter)
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
  DeviceUid getDeviceId() {
    final view = ByteData.view(bytes.buffer);
    final deviceIdNum = view.getUint16(8);
    return DeviceUid(deviceIdNum);
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
    if (other is! Uid) return false;

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
  int compareTo(Uid other) {
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

class DeviceUid {
  final int value; // hmmm, its not bytes

  DeviceUid(this.value) {
    if (value < 0 || value >= _maxDeviceIdValue) {
      throw ArgumentError(
        'Device ID must be between 0 and ${_maxDeviceIdValue - 1}',
      );
    }
  }

  /// Creates a DeviceId from its Base58 string representation
  DeviceUid.fromString(String valueStr) : value = _fromBase58(valueStr) {
    if (value >= _maxDeviceIdValue) {
      throw FormatException('Device ID value exceeds maximum allowed value');
    }
  }

  /// Creates a DeviceId with a random value
  DeviceUid.random() : value = Random.secure().nextInt(_maxDeviceIdValue);

  /// Converts the DeviceUid to its Base58 string representation
  @override
  String toString() => _toBase58(value, _deviceIdSize);

  /// Equality operator to compare two DeviceIds
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DeviceUid) return false;
    return value == other.value;
  }

  /// Hash code implementation for using DeviceId in collections
  @override
  int get hashCode => value.hashCode;
}

class UidGenerator {
  final DeviceUid deviceId;
  int _counter = 0;

  /// Creates an IdGenerator with the specified device ID and optional counter start value
  UidGenerator(this.deviceId, {int counter = 0}) : _counter = counter {
    // If no counter provided, start with a random value to reduce collision potential
    if (counter == 0) {
      _counter = Random.secure().nextInt(_maxCounterValue);
    } else if (counter < 0 || counter >= _maxCounterValue) {
      throw ArgumentError(
        'Counter must be between 0 and ${_maxCounterValue - 1}',
      );
    }
  }

  Uid newUId() {
    // Get current timestamp in milliseconds
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final currentCount = _getAndIncrementCounter();
    return Uid.fromParts(timestamp, deviceId.value, currentCount);
  }

  /// Increment counter and store the new value
  int _getAndIncrementCounter() {
    int current = _counter;
    _counter = (_counter + 1) % _maxCounterValue;
    return current;
  }

  /// Returns the current counter value
  int get counter => _counter;

  /// Sets the counter to a specific value
  set counter(int value) {
    if (value < 0 || value >= _maxCounterValue) {
      throw ArgumentError(
        'Counter must be between 0 and ${_maxCounterValue - 1}',
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
