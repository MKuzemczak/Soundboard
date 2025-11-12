import 'dart:io';

import 'dart:async';

import 'package:path/path.dart';
import 'package:sounboard/database/sound_details.dart';
import 'package:sqflite_common_porter/sqflite_porter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  final String soundsTableName = "sounds";
  final String soundDbFileName = "sounds.db";
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
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE $soundsTableName ( "
          "    soundId INTEGER PRIMARY KEY AUTOINCREMENT,"
          "    name TEXT NOT NULL,"
          "    path TEXT NOT NULL);"
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

  Future<SoundDetails> insertExercise(SoundDetails soundDetails) async {
    final db = await database;
    int insertedId = await db.insert(
      soundsTableName,
      soundDetails.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    SoundDetails result = soundDetails.clone();
    result.soundId = insertedId;
    return result;
  }

  // Future<bool> updateExercise(SoundDetails exercise) async {
  //   final db = await database;

  //   final List<Map<String, dynamic>> maps = await db.query(
  //     "exercises",
  //     where: "exerciseID = ?",
  //     whereArgs: [exercise.exerciseID]);

  //   if (maps.isEmpty)
  //   {
  //     return false;
  //   }

  //   Exercise exerciseFromDb = Exercise.fromMap(maps[0]);

  //   final bool exerciseChanged = exerciseFromDb.loadDetails.sets != exercise.loadDetails.sets
  //     || exerciseFromDb.loadDetails.repsPerSet != exercise.loadDetails.repsPerSet
  //     || exerciseFromDb.loadDetails.repLoad != exercise.loadDetails.repLoad
  //     || exerciseFromDb.loadDetails.interval != exercise.loadDetails.interval;

  //   await db.update(
  //     "exercises",
  //     exercise.toMap(),
  //     where: "exerciseID = ?",
  //     whereArgs: [exercise.exerciseID!],
  //   );

  //   return exerciseChanged;
  // }

  Future<SoundDetails?> getSound(int soundId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      soundsTableName,
      where: "soundId = ?",
      whereArgs: [soundId]);

    if (maps.isEmpty)
    {
      return null;
    }

    SoundDetails exerciseFromDb = SoundDetails.fromMap(maps[0]);

    return exerciseFromDb;
  }

  Future<List<SoundDetails>> getSounds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(soundsTableName);

    final output = List.generate(maps.length, (i) => SoundDetails.fromMap(maps[i]));

    return output;
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

  Future <String> exportDatabase(String path) async {
    final db = await database;

    final export = await dbExportSql(db);
    // final Directory? downloadsDir = await getDownloadsDirectory();
    // if (downloadsDir != null) {
    final now = DateTime.now();
    File file = File("/storage/emulated/0/Download/soundboardDbExport-${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}-${now.second}-${now.microsecond}.txt");
    print("Exporting db to ${file.path}");


    file.writeAsString(export.join("\n"), mode: FileMode.writeOnlyAppend);
    return file.path;
    // }
    // return "NOT EXPORTED";
  }
}
