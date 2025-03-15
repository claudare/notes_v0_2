import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/notes/streams.dart';
import 'package:notes_v0_2/system/models.dart';
// following https://dart.dev/language/class-modifiers#sealed

sealed class NotesEvent extends AnyEvent {
  static final Map<String, NotesEvent Function(Map<String, dynamic>)> _parsers =
      {
        NoteNewStreamCreated._type: NoteNewStreamCreated.fromMap,
        NoteBodyEditedFull._type: NoteBodyEditedFull.fromMap,
        NoteReordered._type: NoteReordered.fromMap,
        NotePinned._type: NotePinned.fromMap,
        NoteUnarchived._type: NoteUnarchived.fromMap,
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

  static const String _type = 'newNoteStreamCreated';

  @override
  NoteNewStreamCreated.fromMap(Map<String, dynamic> json)
    : streamId = Id.fromString(json['streamId']);

  @override
  Map<String, dynamic> toMap() => {
    '_type': _type,
    'streamId': streamId.toString(),
  };

  // @override
  // EventLogMinimal toLog() {
  //   return EventLogMinimal(stream: streamGlobal, event: this);
  // }
}

class NoteBodyEditedFull extends NotesEvent {
  final String value;

  const NoteBodyEditedFull({required this.value});

  static const String _type = 'noteBodyEditedFull';

  @override
  NoteBodyEditedFull.fromMap(Map<String, dynamic> json) : value = json['value'];

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'value': value};

  // @override
  // EventLogMinimal toLog() {
  //   return EventLogMinimal(stream: streamNote, event: this);
  // }
}

class NoteReordered extends NotesEvent {
  // if beforeNoteId is null, it means it goes to the top
  final Id noteId;
  final Id? beforeNoteId;

  const NoteReordered({required this.noteId, required this.beforeNoteId});

  static const String _type = 'noteReordered';

  @override
  NoteReordered.fromMap(Map<String, dynamic> json)
    : noteId = Id.fromString(json['noteId']),
      beforeNoteId =
          json['beforeNoteId'] != null
              ? Id.fromString(json['beforeNoteId'])
              : null;

  @override
  Map<String, dynamic> toMap() => {
    '_type': _type,
    'noteId': noteId.toString(),
    'beforeNoteId': beforeNoteId?.toString(),
  };
}

class NotePinned extends NotesEvent {
  // TODO: also save the index of the position for restore functionality
  final Id noteId;

  const NotePinned({required this.noteId});

  static const String _type = 'notePinned';

  @override
  NotePinned.fromMap(Map<String, dynamic> json)
    : noteId = Id.fromString(json['noteId']);

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'noteId': noteId.toString()};
}

class NoteUnarchived extends NotesEvent {
  const NoteUnarchived();

  static const String _type = 'noteUnarchived';

  @override
  NoteUnarchived.fromMap(Map<String, dynamic> json);

  @override
  Map<String, dynamic> toMap() => {'_type': _type};
}

/// tags are not created nor destroyed
/// they are simply assigned. the logic of this handler (apply)
/// creates and removes them from general list
class TagAssignedToNote extends NotesEvent {
  final String tagName;

  TagAssignedToNote({required this.tagName});

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

  static const String _type = 'TEST_EVENT';

  @override
  TestEvent.fromMap(Map<String, dynamic> json) : value = json['value'];

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'value': value};
}
