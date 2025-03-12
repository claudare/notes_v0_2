import 'package:notes_v0_2/id.dart';

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

  @override
  String toString() {
    final tagStr = tags.isEmpty ? 'none' : tags.join(', ');
    return 'Note[id: $noteId, title: $title, body: $body, tags: $tagStr, createdAt: $createdAt, editedAt: $editedAt]';
  }
}
