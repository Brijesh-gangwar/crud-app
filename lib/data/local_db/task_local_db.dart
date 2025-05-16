import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';

class TaskLocalDb {
  static final TaskLocalDb instance = TaskLocalDb._init();
  static Database? _database;

  TaskLocalDb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');

    _database = await openDatabase(
      path,
      version: 2, // Ensure version matches schema
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
    return _database!;
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        userId TEXT,
        title TEXT,
        description TEXT,
        status TEXT,
        createdDate TEXT,
        priority INTEGER
      )
    ''');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN userId TEXT');
    }
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toJson(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final result = await db.query('tasks');
    return result.map((e) => Task.fromJson(e)).toList();
  }

  Future<List<Task>> getTasksByUser(String userId) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.map((e) => Task.fromJson(e)).toList();
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('tasks');
  }
}
