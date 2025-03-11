// limit to 12 characters and get max sizes:
// 24 bytes binary
// 32 bytes text
import 'package:notes_v0_2/id.dart';

class StreamIdGlobal extends StreamId {
  StreamIdGlobal() : super("global", null);

  static throwIfNotOfType(StreamId streamId) {
    if (streamId is! StreamIdGlobal &&
        !streamId.doesConformToType("global", false)) {
      throw ArgumentError('${streamId.name} is not GlobalStreamId');
    }
  }
}

class StreamIdNote extends StreamId {
  StreamIdNote(Id id) : super("note", id);

  static throwIfNotOfType(StreamId streamId) {
    // the check is skipped if it is actually a streamIdNote
    // there is no way to create it otherwise, as name and id are final
    if (streamId is! StreamIdNote &&
        !streamId.doesConformToType("note", false)) {
      throw ArgumentError('${streamId.name} is not NoteStreamId');
    }
  }
}

class StreamId {
  // static const _size = 24;
  static const _maxNameSize = 12; // 12

  final String name;
  final Id? id;

  StreamId(this.name, this.id) {
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
      // inefficient but it works
      final idStr = parts.sublist(1).join('-');
      return StreamId(name, Id.fromString(idStr));
    } else {
      throw FormatException("Invalid ID format");
    }
  }

  // is this really needed?
  // fix it for nullable id
  // Uint8List getBytes() {
  //   final bytes = Uint8List(_size);
  //   for (var i = 0; i < _maxNameSize; i++) {
  //     bytes[i] = name.codeUnitAt(i);
  //   }
  //   for (var i = _maxNameSize; i < Uid._size; i++) {
  //     bytes[i] = id.bytes[i - _maxNameSize];
  //   }
  //   return bytes;
  // }

  @override
  String toString() {
    if (id != null) {
      final idStr = id.toString();
      // final paddedName = name.padRight(_maxNameSize, '_');
      // return "$paddedName-$idStr";
      return '$name-$idStr';
    } else {
      // do not pad on global streams?
      return name;
    }
  }

  bool doesConformToType(String withName, bool withId) {
    final hasId = id != null;

    if (withId && !hasId) {
      return false;
    } else if (!withId && hasId) {
      return false;
    } else if (withName != name) {
      return false;
    }

    return true;
  }
}
