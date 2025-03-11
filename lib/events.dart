import 'package:notes_v0_2/app_db.dart';
import 'package:notes_v0_2/stream_id.dart';

// following https://dart.dev/language/class-modifiers#sealed

sealed class Event {
  static final Map<String, Event Function(Map<String, dynamic>)> _eventParsers =
      {
        NewNoteStreamCreated._type:
            (json) => NewNoteStreamCreated.fromMap(json),
        NoteArchived._type: (json) => NoteArchived.fromMap(json),
        NoteBodyEdited._type: (json) => NoteBodyEdited.fromMap(json),
        TagAssignedToNote._type: (json) => TagAssignedToNote.fromMap(json),
      };

  const Event();

  // empty values which will be overriden
  Event.fromMap(Map<String, dynamic> json);

  Map<String, dynamic> toMap() => {};

  // its inStreamId because this is the current stream that was written
  Future<void> apply(StreamId inStreamId, AppDb db) async => {};

  // Static method to parse any event from a map
  static Event parseEvent(Map<String, dynamic> eventMap) {
    final eventType = eventMap['_type'];

    if (_eventParsers.containsKey(eventType)) {
      return _eventParsers[eventType]!(eventMap);
    }

    throw ArgumentError('Unknown event type: $eventType');
  }
}

class NewNoteStreamCreated extends Event {
  StreamIdWithId streamId;

  NewNoteStreamCreated({required this.streamId}) {
    if (!StreamIdNote.isNote(streamId)) {
      throw ArgumentError("streamId is not note! got instead $streamId");
    }
  }

  @override
  Future<void> apply(StreamId inStreamId, AppDb db) async {
    // this does not work for some reason>?
    // if (StreamIdGlobal.isGlobal(inStreamId)) {
    //   throw ArgumentError("streamId is not global! got instead $inStreamId");
    // }

    // create a new note, whos id is part of the stream
    await db.noteCreate(streamId.id);
  }

  static const String _type = 'newNoteStreamCreated';

  @override
  NewNoteStreamCreated.fromMap(Map<String, dynamic> json)
    : streamId = StreamIdWithId.fromString(json['streamId']);

  @override
  Map<String, dynamic> toMap() => {
    '_type': _type,
    'streamId': streamId.toString(),
  };
}

// soft delete only for now
class NoteArchived extends Event {
  NoteArchived();

  @override
  Future<void> apply(StreamId inStreamId, AppDb db) async {
    throw UnimplementedError();
  }

  static const String _type = 'noteArchived';

  @override
  NoteArchived.fromMap(Map<String, dynamic> json);

  @override
  Map<String, dynamic> toMap() => {'_type': _type};
}

class NoteBodyEdited extends Event {
  String value;

  NoteBodyEdited({required this.value});

  @override
  Future<void> apply(StreamId inStreamId, AppDb db) async {
    final id = inStreamId.getIdOrThrow();

    await db.noteContentUpdate(id, fullBody: value);
  }

  static const String _type = 'noteBodyEdited';

  @override
  NoteBodyEdited.fromMap(Map<String, dynamic> json) : value = json['value'];

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'value': value};
}

/// tags are not created nor destroyed
/// they are simply assigned. the logic of this handler (apply)
/// creates and removes them from general list
class TagAssignedToNote extends Event {
  String tagName;

  TagAssignedToNote({required this.tagName});

  @override
  Future<void> apply(StreamId inStreamId, AppDb db) async {
    throw UnimplementedError();
  }

  static const String _type = 'tagAssignToNote';

  @override
  TagAssignedToNote.fromMap(Map<String, dynamic> json)
    : tagName = json['tagName'];

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'tagName': tagName};
}
