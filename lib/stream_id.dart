// limit to 12 characters and get max sizes:
// 24 bytes binary
// 32 bytes text
import 'package:notes_v0_2/id.dart';

class StreamIdGlobal extends StreamId {
  static const _name = "global";

  StreamIdGlobal() : super(_name, null);

  static bool isGlobal(StreamId streamId) {
    print("compare stream id is $streamId, compared to $_name");
    return streamId.name == _name && !streamId.hasId;
  }
}

class StreamIdNote extends StreamIdWithId {
  static const _name = "note";

  StreamIdNote(Id id) : super(_name, id);

  static bool isNote(StreamId streamId) {
    return streamId.name == _name && streamId.hasId;
  }
}

class StreamId {
  // static const _size = 24;
  static const _maxNameSize = 12; // 12

  final String name;
  final Id? _id;

  StreamId(this.name, this._id) {
    // TODO: only ascci allowed!
    if (name.length > (_maxNameSize)) {
      throw ArgumentError('stream name cannot be longer then $_maxNameSize');
    }
  }

  factory StreamId.fromString(String value) {
    final parts = value.split('-');
    if (parts.length == 1) {
      return StreamId(parts[0], null);
    } else if (parts.length == 4) {
      final name = parts[0];
      final idStr = parts.sublist(1).join('-');
      return StreamIdWithId(name, Id.fromString(idStr));
    } else {
      throw FormatException("Invalid ID format");
    }
  }

  StreamIdWithId toStreamIdWithId() {
    if (!hasId) {
      throw ArgumentError('stream $name does not have an id');
    }
    return StreamIdWithId(name, _id!);
  }

  Id getIdOrThrow() {
    if (!hasId) {
      throw ArgumentError('stream $name does not have an id');
    }
    return _id!;
  }

  bool get hasId => _id != null;
}

class StreamIdWithId extends StreamId {
  StreamIdWithId(super.name, super.id);

  factory StreamIdWithId.fromString(String value) {
    final parts = value.split('-');
    if (parts.length != 4) {
      throw FormatException("Invalid ID format");
    }
    final name = parts[0];
    final idStr = parts.sublist(1).join('-');
    return StreamIdWithId(name, Id.fromString(idStr));
  }

  Id get id => _id!;

  @override
  String toString() {
    return '$name-${id.toString()}';
  }
}
