import 'package:notes_v0_2/app_db.dart';
import 'package:notes_v0_2/system_db.dart';
import 'package:notes_v0_2/system_models.dart';

Future<void> appendEventLogMinimalAndApply(
  SystemDb systemDb,
  AppDb appDb,
  EventLogMinimal min,
) async {
  await systemDb.eventLogAppend(min);

  try {
    await min.event.apply(min.streamId, appDb);
  } catch (err) {
    print('failed to apply event $err');
    // in prod, loud warning and traces are generated, but application must continue to operate
    // for now though, we just rethrow
    rethrow;
  }
}
