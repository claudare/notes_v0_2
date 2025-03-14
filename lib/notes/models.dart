import 'package:notes_v0_2/common/id.dart';

// these are not models, but rather projections!
// there are many note projections
// notably, i need to model edit history

class Note {
  Id noteId;
  String title;
  String body;
  DateTime createdAt;
  DateTime editedAt;

  // conflicts are just pointers to the current body content
  // they are arrays, which are used to assist conflict resolution
  String conflicts = 'TODO';

  List<String> tags;

  Note(this.noteId, {this.title = "", this.body = "", this.tags = const []})
    : createdAt = noteId.getTimestamp(),
      editedAt = noteId.getTimestamp();

  Note.fromMap(Map<String, dynamic> map)
    : noteId = Id.fromString(map['noteId']),
      title = map['title'] ?? '',
      body = map['body'] ?? '',
      tags = List<String>.from(map['tags']),
      createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      editedAt = DateTime.fromMillisecondsSinceEpoch(map['editedAt']);

  Map<String, dynamic> toMap() => {
    'noteId': noteId.toString(),
    'title': title,
    'body': body,
    'tags': tags,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'editedAt': editedAt.millisecondsSinceEpoch,
  };

  // void updateEditedAt() {
  //   editedAt = DateTime.now(); // this is hardly testable
  // }

  @override
  String toString() {
    final tagStr = tags.isEmpty ? 'none' : tags.join(', ');
    return 'Note[id: $noteId, title: $title, body: $body, tags: $tagStr, createdAt: $createdAt, editedAt: $editedAt]';
  }
}

enum TagAction { add, remove }

// TODO: change stored value from int to List<Id>
// also allow to store each tag as a separate row
class Tags {
  final Map<String, int> _tagCounts;

  const Tags(this._tagCounts);
  Tags.empty() : _tagCounts = {};

  void add(String tag) {
    if (_tagCounts.containsKey(tag)) {
      _tagCounts[tag] = _tagCounts[tag]! + 1;
    } else {
      _tagCounts[tag] = 1;
    }
  }

  void remove(String tag) {
    if (_tagCounts.containsKey(tag)) {
      _tagCounts[tag] = _tagCounts[tag]! - 1;
      if (_tagCounts[tag] == 0) {
        _tagCounts.remove(tag);
      }
    }
  }

  List<String> toList() {
    return _tagCounts.keys.toList();
  }

  Map<String, dynamic> toMap() => _tagCounts;

  factory Tags.fromMap(Map<String, dynamic> map) {
    return Tags(Map<String, int>.from(map));
  }
  // or could do this:
  // factory Tags.fromMap(Map<String, dynamic> map) => Tags(Map<String, int>.from(map));

  @override
  String toString() {
    final tagsStr = toList().join(", ");
    return 'TagMap[$tagsStr]';
  }
}
