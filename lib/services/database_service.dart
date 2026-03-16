import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/water_log.dart';
import '../models/drink_type.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'water_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE drink_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        emoji TEXT NOT NULL,
        color_hex TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE water_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        amount_ml INTEGER NOT NULL,
        drink_type TEXT NOT NULL,
        note TEXT
      )
    ''');

    // Seed drink types
    final types = [
      {'name': 'น้ำเปล่า', 'emoji': '💧', 'color_hex': '#2196F3'},
      {'name': 'น้ำผลไม้', 'emoji': '🍊', 'color_hex': '#FF9800'},
      {'name': 'ชา', 'emoji': '🍵', 'color_hex': '#8BC34A'},
      {'name': 'กาแฟ', 'emoji': '☕', 'color_hex': '#795548'},
      {'name': 'นม', 'emoji': '🥛', 'color_hex': '#E3F2FD'},
      {'name': 'น้ำอัดลม', 'emoji': '🥤', 'color_hex': '#F44336'},
      {'name': 'เครื่องดื่มชูกำลัง', 'emoji': '⚡', 'color_hex': '#FFC107'},
      {'name': 'น้ำมะพร้าว', 'emoji': '🥥', 'color_hex': '#4CAF50'},
    ];

    for (var t in types) {
      await db.insert('drink_types', t);
    }

    // Seed sample water logs (10+ records)
    final now = DateTime.now();
    final logs = [
      {'date': _dateStr(now), 'time': '07:00', 'amount_ml': 300, 'drink_type': 'น้ำเปล่า', 'note': 'ตื่นนอน'},
      {'date': _dateStr(now), 'time': '09:30', 'amount_ml': 250, 'drink_type': 'กาแฟ', 'note': ''},
      {'date': _dateStr(now), 'time': '11:00', 'amount_ml': 400, 'drink_type': 'น้ำเปล่า', 'note': ''},
      {'date': _dateStr(now), 'time': '13:00', 'amount_ml': 350, 'drink_type': 'น้ำผลไม้', 'note': 'หลังอาหาร'},
      {'date': _dateStr(now), 'time': '15:30', 'amount_ml': 200, 'drink_type': 'ชา', 'note': 'ชาเขียว'},
      {'date': _dateStr(now.subtract(const Duration(days: 1))), 'time': '08:00', 'amount_ml': 300, 'drink_type': 'น้ำเปล่า', 'note': ''},
      {'date': _dateStr(now.subtract(const Duration(days: 1))), 'time': '10:00', 'amount_ml': 500, 'drink_type': 'น้ำเปล่า', 'note': 'หลังออกกำลังกาย'},
      {'date': _dateStr(now.subtract(const Duration(days: 1))), 'time': '12:00', 'amount_ml': 250, 'drink_type': 'นม', 'note': ''},
      {'date': _dateStr(now.subtract(const Duration(days: 1))), 'time': '14:00', 'amount_ml': 330, 'drink_type': 'น้ำอัดลม', 'note': ''},
      {'date': _dateStr(now.subtract(const Duration(days: 2))), 'time': '07:30', 'amount_ml': 300, 'drink_type': 'น้ำเปล่า', 'note': ''},
      {'date': _dateStr(now.subtract(const Duration(days: 2))), 'time': '09:00', 'amount_ml': 200, 'drink_type': 'กาแฟ', 'note': 'ลาเต้'},
      {'date': _dateStr(now.subtract(const Duration(days: 2))), 'time': '14:00', 'amount_ml': 400, 'drink_type': 'น้ำมะพร้าว', 'note': 'สดชื่น'},
      {'date': _dateStr(now.subtract(const Duration(days: 3))), 'time': '08:00', 'amount_ml': 350, 'drink_type': 'น้ำเปล่า', 'note': ''},
      {'date': _dateStr(now.subtract(const Duration(days: 3))), 'time': '11:00', 'amount_ml': 250, 'drink_type': 'ชา', 'note': 'ชาดำ'},
    ];

    for (var log in logs) {
      await db.insert('water_logs', log);
    }
  }

  String _dateStr(DateTime d) => d.toIso8601String().split('T')[0];

  // ---- DrinkType CRUD ----
  Future<List<DrinkType>> getDrinkTypes() async {
    final db = await database;
    final maps = await db.query('drink_types', orderBy: 'name');
    return maps.map((m) => DrinkType.fromMap(m)).toList();
  }

  // ---- WaterLog CRUD ----
  Future<int> insertLog(WaterLog log) async {
    final db = await database;
    return await db.insert('water_logs', log.toMap()..remove('id'));
  }

  Future<int> updateLog(WaterLog log) async {
    final db = await database;
    return await db.update(
      'water_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteLog(int id) async {
    final db = await database;
    return await db.delete('water_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WaterLog>> getAllLogs() async {
    final db = await database;
    final maps = await db.query('water_logs', orderBy: 'date DESC, time DESC');
    return maps.map((m) => WaterLog.fromMap(m)).toList();
  }

  Future<List<WaterLog>> getLogsByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'water_logs',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'time DESC',
    );
    return maps.map((m) => WaterLog.fromMap(m)).toList();
  }

  Future<List<WaterLog>> getLogsByDrinkType(String type) async {
    final db = await database;
    final maps = await db.query(
      'water_logs',
      where: 'drink_type = ?',
      whereArgs: [type],
      orderBy: 'date DESC, time DESC',
    );
    return maps.map((m) => WaterLog.fromMap(m)).toList();
  }

  Future<List<WaterLog>> searchLogs({String? date, String? drinkType}) async {
    final db = await database;
    String where = '';
    List<dynamic> args = [];

    if (date != null && date.isNotEmpty) {
      where += 'date = ?';
      args.add(date);
    }
    if (drinkType != null && drinkType.isNotEmpty && drinkType != 'ทั้งหมด') {
      if (where.isNotEmpty) where += ' AND ';
      where += 'drink_type = ?';
      args.add(drinkType);
    }

    final maps = await db.query(
      'water_logs',
      where: where.isEmpty ? null : where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, time DESC',
    );
    return maps.map((m) => WaterLog.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;

    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM water_logs');
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    final totalAmountResult = await db.rawQuery('SELECT SUM(amount_ml) as total FROM water_logs');
    final totalAmount = totalAmountResult.first['total'] as int? ?? 0;

    final typeStats = await db.rawQuery(
      'SELECT drink_type, COUNT(*) as count, SUM(amount_ml) as total FROM water_logs GROUP BY drink_type ORDER BY total DESC',
    );

    final dateStats = await db.rawQuery(
      'SELECT date, SUM(amount_ml) as total FROM water_logs GROUP BY date ORDER BY date DESC LIMIT 7',
    );

    final distinctDays = await db.rawQuery('SELECT COUNT(DISTINCT date) as days FROM water_logs');
    final days = Sqflite.firstIntValue(distinctDays) ?? 1;
    final avgPerDay = days > 0 ? totalAmount ~/ days : 0;

    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final todayResult = await db.rawQuery(
      'SELECT SUM(amount_ml) as total FROM water_logs WHERE date = ?',
      [todayStr],
    );
    final todayTotal = todayResult.first['total'] as int? ?? 0;

    return {
      'totalCount': totalCount,
      'totalAmount': totalAmount,
      'avgPerDay': avgPerDay,
      'todayTotal': todayTotal,
      'typeStats': typeStats,
      'dateStats': dateStats,
    };
  }
}
