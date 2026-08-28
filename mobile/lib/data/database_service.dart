import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'neuroassist_offline.db');

    return await openDatabase(
      path,
      version: 2, // UPGRADED VERSION TO 2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add reminders table if upgrading from version 1
      await db.execute('''
        CREATE TABLE reminders(
          id TEXT PRIMARY KEY,
          title TEXT,
          time_hour INTEGER,
          time_minute INTEGER,
          is_active INTEGER,
          last_triggered_date TEXT
        )
      ''');
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE patients(
        id TEXT PRIMARY KEY,
        name TEXT,
        baseline_difficulty INTEGER,
        created_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE game_sessions(
        id TEXT PRIMARY KEY,
        patient_id TEXT,
        game_type TEXT,
        score INTEGER,
        response_time_ms INTEGER,
        errors INTEGER,
        timestamp TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_events(
        id TEXT PRIMARY KEY,
        payload_type TEXT,
        payload_json TEXT,
        status TEXT,
        created_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE reminders(
        id TEXT PRIMARY KEY,
        title TEXT,
        time_hour INTEGER,
        time_minute INTEGER,
        is_active INTEGER,
        last_triggered_date TEXT
      )
    ''');
  }
}