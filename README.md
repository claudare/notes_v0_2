# notes_v0_2

Second attempt at this

Instead of
`f(event) -> []sqlstatements`
Do a direct nosql database access through a typed system
`f(event, dbwraper) -> dbwrapper(state)`

I will still use sqlite though. Create a dwrapper for all objects, make them queryable (sqlite actually has this). Never rouch raw database objects. As comic as it is, the data-tables will look like this:
```
id TEXT UNIQUE
value BLOB
```
Id should be generated as a random string with preseeding of the device id. Some loweruuid, but with higher density...

All events are stored inside a stream. All inside a stream.


There is a deviceId (fixed string!), devSeqId (autoincrementing per device), streamId (text), streamSeqId (autoincrementing per insert) and data (blob).
StreamId is only used for quering and optimizing lookups of sorts. This will enable for granular conflict resolution.

Reorder events are simply in the stream with name reorder. All notes are implicitly created in desc order. All these events do, is emit NotesReordered(noteId, afterNoteId); edge case of end just uses an empty adterNoteId). Pin promotes to the top. Pins utilize the same reordered system!

Each note has its own stream. NoteId is not stored inside these events, noteId is scoped from its stream name: 'note_$streamid'. Tags are also in this stream. Their global list is just a sideeffect.

seqId is used for replays. ON start up, all events are replayed sequentially. When notes are time traveled though, the database wrapper exists in memory and it allows to see the state of all changes.

Forks is what i need. Since streams are broken out, conflicts exist on PER stream basis. Should each event have a timestamp? If so, i simply need to handle all edge cases for majority of conflicts. In some cases user action is needed. As a rule, first to resolve a conflict and submit it wins, multiple diverging conflict resolutions are punished by timestamp. Most conflicts are resolved with timestamp...

Just global coordinator needed. Just specify what events to play until when, and insert new ones in the middle in global order as EXPLICIT conflict resolve events.

Tags are a json map, where key is tag name, and value is count. When count reaches zero, the tag is removed. This should not be sql! All is stored as just blobs. In this experiment Im gonna use nosql on purpose!

Notes are just full nosql content.

Alternative databases:

Best to worst
- [isar](https://pub.dev/packages/isar). Pretty good, but no union support, as in sealed. Plus heavy on code generation. Still uses ffi for "performance" reasons.
- [objectbox](https://pub.dev/packages/objectbox) meh
