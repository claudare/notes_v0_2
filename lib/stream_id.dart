// limit to 12 characters and get max sizes:
// 24 bytes binary
// 32 bytes text
import 'package:notes_v0_2/id.dart';

class GlobalStreamId extends StreamId {
  GlobalStreamId() : super("global", null);
}

class NoteStreamId extends StreamId {
  NoteStreamId(Id id) : super("note", id);
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

  bool get hasId => id != null;

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
}
