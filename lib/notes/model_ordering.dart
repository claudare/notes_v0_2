// ignore_for_file: library_private_types_in_public_api
// is this ignore alright?
import 'dart:collection';

import 'package:notes_v0_2/common/id.dart';

final class _EntryOrdering extends LinkedListEntry<_EntryOrdering> {
  final Id id;
  final Category category;

  _EntryOrdering(this.id, this.category);

  @override
  String toString() {
    return '$id';
  }
}

enum Category { main, pinned }

class NoteOrdering {
  final Map<Id, _EntryOrdering> _lookup;
  final LinkedList<_EntryOrdering> main;
  final LinkedList<_EntryOrdering> pinned;

  NoteOrdering()
    : _lookup = {},
      main = LinkedList<_EntryOrdering>(),
      pinned = LinkedList<_EntryOrdering>();

  void append(Id id, Category cat) {
    final entry = _EntryOrdering(id, cat);
    final ll = _getLinkedList(cat);

    _lookup[id] = entry;
    ll.add(entry);
  }

  // the item will be moved to another category and will always go on the top

  void moveToOtherCategory(Id id, Category otherCat) {
    final entry = _lookup[id];
    if (entry == null) {
      throw ArgumentError('entry $id not found');
    }
    final fromLinkedList = _getLinkedList(entry.category);
    final toLinkedList = _getLinkedList(otherCat);
    fromLinkedList.remove(entry);
    toLinkedList.add(entry);
  }

  // but sometimes (in the case of restore, it needs to move back to its original position)
  // then index from the top is used instead, as "after" items could have been be moved
  //
  // this can be done by simple iteraton, optimized with a binary search lookup index of sorts
  void moveToOtherCategoryAtIndex(Id id, Category otherCat, int idx) {
    throw UnimplementedError();
  }

  void rearrange(Id id, Id? afterId) {
    final entry = _lookup[id];
    if (entry == null) {
      throw ArgumentError('entry $id not found');
    }
    final ll = _getLinkedList(entry.category);

    if (afterId == null) {
      ll.addFirst(entry);
      return;
    }

    final afterEntry = _lookup[afterId];
    if (afterEntry == null) {
      throw ArgumentError('afterEntry $id not found');
    }

    if (entry.category != afterEntry.category) {
      throw Exception(
        "cannot rearrange to different category: ${entry.category} to ${afterEntry.category}",
      );
    }

    entry.unlink();
    afterEntry.insertAfter(entry);
  }

  void remove(Id id) {
    final entry = _lookup[id];
    if (entry == null) {
      throw ArgumentError('entry $id not found');
    }
    entry.unlink();
    _lookup.remove(id);
  }

  int count(Category cat) {
    final ll = _getLinkedList(cat);
    return ll.length;
  }

  LinkedList<_EntryOrdering> _getLinkedList(Category cat) {
    return switch (cat) {
      Category.main => main,
      Category.pinned => pinned,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'main':
          main.map((e) => e.id.toString()).toList(), //toList(growable: false),
      'pinned': pinned.map((e) => e.id.toString()).toList(),
    };
  }

  factory NoteOrdering.fromJson(Map<String, dynamic> json) {
    final mainList =
        (json['main'] as List<dynamic>).map((e) => Id.fromString(e)).toList();
    final pinnedList =
        (json['pinned'] as List<dynamic>).map((e) => Id.fromString(e)).toList();

    final res = NoteOrdering();

    for (final id in mainList) {
      res.append(id, Category.main);
    }
    for (final id in pinnedList) {
      res.append(id, Category.pinned);
    }

    return res;
  }
}
