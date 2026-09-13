import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'baby_manager.db';
  static const int _databaseVersion = 1;

  static Database? _database;

  /// Returns the singleton database instance.
  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  /// Initializes the SQLite database.
  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the database schema.
  static Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE bottles (
        id TEXT PRIMARY KEY,
        child_id TEXT,

        feeding_started_at TEXT NOT NULL,
        feeding_ended_at TEXT,

        burping_started_at TEXT,
        burping_ended_at TEXT,

        volume REAL,
        volume_unit TEXT,

        type TEXT,

        notes TEXT,

        source TEXT NOT NULL,

        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Useful for queries by child.
    await db.execute('''
      CREATE INDEX idx_bottles_child_id
      ON bottles(child_id)
    ''');

    // Useful for displaying the bottle history.
    await db.execute('''
      CREATE INDEX idx_bottles_feeding_started_at
      ON bottles(feeding_started_at)
    ''');
  }

  /// Handles database migrations.
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Future migrations go here.
    //
    // Example:
    //
    // if (oldVersion < 2) {
    //   await db.execute(
    //     'ALTER TABLE bottles ADD COLUMN example TEXT',
    //   );
    // }
  }

  /// Closes the database.
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Deletes the entire database.
  ///
  /// Useful during development/testing.
  /// Do NOT use this as part of normal application flow.
  static Future<void> deleteDatabaseFile() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    await deleteDatabase(path);

    _database = null;
  }
}