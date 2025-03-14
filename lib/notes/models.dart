import 'package:notes_v0_2/common/id.dart';

// these are not models, but rather projections!
// there are many note projections
// notably, i need to model edit history

class Note {
  final Id noteId;
  String title;
  String body;
  DateTime createdAt;
  DateTime editedAt;

  // conflicts are just pointers to the current body content
  // they are arrays, which are used to assist conflict resolution
  final String conflicts = 'TODO';

  final Set<String> tags;

  Note(this.noteId, {this.title = "", this.body = ""})
    : createdAt = noteId.getTimestamp(),
      editedAt = noteId.getTimestamp(),
      tags = {};

  Note.fromMap(Map<String, dynamic> map)
    : noteId = Id.fromString(map['noteId']),
      title = map['title'] ?? '',
      body = map['body'] ?? '',
      tags = Set<String>.from(map['tags']),
      createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      editedAt = DateTime.fromMillisecondsSinceEpoch(map['editedAt']);

  Map<String, dynamic> toMap() => {
    'noteId': noteId.toString(),
    'title': title,
    'body': body,
    'tags': tags.toList(),
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

class Tag {
  final String name;
  final Set<Id> assignedToNotes;

  const Tag(this.name, this.assignedToNotes);

  int get count => assignedToNotes.length;

  // Serialize to Map instead of List
  Map<String, dynamic> toJson() => {
    'name': name,
    'assignedToNotes': assignedToNotes.map((id) => id.toString()).toList(),
  };

  // Create from Map<String, dynamic>
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      json['name'],
      (json['assignedToNotes'] as List)
          .map((item) => Id.fromString(item.toString()))
          .toSet(),
    );
  }

  @override
  String toString() {
    final notesStr = assignedToNotes.map((id) => id.toString()).join(", ");
    return 'Tag[notes: $notesStr]';
  }
}
