# notes_v0_2

Second attempt at this

Instead of

`f(event) -> []sqlstatements`

Do a direct nosql database mutation through a typed app db stateUpdater

`f(event, stateUpdater) -> stateUpdater()`

I will still use sqlite though. Create a dwrapper for all objects, make them queryable (sqlite actually has this). Never rouch raw database objects. As comic as it is, most of the application state tables will look like this:
```
id VARCHAR(19) PRIMARY KEY NOT NULL
data BLOB NOT NULL
```
Id is specially crafted for this purpose.

All events are stored inside a stream. All inside a stream.

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

Im gonna use `sqlite_async`. [bson](https://github.com/mongo-dart/bson/blob/main/example/object/object_serialize.dart) format could be interesting for data compression, but for now its low priority. Plus I dont like how the library requires that there is a global repository.

# Some definitions

There are also two codebases:
 - `client` is a strictly dart application that does all heavy lifting. Stores events and blobs.
 - `server` is central golang server that stores events and blobs, routes traffic between clients (with auth), exposes a public endpoint, and deals with backups. This uses heavy server-side storage systems such as postgres, redis, minio, etc... The server has no application logic at all. Its a dummy that facilites operation of many clients within one account. In the future, it could enable collaboration between servers of separate clients.

Each `client` has a role. There are two type of roles:
 - `app` is a flutter app. Full UI and everything.
 - `agent` is a dart app (since dart can ffi C pretty well) or a go backend application with strong data-access priviledges that runs on a powerful server. This takes heavy jobs away from the app clients such as thumbnail generation, video transcoding, AI things, etc. Ideally the app can do some of these tasks, but not all. There is a separate agent for each app or "task". Maybe can have a backup agent, which does simpler backups like the server.
