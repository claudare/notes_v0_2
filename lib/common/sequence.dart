class DbSequences {
  Map<String, Device> devices;

  DbSequences() : devices = {};

  // raw, pure, shameless json
  factory DbSequences.fromMap(Map<String, dynamic> map) {
    final dbSequences = DbSequences();
    for (final deviceUid in map.keys) {
      final deviceData = map[deviceUid] as Map<String, dynamic>;
      final lastSeq = deviceData['lastSeq'] as int;
      final streamSeqs = SequenceMap.fromMap(deviceData['streams']);
      dbSequences.devices[deviceUid] = Device(lastSeq)..streamSeqs = streamSeqs;
    }
    return dbSequences;
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    for (final deviceUid in devices.keys) {
      final device = devices[deviceUid]!;
      final deviceData = {
        'lastSeq': device.deviceSeq.current,
        'streams': device.streamSeqs.toMap(),
      };
      map[deviceUid] = deviceData;
    }
    return map;
  }

  void addDevice(String deviceUid, int deviceLastSeq) {
    if (devices.containsKey(deviceUid)) {
      throw ArgumentError('device $deviceUid already exists');
    }
    devices[deviceUid] = Device(deviceLastSeq);
  }

  Sequence getDeviceSequence(String deviceUid) {
    if (!devices.containsKey(deviceUid)) {
      throw ArgumentError('device $deviceUid does not exist');
    }
    return devices[deviceUid]!.deviceSeq;
  }

  void addStreamSequence(
    String deviceUid,
    String streamName,
    int streamLastSeq,
  ) {
    final streamSeqs = _getStreamSequenceMap(deviceUid);
    streamSeqs.add(streamName, streamLastSeq);
  }

  int nextStreamSequence(String deviceUid, String streamName) {
    return _getStreamSequenceMap(deviceUid).nextOrNew(streamName);
  }

  SequenceMap _getStreamSequenceMap(String deviceUid) {
    if (!devices.containsKey(deviceUid)) {
      throw ArgumentError("Device does not exist");
    }
    return devices[deviceUid]!.streamSeqs;
  }
}

class Device {
  SequenceMap streamSeqs;
  Sequence deviceSeq;

  Device(int deviceLastSeq)
    : streamSeqs = SequenceMap(),
      deviceSeq = Sequence(deviceLastSeq);
}

class SequenceMap {
  Map<String, Sequence> map;

  SequenceMap() : map = {};

  factory SequenceMap.fromMap(Map<String, dynamic> map) {
    final sequenceMap = SequenceMap();
    for (final name in map.keys) {
      final value = map[name] as int;
      sequenceMap.add(name, value);
    }
    return sequenceMap;
  }

  Map<String, dynamic> toMap() {
    final outMap = <String, dynamic>{};
    for (final name in map.keys) {
      outMap[name] = map[name]!.current;
    }
    return outMap;
  }

  void add(String name, int value) {
    if (map.containsKey(name)) {
      throw ArgumentError('named sequence $name already exists');
    }
    map[name] = Sequence(value);
  }

  int next(String name) {
    if (!map.containsKey(name)) {
      throw ArgumentError("Sequence does not exist");
    }
    return map[name]!.next();
  }

  int nextOrNew(String name) {
    if (map.containsKey(name)) {
      return map[name]!.next();
    } else {
      final newSeq = Sequence(0);
      map[name] = newSeq;
      return newSeq.next();
    }
  }
}

class Sequence {
  int _value;

  Sequence(this._value) {
    if (_value < 0) {
      throw ArgumentError("sequences must be positive");
    }
  }

  int get current => _value;

  int next() {
    _value += 1;
    return _value;
  }
}
