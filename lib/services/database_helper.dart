import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'worker_monitor.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE supervisors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supervisorId INTEGER NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        gender TEXT NOT NULL,
        age INTEGER NOT NULL,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        bmi REAL NOT NULL,
        photoPath TEXT,
        FOREIGN KEY (supervisorId) REFERENCES supervisors (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE monitoring_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supervisorId INTEGER NOT NULL,
        workerId INTEGER NOT NULL,
        windSpeed REAL NOT NULL,
        blackBallTemp REAL NOT NULL,
        ambientTemp REAL NOT NULL,
        humidity REAL NOT NULL,
        activityIntensity TEXT NOT NULL,
        pulse TEXT NOT NULL,
        clothing TEXT NOT NULL,
        workDuration REAL NOT NULL,
        heatStressIndex REAL NOT NULL,
        riskLevel TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (supervisorId) REFERENCES supervisors (id) ON DELETE CASCADE,
        FOREIGN KEY (workerId) REFERENCES workers (id) ON DELETE CASCADE
      )
    ''');
  }
}
