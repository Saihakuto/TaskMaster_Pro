import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('taskflow.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path, version: 4,
      onCreate: _createDB, onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN progress INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('''CREATE TABLE IF NOT EXISTS progress_statuses (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, percentage INTEGER NOT NULL DEFAULT 0)''');
    }
    if (oldVersion < 4) {
      await db.execute('''CREATE TABLE IF NOT EXISTS status_configs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key_name TEXT NOT NULL UNIQUE,
        label TEXT NOT NULL,
        color_value INTEGER NOT NULL
      )''');
      await _seedStatusConfigs(db);
    }
  }

  Future _seedStatusConfigs(Database db) async {
    final defaults = [
      {'key_name': 'pending', 'label': 'รอดำเนินการ', 'color_value': 0xFF607D8B},
      {'key_name': 'in_progress', 'label': 'กำลังทำ', 'color_value': 0xFFFF9800},
      {'key_name': 'completed', 'label': 'เสร็จแล้ว', 'color_value': 0xFF4CAF50},
    ];
    for (final s in defaults) {
      await db.insert('status_configs', s,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL, description TEXT NOT NULL,
      category_id INTEGER NOT NULL, due_date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      progress INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories(id))''');
    await db.execute('''CREATE TABLE progress_statuses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL, percentage INTEGER NOT NULL DEFAULT 0)''');
    await db.execute('''CREATE TABLE status_configs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key_name TEXT NOT NULL UNIQUE,
      label TEXT NOT NULL,
      color_value INTEGER NOT NULL)''');

    for (final name in ['งานบ้าน', 'งานเรียน', 'งานส่วนตัว', 'อื่นๆ']) {
      await db.insert('categories', {'name': name});
    }
    await _seedStatusConfigs(db);

    final now = DateTime.now();
    final samples = [
      {'title': 'ส่งรายงาน Flutter', 'description': 'ทำ final project ให้เสร็จ', 'category_id': 2, 'due_date': now.add(const Duration(days: 1)).toIso8601String(), 'status': 'in_progress', 'progress': 60, 'created_at': now.toIso8601String()},
      {'title': 'ซื้อของในตลาด', 'description': 'ผัก, ไข่, น้ำปลา', 'category_id': 1, 'due_date': now.add(const Duration(days: 2)).toIso8601String(), 'status': 'pending', 'progress': 0, 'created_at': now.toIso8601String()},
      {'title': 'ออกกำลังกาย', 'description': 'วิ่ง 30 นาที', 'category_id': 3, 'due_date': now.toIso8601String(), 'status': 'completed', 'progress': 100, 'created_at': now.toIso8601String()},
      {'title': 'อ่านหนังสือ', 'description': 'อ่าน Clean Code 1 บท', 'category_id': 3, 'due_date': now.add(const Duration(days: 3)).toIso8601String(), 'status': 'pending', 'progress': 0, 'created_at': now.toIso8601String()},
      {'title': 'นัดหมอ', 'description': 'ตรวจสุขภาพประจำปี', 'category_id': 4, 'due_date': now.add(const Duration(days: 5)).toIso8601String(), 'status': 'pending', 'progress': 0, 'created_at': now.toIso8601String()},
      {'title': 'เตรียมสไลด์นำเสนอ', 'description': 'Presentation วิชา Mobile App', 'category_id': 2, 'due_date': now.add(const Duration(days: 4)).toIso8601String(), 'status': 'in_progress', 'progress': 40, 'created_at': now.toIso8601String()},
      {'title': 'จ่ายค่าไฟ', 'description': 'โอนผ่านแอปธนาคาร', 'category_id': 4, 'due_date': now.add(const Duration(days: 7)).toIso8601String(), 'status': 'pending', 'progress': 0, 'created_at': now.toIso8601String()},
      {'title': 'ทำความสะอาดห้อง', 'description': 'กวาด ถู จัดของ', 'category_id': 1, 'due_date': now.add(const Duration(days: 2)).toIso8601String(), 'status': 'in_progress', 'progress': 30, 'created_at': now.toIso8601String()},
      {'title': 'ทบทวน Algorithm', 'description': 'ดู lecture ย้อนหลัง', 'category_id': 2, 'due_date': now.add(const Duration(days: 6)).toIso8601String(), 'status': 'completed', 'progress': 100, 'created_at': now.toIso8601String()},
      {'title': 'โทรหาครอบครัว', 'description': 'คุยกับพ่อแม่ทุกอาทิตย์', 'category_id': 3, 'due_date': now.add(const Duration(days: 1)).toIso8601String(), 'status': 'pending', 'progress': 0, 'created_at': now.toIso8601String()},
    ];
    for (final task in samples) {
      await db.insert('tasks', task);
    }
  }

  // ── Tasks ──────────────────────────────────────────
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap()..remove('id'));
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'due_date ASC');
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ── Categories ─────────────────────────────────────
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap()..remove('id'));
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── Progress Statuses ──────────────────────────────
  Future<List<ProgressStatus>> getAllProgressStatuses() async {
    final db = await database;
    final maps = await db.query('progress_statuses', orderBy: 'percentage ASC');
    return maps.map((m) => ProgressStatus.fromMap(m)).toList();
  }

  Future<int> insertProgressStatus(ProgressStatus ps) async {
    final db = await database;
    return await db.insert('progress_statuses', ps.toMap()..remove('id'));
  }

  Future<int> updateProgressStatus(ProgressStatus ps) async {
    final db = await database;
    return await db.update('progress_statuses', ps.toMap(), where: 'id = ?', whereArgs: [ps.id]);
  }

  Future<int> deleteProgressStatus(int id) async {
    final db = await database;
    return await db.delete('progress_statuses', where: 'id = ?', whereArgs: [id]);
  }

  // ── Status Configs ─────────────────────────────────
  Future<List<StatusConfig>> getAllStatusConfigs() async {
    final db = await database;
    final maps = await db.query('status_configs');
    return maps.map((m) => StatusConfig.fromMap(m)).toList();
  }

  Future<int> insertStatusConfig(StatusConfig sc) async {
    final db = await database;
    return await db.insert('status_configs', sc.toMap()..remove('id'));
  }

  Future<int> updateStatusConfig(StatusConfig sc) async {
    final db = await database;
    return await db.update('status_configs', sc.toMap(), where: 'id = ?', whereArgs: [sc.id]);
  }

  Future<int> deleteStatusConfig(int id) async {
    final db = await database;
    return await db.delete('status_configs', where: 'id = ?', whereArgs: [id]);
  }
} 