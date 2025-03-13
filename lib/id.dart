import 'dart:math';
import 'dart:typed_data';

// anything named "id" is the unique id defined in this file
// "seq" denotes an autogrowing sequence. 0 -> infinity
// "aid" denotes autoincrementing ids not related to sequences

/// ids are unique lexicographically sortable id
/// they are scoped by a human-readable prefix that is upto 4 bytes long
/// binary length is 16
/// text length is 24
class Id implements Comparable<Id> {
  static const _binLen = 16;
  static const _strLen = 24;

  static const _binLenScope = 4;
  static const _binLenTimestamp = 8;
  static const _binLenDevice = 2;
  // ignore: unused_field
  static const _binLenCounter = 2;

  // timestamp is valid until 292,277,026,596 AD, at 20:10:55 UTC
  static const _strLenTimestamp = 11;
  // Can represent 58³-1 = 195,111 devices
  static const _strLenDevice = 3;
  // Can handle up to 195,111 IDs per millisecond
  static const _strLenCounter = 3;

  final Uint8List bytes;

  const Id(this.bytes)
    : assert(
        bytes.length == _binLen,
        'id must be $_binLen bytes long, got ${bytes.length} instead',
      );

  // im gonna keep this as is now
  factory Id.fromString(String id) {
    if (id.length > _strLen || id.length < _strLen - 3) {
      throw FormatException('Invalid ID length');
    }

    const dashAscii = 0x2D;

    // Find first dash (scope separator)
    int firstDash = -1;
    for (int i = 1; i <= _binLenScope; i++) {
      if (id.codeUnitAt(i) == dashAscii) {
        firstDash = i;
        break;
      }
    }
    if (firstDash == -1) {
      throw FormatException('Invalid ID format');
    }

    // Calculate expected positions of other dashes
    final secondDash = firstDash + _strLenTimestamp + 1;
    final thirdDash = secondDash + _strLenDevice + 1;
    final totalLength = thirdDash + _strLenCounter + 1;

    // Verify dash positions and final length
    if (secondDash >= id.length ||
        thirdDash >= id.length ||
        id.codeUnitAt(secondDash) != dashAscii ||
        id.codeUnitAt(thirdDash) != dashAscii ||
        id.length != totalLength) {
      throw FormatException('Invalid ID format');
    }

    // Extract components
    final scope = id.substring(0, firstDash);
    if (scope.isEmpty) {
      throw FormatException('Invalid ID format');
    }

    final timestampStr = id.substring(firstDash + 1, secondDash);
    final timestamp = _fromBase58(timestampStr);

    final deviceStr = id.substring(secondDash + 1, thirdDash);
    final device = _fromBase58(deviceStr);

    final counterStr = id.substring(thirdDash + 1);
    final counter = _fromBase58(counterStr);

    return Id.fromParts(scope, timestamp, device, counter);
  }

  /// Creates a new Id from individual timestamp, device, and counter values
  Id.fromParts(String scope, int timestamp, int device, int counter)
    : bytes = Uint8List(_binLen),
      assert(
        scope.isNotEmpty && scope.length <= 4,
        'scope must be 32 bits, got ${scope.length.bitLength} bits of $scope instead',
      ),
      assert(
        timestamp >= 0,
        'timestamp must be 64 bits, got nagative value of $timestamp instead',
      ),
      assert(
        device >= 0 && device <= _maxDeviceIdValue,
        'device must be 16 bits, got value of $device instead',
      ),
      assert(
        counter >= 0 && counter <= _maxCounterValue,
        'counter must be 16 bits, got value of $counter instead',
      ) {
    final view = ByteData.view(bytes.buffer);
    for (int i = 0; i < scope.length; i++) {
      bytes[i] = scope.codeUnitAt(i);
      // the rest are initial zero
    }
    view.setUint64(_binLenScope, timestamp);
    view.setUint16(_binLenScope + _binLenTimestamp, device);
    view.setUint16(_binLenScope + _binLenTimestamp + _binLenDevice, counter);
  }

  /// Returns the scope component as String
  String getScope() {
    final chars = <int>[];
    for (int i = 0; i < _binLenScope; i++) {
      final byte = bytes[i];
      if (byte == 0) break;
      chars.add(byte);
    }
    return String.fromCharCodes(chars);
  }

  /// Returns the timestamp component as a DateTime object
  DateTime getTimestamp() {
    final view = ByteData.view(bytes.buffer);
    final timestampMs = view.getUint64(_binLenScope);
    return DateTime.fromMillisecondsSinceEpoch(timestampMs);
  }

  /// Returns the device component as DeviceId
  DeviceId getDeviceId() {
    final view = ByteData.view(bytes.buffer);
    final deviceNum = view.getUint16(_binLenScope + _binLenTimestamp);
    return DeviceId(deviceNum);
  }

  /// Returns the counter component as int
  int getCounter() {
    final view = ByteData.view(bytes.buffer);
    return view.getUint16(_binLenScope + _binLenTimestamp + _binLenDevice);
  }

  @override
  String toString() {
    final view = ByteData.view(bytes.buffer);

    final timestamp = view.getUint64(_binLenScope);
    final deviceIdNum = view.getUint16(_binLenScope + _binLenTimestamp);
    final counter = view.getUint16(
      _binLenScope + _binLenTimestamp + _binLenDevice,
    );

    final scopeStr = getScope();
    final timestampStr = _toBase58(timestamp, _strLenTimestamp);
    final deviceIdStr = _toBase58(deviceIdNum, _strLenDevice);
    final counterStr = _toBase58(counter, _strLenCounter);
    final result = "$scopeStr-$timestampStr-$deviceIdStr-$counterStr";

    assert(
      result.length <= _strLen && result.length > _strLen - _binLenScope,
      'got length ${result.length} for result "$result"',
    );

    return result;
  }

  /// Equality operator to compare two IDs
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Id) return false;

    for (int i = 0; i < _binLen; i++) {
      if (bytes[i] != other.bytes[i]) return false;
    }
    return true;
  }

  /// Hash code implementation for using Id in collections
  /// TODO: check me
  @override
  int get hashCode {
    int result = 17;
    for (int i = 0; i < _binLen; i++) {
      result = 37 * result + bytes[i];
    }
    return result;
  }

  @override
  int compareTo(Id other) {
    for (int i = 0; i < _binLen; i++) {
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
  final int value; // hmmm, its not bytes

  const DeviceId(this.value)
    : assert(
        value >= 0 && value < _maxDeviceIdValue,
        'incorrect deviceId $value, expected a value in 0-${_maxDeviceIdValue - 1} range',
      );

  /// Creates a DeviceId from its Base58 string representation
  DeviceId.fromString(String valueStr) : value = _fromBase58(valueStr) {
    if (value >= _maxDeviceIdValue) {
      throw FormatException(
        'Device ID value exceeds maximum allowed value of $_maxDeviceIdValue',
      );
    }
  }

  /// Creates a DeviceId with a random value
  DeviceId.random() : value = Random.secure().nextInt(_maxDeviceIdValue);

  /// Converts the DeviceUid to its Base58 string representation
  @override
  String toString() => _toBase58(value, Id._strLenDevice);

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
      _counter = Random.secure().nextInt(_maxCounterValue);
    } else if (counter < 0 || counter > _maxCounterValue) {
      throw ArgumentError('Counter must be between 0 and $_maxCounterValue');
    }
  }

  Id newUId(String scope) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final currentCount = _getAndIncrementCounter();
    return Id.fromParts(scope, timestamp, deviceId.value, currentCount);
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

// Maximum values for device ID and counter components
const int _maxDeviceIdValue = 0xFFFF; // u16
const int _maxCounterValue = 0xFFFF;

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
