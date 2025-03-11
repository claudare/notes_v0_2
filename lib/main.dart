import 'package:notes_v0_2/db.dart';
import 'package:notes_v0_2/id.dart';

void main() async {
  final db = Db(deviceUid: DeviceUid(0)); // device id 0 is 111

  await db.init();

  // Close database to release resources
  await db.deinit();
}
