class Node<T> {
  final T id;
  Node<T>? next;
  Node<T>? prev;

  Node(this.id, {this.next, this.prev});
}

// TODO: move hashmap out of here
// TODO: add quick lookup index (which is serializeable too!)
class DoublyLinkedList<T> {
  final Map<T, Node<T>> _map;
  Node<T>? _last;

  DoublyLinkedList() : _map = {};

  int get count => _map.length;

  // optimized, faster then insert
  void append(T id) {
    final newNode = Node(id);
    _map[id] = newNode;

    if (_last == null) {
      _last = newNode;
      return;
    }

    newNode.prev = _last;
    _last!.next = newNode;
    _last = newNode;
    return;
  }

  Node<T> _cut(T id, {required bool removeFromMap}) {
    final current = _map[id];
    assert(current != null);

    final before = current!.prev;
    final after = current.next;

    before?.next = after;
    after?.prev = before;

    // cutting the first value
    if (after == null) {
      _last = before;
    }

    if (removeFromMap) {
      _map.remove(id);
      current.prev = null;
      current.next = null;
    }

    return current;
  }

  void _paste(Node<T> node, T? afterId, {required bool addToMap}) {
    if (addToMap) {
      _map[node.id] = node;
    }

    if (afterId == null) {
      final last = getLast();

      node.next = last;
      last.prev = node;

      return;
    }
    final before = _map[afterId];

    final after = before!.next;
    before.next = node;
    node.prev = before;
    node.next = after;
    after?.prev = node;

    if (after == null) {
      // adding to the end
      _last = node;
    }
  }

  void remove(T id) {
    _cut(id, removeFromMap: true);
  }

  /// if afterId is null, the value will be inserted in the beginning
  void insert(T id, T? afterId) {
    if (_last == null) {
      append(id);
      return;
    }

    final node = Node<T>(id);
    _paste(node, afterId, addToMap: true);
  }

  void move(T id, T? afterId) {
    if (id == afterId) {
      throw ArgumentError("cannot move in place, this is noop");
    }
    final cutNode = _cut(id, removeFromMap: false);
    _paste(cutNode, afterId, addToMap: false);
  }

  // this will iterate all of them and return starting index
  // for now its not optimized, but its okay
  // empty list is not allowed
  Node getAtIndex(int idx) {
    assert(_last != null, 'empty list not allowed');
    assert(_map.isNotEmpty, 'empty list not allowed');

    var node = _last;
    for (var i = 0; i < idx; i++) {
      if (node == null) {
        throw RangeError('ordering index $idx is out of range. max is $i');
      }
      node = node.prev;
    }
    return node!;
  }

  // this cant be called if there are no items...
  Node<T> getLast() {
    assert(_last != null && _map.isNotEmpty);
    if (_last == null) {
      throw StateError('No items in list');
    }
    var node = _last;

    while (node!.prev != null) {
      node = node.prev;
    }
    return node;
  }

  void clear() {
    var node = _last;
    while (node != null) {
      _last!.next = null;
      node = node.prev;
    }
    _map.clear();
  }

  // from last to first
  List<T> toListDesc() {
    if (_last == null) {
      return [];
    }

    final result = List<T>.empty(growable: true);

    var remaining = count;
    var node = _last;
    while (node != null) {
      result.add(node.id);
      node = node.prev;

      remaining--;
      assert(
        remaining >= 0,
        'infinite loop detected. count $count. list ${result.join(', ')} ',
      );
    }

    return result;
  }
}

// instead use LinkedList from collection?
