import 'dart:io';

import 'dart:async';

import 'package:path/path.dart';
import 'package:sounboard/database/sound_containter_details.dart';
import 'package:sounboard/database/sound_details.dart';
import 'package:sounboard/database/soundboard_details.dart';
import 'package:sqflite_common_porter/sqflite_porter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  final String soundDbFileName = "sounds.db";
  final String soundsTableName = "sounds";
  final String soundContainersTableName = "soundContainers";
  final String soundContainersToSoundsTableName = "soundContainersToSounds";
  final String soundboardsTableName = "soundboards";
  final String soundboardsToSoundContainersTableName =
      "soundboardsToSoundContainers";
  factory DbHelper() => _instance;

  static Database? _database;

  DbHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), soundDbFileName);
    // await deleteDatabase(path);
    return await openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE IF NOT EXISTS $soundsTableName ( "
          "    soundId INTEGER PRIMARY KEY AUTOINCREMENT,"
          "    name TEXT NOT NULL,"
          "    path TEXT NOT NULL);",
        );
        await db.execute(
          "CREATE TABLE IF NOT EXISTS $soundContainersTableName ("
          "    soundContainerId INTEGER PRIMARY KEY AUTOINCREMENT,"
          "    name TEXT NOT NULL,"
          "    shuffle BIT NOT NULL,"
          "    loop BIT NOT NULL);",
        );
        await db.execute(
          "CREATE TABLE IF NOT EXISTS $soundContainersToSoundsTableName ("
          "    soundContainerId INTEGER NOT NULL,"
          "    soundId INTEGER NOT NULL);",
        );
        await db.execute(
          "CREATE TABLE IF NOT EXISTS $soundboardsTableName ("
          "    soundboardId INTEGER PRIMARY KEY AUTOINCREMENT,"
          "    name TEXT NOT NULL);",
        );
        await db.execute(
          "CREATE TABLE IF NOT EXISTS $soundboardsToSoundContainersTableName ("
          "    soundboardId INTEGER NOT NULL,"
          "    soundContainerId INTEGER NOT NULL);",
        );
      },
      version: 1,
    );
  }

  Future<void> deleteDb() async {
    final path = join(await getDatabasesPath(), soundDbFileName);
    await deleteDatabase(path);
    final path2 = join(await getDatabasesPath(), "exercises.db");
    await deleteDatabase(path2);
  }

  Future<SoundDetails> insertSound(SoundDetails soundDetails) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      soundsTableName,
      where: "path = ?",
      whereArgs: [soundDetails.path],
    );

    if (maps.isNotEmpty) {
      return SoundDetails.fromMap(maps[0]);
    }

    int insertedId = await db.insert(
      soundsTableName,
      soundDetails.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    SoundDetails result = soundDetails.clone();
    result.soundId = insertedId;
    return result;
  }

  Future<SoundContainerDetails> insertSoundContainer(
    SoundContainerDetails soundContainerDetails,
  ) async {
    final db = await database;
    int insertedId = await db.insert(
      soundContainersTableName,
      soundContainerDetails.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    SoundContainerDetails result = soundContainerDetails.clone();
    result.soundContainerId = insertedId;
    return result;
  }

  Future<SoundboardDetails> insertSoundboard(
    SoundboardDetails soundboardDetails,
  ) async {
    final db = await database;
    int insertedId = await db.insert(
      soundboardsTableName,
      soundboardDetails.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    SoundboardDetails result = soundboardDetails.clone();
    result.soundboardId = insertedId;
    return result;
  }

  Future<void> insertSoundContainerToSoundMapping(
    int soundContainerId,
    SoundDetails soundDetails,
  ) async {
    if (soundDetails.soundId == null) {
      return;
    }

    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      soundContainersToSoundsTableName,
      where: "soundContainerId = ? AND soundId = ?",
      whereArgs: [soundContainerId, soundDetails.soundId!],
    );

    if (maps.isNotEmpty) {
      return;
    }

    await db.insert(soundContainersToSoundsTableName, {
      "soundContainerId": soundContainerId,
      "soundId": soundDetails.soundId!,
    });
  }

  Future<void> insertSoundboardToSoundContainerMapping(
    SoundboardDetails soundboardDetails,
    SoundContainerDetails soundContainerDetails,
  ) async {
    if (soundContainerDetails.soundContainerId == null ||
        soundboardDetails.soundboardId == null) {
      return;
    }
    final db = await database;
    await db.insert(soundboardsToSoundContainersTableName, {
      "soundboardId": soundboardDetails.soundboardId!,
      "soundContainerId": soundContainerDetails.soundContainerId!,
    });
  }

  Future<SoundDetails?> getSound(int soundId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      soundsTableName,
      where: "soundId = ?",
      whereArgs: [soundId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return SoundDetails.fromMap(maps[0]);
  }

  Future<List<SoundDetails>> getSounds({int? soundContainerId}) async {
    final db = await database;

    if (soundContainerId == null) {
      final List<Map<String, dynamic>> maps = await db.query(soundsTableName);

      return List.generate(maps.length, (i) => SoundDetails.fromMap(maps[i]));
    }

    final List<Map<String, dynamic>> soundContainerToSoundIdsMaps = await db
        .query(
          soundContainersToSoundsTableName,
          where: "soundContainerId = ?",
          whereArgs: [soundContainerId!],
        );

    final List<int> soundIds = List.generate(
      soundContainerToSoundIdsMaps.length,
      (i) => soundContainerToSoundIdsMaps[i]["soundId"],
    );

    final List<Map<String, dynamic>> soundsMaps = await db.query(
      soundsTableName,
      where: "soundId IN (${List.filled(soundIds.length, '?').join(',')})",
      whereArgs: soundIds,
    );

    return List.generate(
      soundsMaps.length,
      (i) => SoundDetails.fromMap(soundsMaps[i]),
    );
  }

  Future<SoundContainerDetails?> getSoundContainer(int soundContainerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      soundContainersTableName,
      where: "soundContainerId = ?",
      whereArgs: [soundContainerId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return SoundContainerDetails.fromMap(maps[0]);
  }

  Future<List<SoundContainerDetails>> getSoundContainers({
    SoundboardDetails? soundboardDetails,
  }) async {
    final db = await database;

    if (soundboardDetails == null || soundboardDetails.soundboardId == null) {
      final List<Map<String, dynamic>> maps = await db.query(
        soundContainersTableName,
      );

      return List.generate(
        maps.length,
        (i) => SoundContainerDetails.fromMap(maps[i]),
      );
    }

    final List<Map<String, dynamic>> soundboardToSoundContainerIdsMaps =
        await db.query(
          soundboardsToSoundContainersTableName,
          where: "soundboardId = ?",
          whereArgs: [soundboardDetails.soundboardId!],
        );

    final List<int> soundContainerIds = List.generate(
      soundboardToSoundContainerIdsMaps.length,
      (i) => soundboardToSoundContainerIdsMaps[i]["soundContainerId"],
    );

    final List<Map<String, dynamic>> soundContainersMaps = await db.query(
      soundContainersTableName,
      where:
          "soundContainerId IN (${List.filled(soundContainerIds.length, '?').join(',')})",
      whereArgs: soundContainerIds,
    );

    return List.generate(
      soundContainersMaps.length,
      (i) => SoundContainerDetails.fromMap(soundContainersMaps[i]),
    );
  }

  Future<List<SoundboardDetails>> getSoundboards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      soundboardsTableName,
    );

    return List.generate(
      maps.length,
      (i) => SoundboardDetails.fromMap(maps[i]),
    );
  }

  Future<void> updateSoundContainer(
    SoundContainerDetails soundContainerDetails,
  ) async {
    if (soundContainerDetails.soundContainerId == null) {
      return;
    }

    final db = await database;
    await db.update(
      soundContainersTableName,
      soundContainerDetails.toMap(),
      where: "soundContainerId = ?",
      whereArgs: [soundContainerDetails.soundContainerId!],
    );
  }

  Future<void> unmapSoundFromSoundContainer({
    required int soundId,
    required int soundContainerId,
  }) async {
    final db = await database;

    await db.delete(
      soundContainersToSoundsTableName,
      where: "soundContainerId = ? AND soundId = ?",
      whereArgs: [soundContainerId, soundId],
    );

    final List<Map<String, dynamic>> maps = await db.query(
      soundContainersToSoundsTableName,
      where: "soundId = ?",
      whereArgs: [soundId],
    );

    if (maps.isEmpty) {
      await db.delete(
        soundsTableName,
        where: "soundId = ?",
        whereArgs: [soundId],
      );
    }
  }

  Future<void> unmapSoundContainerFromSoundboard({
    required int soundboardId,
    required int soundContainerId,
  }) async {
    final db = await database;

    await db.delete(
      soundboardsToSoundContainersTableName,
      where: "soundboardId = ? AND soundContainerId = ?",
      whereArgs: [soundboardId, soundContainerId],
    );

    final List<Map<String, dynamic>> maps = await db.query(
      soundboardsToSoundContainersTableName,
      where: "soundContainerId = ?",
      whereArgs: [soundContainerId],
    );

    if (maps.isEmpty) {
      final List<Map<String, dynamic>> soundIdMaps = await db.query(
        soundContainersToSoundsTableName,
        columns: ["soundId"],
        where: "soundContainerId = ?",
        whereArgs: [soundContainerId],
      );

      for (var map in soundIdMaps) {
        await unmapSoundFromSoundContainer(
          soundContainerId: soundContainerId,
          soundId: map["soundId"],
        );
      }

      await db.delete(
        soundContainersTableName,
        where: "soundContainerId = ?",
        whereArgs: [soundContainerId],
      );
    }
  }

  // Future <void> removeExercise(int exerciseId) async {
  //   final db = await database;

  //   await db.delete(
  //     "exercises",
  //     where: "exerciseID = ?",
  //     whereArgs: [exerciseId]);

  //   await db.execute(
  //     "DROP TABLE IF EXISTS $_doneDatesTableNamePrefix$exerciseId;"
  //     "DROP TABLE IF EXISTS $_updatedDatesTableNamePrefix$exerciseId");
  // }

  Future<String> exportDatabase(String path) async {
    final db = await database;

    final export = await dbExportSql(db);
    // final Directory? downloadsDir = await getDownloadsDirectory();
    // if (downloadsDir != null) {
    final now = DateTime.now();
    File file = File(
      "/storage/emulated/0/Download/soundboardDbExport-${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}-${now.second}-${now.microsecond}.txt",
    );
    print("Exporting db to ${file.path}");

    file.writeAsString(export.join("\n"), mode: FileMode.writeOnlyAppend);
    return file.path;
    // }
    // return "NOT EXPORTED";
  }
}
