// DatabaseService — local SQLite persistence for the 14-day behavioral
// program, focus score history, rules, and milestones.
//
// All data stays ON-DEVICE. No network calls. No analytics. This is a hard
// requirement for Google Play accessibility-service declaration and for
// Apple's privacy data flow narrative.

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  static const int _version = 1;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'screentime_blocker.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Daily focus score record.
    await db.execute('''
      CREATE TABLE focus_score (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        date        TEXT NOT NULL UNIQUE,
        score       INTEGER NOT NULL,
        pickups     INTEGER NOT NULL,
        notifications INTEGER NOT NULL,
        blocked_minutes INTEGER NOT NULL,
        created_at  INTEGER NOT NULL
      )
    ''');

    // Configured schedules (Rules Engine).
    await db.execute('''
      CREATE TABLE rules (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        kind        TEXT NOT NULL,         -- 'scheduled' | 'manual'
        days_mask   INTEGER NOT NULL,     -- bitmask Mon..Sun
        start_min   INTEGER NOT NULL,     -- minutes since 00:00
        end_min     INTEGER NOT NULL,
        deep_focus INTEGER NOT NULL DEFAULT 0,
        active      INTEGER NOT NULL DEFAULT 1,
        created_at  INTEGER NOT NULL
      )
    ''');

    // Unlocked milestone gems.
    await db.execute('''
      CREATE TABLE milestones (
        id          TEXT PRIMARY KEY,
        day         INTEGER NOT NULL,
        unlocked_at INTEGER NOT NULL,
        shared      INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Onboarding diagnostic answers.
    await db.execute('''
      CREATE TABLE diagnostics (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ---- Focus Score ---------------------------------------------------------

  Future<int> upsertFocusScore({
    required String date,
    required int score,
    required int pickups,
    required int notifications,
    required int blockedMinutes,
  }) async {
    final database = await db;
    return database.insert(
      'focus_score',
      {
        'date': date,
        'score': score,
        'pickups': pickups,
        'notifications': notifications,
        'blocked_minutes': blockedMinutes,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> focusScoreLast(int days) async {
    final database = await db;
    return database.query(
      'focus_score',
      orderBy: 'date DESC',
      limit: days,
    );
  }

  // ---- Rules ---------------------------------------------------------------

  Future<int> insertRule(Map<String, Object?> rule) async {
    final database = await db;
    return database.insert('rules', rule,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> allRules() async {
    final database = await db;
    return database.query('rules', orderBy: 'created_at DESC');
  }

  Future<int> deleteRule(String id) async {
    final database = await db;
    return database.delete('rules', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Milestones ----------------------------------------------------------

  Future<int> unlockMilestone(String id, int day) async {
    final database = await db;
    return database.insert(
      'milestones',
      {
        'id': id,
        'day': day,
        'unlocked_at': DateTime.now().millisecondsSinceEpoch,
        'shared': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, Object?>>> unlockedMilestones() async {
    final database = await db;
    return database.query('milestones', orderBy: 'day ASC');
  }

  // ---- Diagnostics ---------------------------------------------------------

  Future<int> setDiagnostic(String key, String value) async {
    final database = await db;
    return database.insert(
      'diagnostics',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> diagnostic(String key) async {
    final database = await db;
    final rows = await database.query('diagnostics',
        where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }
}
