import 'package:notes_v0_2/id.dart';

// class StreamGlobal extends StreamName {
//   static const _name = "global";

//   StreamGlobal() : super(_name, null);

//   static bool isValid(StreamName streamId) {
//     return streamId.name == _name && !streamId.hasId;
//   }
// }

// class StreamNote extends StreamNameWithId {
//   static const _name = "note";

//   StreamNote(Id id) : super(_name, id);

//   static bool isValid(StreamName streamId) {
//     return streamId.name == _name && streamId.hasId;
//   }
// }

// this is either a constant global name
// or an id name
// either way the length of this id is
// binary 16 bytes
// text 24 bytes. Global are actually 16 bytes
class StreamName {
  final String? _name;
  final Id? _id;

  static const _maxNameLength = 16;

  // const StreamName._(this._name, this._id)
  //   : assert(_name != null && _id != null),
  //     assert(
  //       _name != null && _name.length <= _maxNameLength,
  //       'Global stream name cannot be longer than $_maxNameLength characters',
  //     );

  /// Creates a stream name without an ID
  const StreamName.global(String name)
    : assert(
        name.length <= _maxNameLength,
        'Global stream name cannot be longer than $_maxNameLength characters',
      ),
      _name = name,
      _id = null;

  const StreamName.id(Id id) : _name = null, _id = id;

  /// Parses a stream name from its string representation
  factory StreamName.fromString(String value) {
    if (!value.contains('-')) {
      return StreamName.global(value);
    }

    final id = Id.fromString(value);
    return StreamName.id(id);
  }

  bool get isId => _id != null;
  bool get isGlobal => _name != null;

  String get name {
    if (isId) {
      return _id!.toString();
    }
    return _name!;
  }

  Id? get id {
    return _id;
  }

  bool isGlobalWithName(String name) {
    if (_name != null) return _name == name;
    return false;
  }

  void throwIfNotGlobalWithName(String name) {
    if (_name == null) {
      throw ArgumentError('stream $_id is not global $name');
    }
    if (_name != name) {
      throw ArgumentError('stream $_name does not have name $name');
    }
  }

  Id? getIdInScope(String scope) {
    if (_id != null && _id.getScope() == scope) {
      return _id;
    }
    return null;
  }

  Id getIdInScopeOrThrow(String scope) {
    if (_id == null) {
      throw ArgumentError('stream $_name is not id with scope $scope');
    }
    if (_id.getScope() != scope) {
      throw ArgumentError('stream $_id is not scoped to $scope');
    }
    return _id;
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamName && other._name == _name && other._id == _id;
  }

  @override
  int get hashCode => Object.hash(_name, _id);
}
