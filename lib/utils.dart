import 'package:notes_v0_2/app_db.dart';
import 'package:notes_v0_2/system_db.dart';
import 'package:notes_v0_2/system_models.dart';

Future<void> appendEventLogMinimalAndApply(
  SystemDb systemDb,
  AppDb appDb,
  EventLogMinimal min,
) async {
  print('doing event log min ${min.streamId}');
  await systemDb.eventLogAppend(min);
  await min.event.apply(min.streamId, appDb);
}
