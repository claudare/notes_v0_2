import 'package:notes_v0_2/common/id.dart';

class Node<T> {
  final T id;
  Node<T>? next;
  Node<T>? prev;

  Node(this.id, {this.next, this.prev});
}

class Ordering<T> {
  final Map<T, Node> _map;
  Node<T>? _last;

  Ordering() : _map = {};

  int get count => _map.length;

  // optimized, faster then insert
  void append(T id) {
    final newNode = Node(id);
    _map[id] = newNode;
    // ignore: prefer_conditional_assignment
    if (_last == null) {
      _last = newNode;
      return;
    }

    newNode.prev = _last;
    _last!.next = newNode;
    _last = newNode;
    return;
  }

  Node _cut(T id, {required bool removeFromMap}) {
    final current = _map[id];
    assert(current != null);
    final before = current!.prev;
    final after = current.next;
    before?.next = after;
    after?.prev = before;

    if (removeFromMap) {
      _map.remove(id);
      current.prev = null;
      current.next = null;
    }

    return current;
  }

  void _paste(Node node, T? afterId, {required bool addToMap}) {
    if (afterId == null) {
      final last = getLast();
      node.next = last;
      last.prev = node;
      if (addToMap) {
        _map[node.id] = node;
      }
      return;
    }
    final before = _map[afterId];
    assert(before != null);

    final after = before!.next;

    before.next = node;
    node.prev = before;
    node.next = after;
    after?.prev = node;

    if (addToMap) {
      _map[node.id] = node;
    }
  }

  void remove(T id) {
    _cut(id, removeFromMap: true);
  }

  void insert(T id, T? afterId) {
    final node = Node(id);
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
    assert(_last != null);
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
  Node getLast() {
    var node = _last;
    assert(node != null);

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
        'infinite loop detected. current list: ${result.join(', ')} ',
      );
    }

    return result;
  }
}
