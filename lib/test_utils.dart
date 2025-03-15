import 'package:notes_v0_2/common/db.dart';
import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/notes/events.dart';
import 'package:notes_v0_2/notes/repo.dart';
import 'package:notes_v0_2/notes/resolver.dart';
import 'package:notes_v0_2/notes/storage.dart';
import 'package:notes_v0_2/system/models.dart';
import 'package:notes_v0_2/system/repo.dart';

// this is a test_util function, nothing more or lses
Future<void> testSaveEventLogAndResolve(
  SystemRepo sysRepo,
  NotesResolver resolver,
  EventLogMinimal min,
) async {
  await sysRepo.eventLogAppend(min);
  final notesEvent = min.event as NotesEvent;
  await resolver.handleEvent(min.stream, notesEvent);
}

// more convenient test function
// tests default to flushing after every operation
Future<void> testApplyEventLog(
  TestAllSystemsInOne aio,
  EventLogMinimal min, {
  flush = true,
  appendLog = false,
}) async {
  if (appendLog) {
    await aio.sysRepo.eventLogAppend(min);
  }
  final notesEvent = min.event as NotesEvent;
  await aio.notesResolver.handleEvent(min.stream, notesEvent);
  if (flush) {
    await aio.notesRepo.flush();
  }
}

class TestAllSystemsInOne {
  late Db sysDb;
  late SystemRepo sysRepo;

  late Db notesDb;
  late NotesStorage notesStorage;
  late NotesRepo notesRepo;
  late NotesResolver notesResolver;

  TestAllSystemsInOne({DeviceId? deviceId}) {
    sysDb = Db.temporary();
    sysRepo = SystemRepo(sysDb.underlyingDb, deviceId ?? DeviceId(0));

    notesDb = Db.temporary();
    notesStorage = NotesStorage(notesDb.underlyingDb);
    notesRepo = NotesRepo(notesStorage);
    notesResolver = NotesResolver(notesRepo);
  }
  Future<void> init() async {
    await sysRepo.init();
    await notesStorage.migrate();
  }

  Future<void> deinit() async {
    await sysDb.deinit();
    await notesDb.deinit();
  }
}
