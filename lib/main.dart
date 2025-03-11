import 'package:notes_v0_2/db.dart';
import 'package:notes_v0_2/id.dart';

void main() async {
  final db = Db(deviceUid: DeviceUid(0)); // device id 0 is 111

  await db.init();

  await db.eventLogAppend(streamName: "test", data: '{"hello": "world1"}');
  await db.eventLogAppend(streamName: "test", data: '{"hello": "world2"}');
  await db.eventLogAppend(streamName: "another", data: '{"hello": "world3"}');
  // Close database to release resources
  //
  await Future<void>.delayed(Duration(milliseconds: 1000));
  await db.deinit();
}
