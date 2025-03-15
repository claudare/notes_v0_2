import 'package:notes_v0_2/common/stream.dart';

const streamNameGlobal = 'global';
const streamNameNoteOrder = 'note_order';
const streamNameNote = 'note';

// static (global) event names;
// I can check for equality on these ones! nice
const streamGlobal = Stream.named(streamNameGlobal);
const streamNoteOrder = Stream.named(streamNameNoteOrder);
