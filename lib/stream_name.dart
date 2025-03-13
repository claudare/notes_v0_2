// limit to 12 characters and get max sizes:
// 24 bytes binary
// 32 bytes text
import 'package:notes_v0_2/id.dart';

class StreamGlobal extends StreamName {
  static const _name = "global";

  StreamGlobal() : super(_name, null);

  static bool isValid(StreamName streamId) {
    return streamId.name == _name && !streamId.hasId;
  }
}

class StreamNote extends StreamNameWithId {
  static const _name = "note";

  StreamNote(Id id) : super(_name, id);

  static bool isValid(StreamName streamId) {
    return streamId.name == _name && streamId.hasId;
  }
}

class StreamName {
  // static const _size = 24;
  static const _maxNameSize = 12; // 12

  final String name;
  final Id? _id;

  const StreamName(this.name, this._id);
  // : assert(
  //     name.length > _maxNameSize,
  //     'stream name cannot be longer then $_maxNameSize. given ${name}',
  //   );

  factory StreamName.fromString(String value) {
    final parts = value.split('-');
    if (parts.length == 1) {
      return StreamName(parts[0], null);
    } else if (parts.length == 4) {
      final name = parts[0];
      final idStr = parts.sublist(1).join('-');
      return StreamNameWithId(name, Id.fromString(idStr));
    } else {
      throw FormatException("Invalid ID format");
    }
  }

  bool get hasId => _id != null;

  StreamNameWithId toStreamIdWithId() {
    if (!hasId) {
      throw ArgumentError('stream $name does not have an id');
    }
    return StreamNameWithId(name, _id!);
  }

  Id getIdOrThrow() {
    if (!hasId) {
      throw ArgumentError('stream $name does not have an id');
    }
    return _id!;
  }

  bool doesConformTo(String withName, bool withId) {
    if (name != withName) return false;
    if (withId && _id == null) return false;
    if (!withId && _id != null) return false;
    return true;
  }

  // hardcoded stream examples for this app
  // bool get isNote => name == 'note' && _id != null;
  // bool get isGlobal => name == 'global' && _id == null;
}

class StreamNameWithId extends StreamName {
  const StreamNameWithId(super.name, super.id);

  factory StreamNameWithId.fromString(String value) {
    final parts = value.split('-');
    if (parts.length != 4) {
      throw FormatException("Invalid ID format");
    }
    final name = parts[0];
    final idStr = parts.sublist(1).join('-');
    return StreamNameWithId(name, Id.fromString(idStr));
  }

  Id get id => _id!;

  @override
  String toString() {
    return '$name-${id.toString()}';
  }
}
