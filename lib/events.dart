import 'package:notes_v0_2/app_db.dart';
import 'package:notes_v0_2/app_models.dart';
import 'package:notes_v0_2/stream_id.dart';

// following https://dart.dev/language/class-modifiers#sealed

sealed class Event {
  static final Map<String, Event Function(Map<String, dynamic>)> _parsers = {
    NoteNewStreamCreated._type: NoteNewStreamCreated.fromMap,
    NoteBodyEditedFull._type: NoteBodyEditedFull.fromMap,
    NoteArchived._type: NoteArchived.fromMap,
    TagAssignedToNote._type: TagAssignedToNote.fromMap,
    TagUnassignedToNote._type: TagUnassignedToNote.fromMap,
  };

  const Event();

  factory Event.fromMap(Map<String, dynamic> map) {
    final eventType = map['_type'];

    if (_parsers.containsKey(eventType)) {
      return _parsers[eventType]!(map);
    }

    throw ArgumentError('Unknown event type: $eventType');
  }

  Map<String, dynamic> toMap();

  /// inStreamId is current stream id that is being written to
  Future<void> apply(StreamId inStreamId, AppDb db) async => {};
}

class NoteNewStreamCreated extends Event {
  StreamIdWithId streamId;

  NoteNewStreamCreated({required this.streamId}) {
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
  NoteNewStreamCreated.fromMap(Map<String, dynamic> json)
    : streamId = StreamIdWithId.fromString(json['streamId']);

  @override
  Map<String, dynamic> toMap() => {
    '_type': _type,
    'streamId': streamId.toString(),
  };
}

class NoteBodyEditedFull extends Event {
  String value;

  NoteBodyEditedFull({required this.value});

  @override
  Future<void> apply(StreamId inStreamId, AppDb db) async {
    final id = inStreamId.getIdOrThrow();

    await db.noteContentUpdate(id, fullBody: value);
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

/// tags are not created nor destroyed
/// they are simply assigned. the logic of this handler (apply)
/// creates and removes them from general list
class TagAssignedToNote extends Event {
  String tagName;

  TagAssignedToNote({required this.tagName});

  @override
  Future<void> apply(StreamId inStreamId, AppDb db) async {
    final noteId = inStreamId.getIdOrThrow();
    await db.tagActionOnNote(noteId, tagName, TagAction.add);
  }

  static const String _type = 'tagAssignedToNote';

  @override
  TagAssignedToNote.fromMap(Map<String, dynamic> json)
    : tagName = json['tagName'];

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'tagName': tagName};
}

class TagUnassignedToNote extends Event {
  String tagName;

  TagUnassignedToNote({required this.tagName});

  @override
  Future<void> apply(StreamId inStreamId, AppDb db) async {
    final noteId = inStreamId.getIdOrThrow();
    await db.tagActionOnNote(noteId, tagName, TagAction.remove);
  }

  static const String _type = 'tagUnassignedToNote';

  @override
  TagUnassignedToNote.fromMap(Map<String, dynamic> json)
    : tagName = json['tagName'];

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'tagName': tagName};
}
