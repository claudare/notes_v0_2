class ItemNotFoundException implements Exception {
  final String _stringId;

  const ItemNotFoundException(this._stringId);

  @override
  String toString() {
    return _stringId;
  }
}

class ItemWasAlreadyDeletedException implements Exception {
  final String _stringId;

  const ItemWasAlreadyDeletedException(this._stringId);

  @override
  String toString() {
    return _stringId;
  }
}
