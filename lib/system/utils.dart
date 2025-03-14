import 'package:notes_v0_2/notes/repo.dart';
import 'package:notes_v0_2/system/models.dart';
import 'package:notes_v0_2/system/repo.dart';

// this is the function which crosses the system and app domain
// will need to think hard where to place it,
// i think resolver that takes in a system will be the best
Future<void> appendEventLogMinimalAndApply(
  SystemRepo systemDb,
  NotesRepo appDb,
  EventLogMinimal min,
) async {
  await systemDb.eventLogAppend(min);

  try {
    await min.event.apply(min.stream, appDb);
  } catch (err) {
    print('failed to apply event $err');
    // in prod, loud warning and traces are generated, but application must continue to operate
    // for now though, we just rethrow
    rethrow;
  }
}
