import 'package:notes_v0_2/common/id.dart';

// this is either a constant global name
// or an id name
// either way the length of this id is
// binary 16 bytes
// text 24 bytes. Named ones are actually 16 bytes
class Stream {
  final String? _name;
  final Id? _id;

  static const _maxNameLength = 16;

  const Stream.id(Id id) : _name = null, _id = id;

  // TODO: should not allow "-" in the name
  const Stream.named(String name)
    : assert(
        name.length <= _maxNameLength,
        'Global stream name cannot be longer than $_maxNameLength characters',
      ),
      _name = name,
      _id = null;

  factory Stream.fromString(String value) {
    if (!value.contains('-')) {
      return Stream.named(value);
    }

    final id = Id.fromString(value);
    return Stream.id(id);
  }

  String get name {
    if (_id != null) {
      return _id.toString();
    }
    return _name!;
  }

  Id? get id {
    return _id;
  }

  Id get idOrThrow {
    if (_id != null) return _id;
    throw ArgumentError('stream $name does not have an id');
  }

  /// returns true if id stream has the same scope
  /// returns true if static name completely matches
  /// this does not differentiate the ids. instead use idOrThrow getter.
  bool isInScope(String scope) {
    if (_name != null) return scope == _name;
    if (_id != null) return scope == _id.getScope();

    return false;
  }

  void throwIfNotInScope(String scope) {
    final inScope = isInScope(scope);

    if (!inScope) {
      throw ArgumentError('Stream $name is not in scope $scope');
    }
  }

  @Deprecated('bad API')
  bool get isNamed => _name != null;

  @Deprecated('bad API')
  bool isNamedWithName(String name) {
    if (_name != null) return _name == name;
    return false;
  }

  @Deprecated('bad API')
  void throwIfNotNamedWithName(String name) {
    if (_name == null) {
      throw ArgumentError('stream $_id is not global $name');
    }
    if (_name != name) {
      throw ArgumentError('stream $_name does not have name $name');
    }
  }

  @Deprecated('bad API')
  bool get isId => _id != null;

  @Deprecated('bad API')
  Id? getIdInScope(String scope) {
    if (_id != null && _id.getScope() == scope) {
      return _id;
    }
    return null;
  }

  @Deprecated('bad API')
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
    return other is Stream && other._name == _name && other._id == _id;
  }

  @override
  int get hashCode => Object.hash(_name, _id);
}
