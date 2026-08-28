import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class Reminder {
  final String id;
  final String title;
  final int hour;
  final int minute;
  final bool isActive;
  final String lastTriggeredDate;

  Reminder({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.isActive,
    required this.lastTriggeredDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time_hour': hour,
      'time_minute': minute,
      'is_active': isActive ? 1 : 0,
      'last_triggered_date': lastTriggeredDate,
    };
  }
}

class ReminderRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> addReminder(Reminder reminder) async {
    final db = await _dbService.database;
    await db.insert('reminders', reminder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Reminder>> getActiveReminders() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'is_active = ?',
      whereArgs: [1],
    );

    return List.generate(maps.length, (i) {
      return Reminder(
        id: maps[i]['id'],
        title: maps[i]['title'],
        hour: maps[i]['time_hour'],
        minute: maps[i]['time_minute'],
        isActive: maps[i]['is_active'] == 1,
        lastTriggeredDate: maps[i]['last_triggered_date'],
      );
    });
  }

  Future<void> updateLastTriggered(String id, String dateStr) async {
    final db = await _dbService.database;
    await db.update(
      'reminders',
      {'last_triggered_date': dateStr},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteReminder(String id) async {
    final db = await _dbService.database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}