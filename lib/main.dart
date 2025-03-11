import 'package:notes_v0_2/db_app.dart';
import 'package:notes_v0_2/db_system.dart';
import 'package:notes_v0_2/id.dart';

void main() async {
  final dbSystem = DbSystem(deviceUid: DeviceUid(0)); // device id 0 is 111
  await dbSystem.init();

  final dbApp = DbApp(dbSystem.db);

  try {
    await dbSystem.eventLogAppend(
      streamName: "test",
      data: '{"hello": "world1"}',
    );
    await dbSystem.eventLogAppend(
      streamName: "test",
      data: '{"hello": "world2"}',
    );
    await dbSystem.eventLogAppend(
      streamName: "another",
      data: '{"hello": "world3"}',
    );

    await Future<void>.delayed(Duration(milliseconds: 1000));
  } finally {
    await dbSystem.deinit();
  }
}
