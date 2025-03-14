import 'package:notes_v0_2/notes/repo.dart';
import 'package:notes_v0_2/notes/models.dart';
import 'package:notes_v0_2/common/stream.dart';
import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/system/models.dart';
// following https://dart.dev/language/class-modifiers#sealed

sealed class NotesEvent extends AnyEvent<NotesRepo> {
  static final Map<String, NotesEvent Function(Map<String, dynamic>)> _parsers =
      {
        NoteNewStreamCreated._type: NoteNewStreamCreated.fromMap,
        NoteBodyEditedFull._type: NoteBodyEditedFull.fromMap,
        NoteArchived._type: NoteArchived.fromMap,
        TagAssignedToNote._type: TagAssignedToNote.fromMap,
        TagUnassignedToNote._type: TagUnassignedToNote.fromMap,
        TestEvent._type: TestEvent.fromMap,
      };

  const NotesEvent();

  factory NotesEvent.fromMap(Map<String, dynamic> map) {
    final eventType = map['_type'];

    if (_parsers.containsKey(eventType)) {
      return _parsers[eventType]!(map);
    }

    throw ArgumentError('Unknown event type: $eventType');
  }
}

final class NoteNewStreamCreated extends NotesEvent {
  final Id streamId;

  const NoteNewStreamCreated({required this.streamId});
  // : assert(StreamNote.isValid(streamId)),
  //   assert(streamId.name == "note");
  // {
  //   if (!StreamNote.isValid(streamId)) {
  //     throw ArgumentError("streamId is not note! got instead $streamId");
  //   }
  // }

  @override
  Future<void> apply(Stream inStream, NotesRepo db) async {
    inStream.throwIfNotNamedWithName("global");
    final note = Note(streamId);
    // create a new note, whos id is part of the stream
    await db.noteSave(note);
  }

  static const String _type = 'newNoteStreamCreated';

  @override
  NoteNewStreamCreated.fromMap(Map<String, dynamic> json)
    : streamId = Id.fromString(json['streamId']);

  @override
  Map<String, dynamic> toMap() => {
    '_type': _type,
    'streamId': streamId.toString(),
  };
}

class NoteBodyEditedFull extends NotesEvent {
  final String value;

  const NoteBodyEditedFull({required this.value});

  @override
  Future<void> apply(Stream inStream, NotesRepo db) async {
    final noteId = inStream.getIdInScopeOrThrow("note");

    await db.noteContentUpdate(noteId, fullBody: value);
  }

  static const String _type = 'noteBodyEditedFull';

  @override
  NoteBodyEditedFull.fromMap(Map<String, dynamic> json) : value = json['value'];

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'value': value};
}

// soft delete only for now
// this "reorders" this event into the "archived" list
// there are 3 ordering lists: main, archived, pinned
class NoteArchived extends NotesEvent {
  const NoteArchived();

  @override
  Future<void> apply(Stream inStream, NotesRepo db) async {
    throw UnimplementedError();
  }

  static const String _type = 'noteArchived';

  @override
  NoteArchived.fromMap(Map<String, dynamic> json);

  @override
  Map<String, dynamic> toMap() => {'_type': _type};
}

/// tags are not created nor destroyed
/// they are simply assigned. the logic of this handler (apply)
/// creates and removes them from general list
class TagAssignedToNote extends NotesEvent {
  final String tagName;

  TagAssignedToNote({required this.tagName});

  @override
  Future<void> apply(Stream inStream, NotesRepo db) async {
    final noteId = inStream.getIdInScopeOrThrow("note");
    await db.tagActionOnNote(noteId, tagName, TagAction.add);
  }

  static const String _type = 'tagAssignedToNote';

  @override
  TagAssignedToNote.fromMap(Map<String, dynamic> json)
    : tagName = json['tagName'];

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'tagName': tagName};
}

class TagUnassignedToNote extends NotesEvent {
  final String tagName;

  TagUnassignedToNote({required this.tagName});

  @override
  Future<void> apply(Stream inStream, NotesRepo db) async {
    final noteId = inStream.getIdInScopeOrThrow("note");
    await db.tagActionOnNote(noteId, tagName, TagAction.remove);
  }

  static const String _type = 'tagUnassignedToNote';

  @override
  TagUnassignedToNote.fromMap(Map<String, dynamic> json)
    : tagName = json['tagName'];

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'tagName': tagName};
}

class TestEvent extends NotesEvent {
  final String value;

  TestEvent({required this.value});

  @override
  Future<void> apply(Stream inStream, NotesRepo db) async {
    throw Exception("cannot apply test event");
  }

  static const String _type = 'TEST_EVENT';

  @override
  TestEvent.fromMap(Map<String, dynamic> json) : value = json['value'];

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'value': value};
}
