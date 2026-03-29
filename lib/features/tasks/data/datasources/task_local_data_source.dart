import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/task_model.dart';

abstract interface class TaskLocalDataSource {
  Future<List<TaskModel>> getAll();
  Future<void> insert(TaskModel model);
  Future<void> update(TaskModel model);
  Future<void> delete(String id);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  TaskLocalDataSourceImpl._();

  static final TaskLocalDataSourceImpl instance = TaskLocalDataSourceImpl._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    // sqflite_common_ffi works on Windows/Linux/macOS without symlinks.
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;

    final dbDir = join(
      Platform.environment['APPDATA'] ??
          Platform.environment['HOME'] ??
          '.',
      'flodo_tasks',
    );
    await Directory(dbDir).create(recursive: true);

    return factory.openDatabase(
      join(dbDir, 'flodo_tasks_v1.db'),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE tasks (
            id            TEXT    PRIMARY KEY,
            title         TEXT    NOT NULL,
            description   TEXT    NOT NULL,
            due_date_ms   INTEGER NOT NULL,
            status        TEXT    NOT NULL,
            blocked_by_id TEXT,
            created_at_ms INTEGER NOT NULL,
            sort_order    INTEGER NOT NULL DEFAULT 0
          )
        '''),
      ),
    );
  }

  @override
  Future<List<TaskModel>> getAll() async {
    final db = await _database;
    final rows = await db.query(
      'tasks',
      orderBy: 'sort_order ASC, created_at_ms ASC',
    );
    return rows.map(TaskModel.fromMap).toList();
  }

  @override
  Future<void> insert(TaskModel model) async {
    final db = await _database;
    await db.insert(
      'tasks',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(TaskModel model) async {
    final db = await _database;
    await db.update(
      'tasks',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _database;
    await db.update(
      'tasks',
      {'blocked_by_id': null},
      where: 'blocked_by_id = ?',
      whereArgs: [id],
    );
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
