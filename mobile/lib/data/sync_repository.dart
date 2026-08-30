import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added import

class SyncRepository {
  static Database? _database;
  
  // Dynamically load the URL without nested quotes
  static String get _backendUrl {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';
    return '$baseUrl/api/sync';
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'neuroassist_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id TEXT NOT NULL,
            event_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Queues a new offline record locally with synced = 0 (false)
  Future<void> queueEvent(String eventId, String type, String payload) async {
    final db = await database;
    await db.insert('offline_events', {
      'event_id': eventId,
      'event_type': type,
      'payload': payload,
      'synced': 0,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Retrieves count of un-synced events
  Future<int> getPendingEventCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM offline_events WHERE synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Startup & On-Demand Sync: Checks for unsynced records and pushes to FastAPI backend
  Future<bool> pushToCloud() async {
    final db = await database;
    final List<Map<String, dynamic>> unsyncedRecords = await db.query(
      'offline_events',
      where: 'synced = ?',
      whereArgs: [0],
    );

    if (unsyncedRecords.isEmpty) return true;

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        // FIX: Wrap unsyncedRecords in the 'events' key expected by FastAPI
        body: jsonEncode({'events': unsyncedRecords}), 
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mark all records as synced on successful response
        for (var record in unsyncedRecords) {
          await db.update(
            'offline_events',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
        }
        return true;
      }
    } catch (_) {
      // Backend asleep or unreachable
    }
    return false;
  }
}