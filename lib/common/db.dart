import 'dart:io';
import 'dart:math';

import 'package:sqlite_async/sqlite_async.dart';

class Db {
  late SqliteDatabase db;
  String? tempPath;

  Db(String path) : db = SqliteDatabase(path: path);

  Db.temporary() {
    tempPath = _tempDbPath();
    db = SqliteDatabase(path: tempPath);
  }

  Future<void> deinit() async {
    await db.close();

    if (tempPath != null) {
      _tempDbCleanup(tempPath!);
    }
  }
}

const _tempDir = '/tmp/sqlite-db';

//https://github.com/powersync-ja/sqlite_async.dart/discussions/13
String _tempDbPath() {
  final random = Random.secure();
  final chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final length = 10;
  String filename = '';
  for (int i = 0; i < length; i++) {
    filename += chars[random.nextInt(chars.length)];
  }
  Directory(_tempDir).createSync(recursive: false);
  return '$_tempDir/$filename';
}

Future<void> _tempDbCleanup(String path) async {
  try {
    await File(path).delete();
  } on PathNotFoundException {
    // Not an issue
  }
  try {
    await File("$path-shm").delete();
  } on PathNotFoundException {
    // Not an issue
  }
  try {
    await File("$path-wal").delete();
  } on PathNotFoundException {
    // Not an issue
  }
}
