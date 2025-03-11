import 'package:notes_v0_2/app_db.dart';
import 'package:notes_v0_2/id.dart';
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

  Future<void> apply(StreamId streamId, AppDb db) async => {};

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
  StreamId streamId;

  NewNoteStreamCreated({required this.streamId}) {
    if (!streamId.hasId) {
      throw ArgumentError("NewNoteStreamCreated needs an id");
    }
  }

  @override
  Future<void> apply(StreamId streamId, AppDb db) async {
    // TODO: this is untested! Would be nice
    // but i dont wanna overabstract too
    if (streamId is! GlobalStreamId) {
      throw ArgumentError(
        "NewNoteStreamCreated can only be written to the global stream",
      );
    }
    throw UnimplementedError();
  }

  static const String _type = 'newNoteStreamCreated';

  @override
  NewNoteStreamCreated.fromMap(Map<String, dynamic> json)
    : streamId = StreamId.fromString(json['streamId']);

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
  Future<void> apply(StreamId streamId, AppDb db) async {
    if (streamId is! NoteStreamId) {
      throw ArgumentError('Expected a NoteStreamId');
    }

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
  Future<void> apply(StreamId streamId, AppDb db) async {
    throw UnimplementedError();
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
  Future<void> apply(StreamId streamId, AppDb db) async {
    throw UnimplementedError();
  }

  static const String _type = 'tagAssignToNote';

  @override
  TagAssignedToNote.fromMap(Map<String, dynamic> json)
    : tagName = json['tagName'];

  @override
  Map<String, dynamic> toMap() => {'_type': _type, 'tagName': tagName};
}
