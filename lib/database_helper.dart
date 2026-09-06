import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseHelper {
  static final LocalDatabaseHelper instance = LocalDatabaseHelper._init();
  static Database? _database;

  LocalDatabaseHelper._init();

  // ============================================================
  // DATABASE INSTANCE
  // ============================================================

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('precispray_offline_v3.db');
    return _database!;
  }

  // ============================================================
  // DATABASE INITIALIZATION
  // ============================================================

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  // Enable foreign-key support
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ============================================================
  // CREATE DATABASE
  // ============================================================

  Future<void> _createDB(Database db, int version) async {
    // ==========================================================
    // USERS
    // ==========================================================
    //
    // "id" is the UNIQUE USER ID.
    //
    // Example:
    // Ryun   -> id = 1
    // Jaivir -> id = 2
    //
    // ==========================================================

    await db.execute('''
      CREATE TABLE app_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // ==========================================================
    // USER PROFILE
    // ==========================================================
    //
    // Each user can have ONE profile.
    //
    // user_id connects this profile to app_users.id
    //
    // ==========================================================

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        user_id INTEGER NOT NULL UNIQUE,

        name TEXT NOT NULL,
        age TEXT,
        crops TEXT,

        FOREIGN KEY (user_id)
          REFERENCES app_users(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      )
    ''');

    // ==========================================================
    // USER PLOTS
    // ==========================================================
    //
    // One user can have MULTIPLE plots.
    //
    // ==========================================================

    await db.execute('''
      CREATE TABLE user_plots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        user_id INTEGER NOT NULL,

        plot_name TEXT NOT NULL,
        area TEXT NOT NULL,

        FOREIGN KEY (user_id)
          REFERENCES app_users(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      )
    ''');
  }

  // ============================================================
  // AUTHENTICATION
  // ============================================================

  // Register a new user.
  //
  // Returns:
  //   user ID  -> successful registration
  //   null     -> registration failed / phone already exists
  //
  Future<int?> registerLocalUser(
    String phone,
    String password,
  ) async {
    final db = await instance.database;

    try {
      final userId = await db.insert(
        'app_users',
        {
          'phone': phone,
          'password': password,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return userId;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================
  //
  // Returns the complete user record.
  //
  // Example:
  //
  // {
  //   "id": 1,
  //   "phone": "9876...",
  //   "password": "..."
  // }
  //
  // The important value is "id".
  //
  // ============================================================

  Future<Map<String, dynamic>?> verifyLocalLogin(
    String phone,
    String password,
  ) async {
    final db = await instance.database;

    final result = await db.query(
      'app_users',
      where: 'phone = ? AND password = ?',
      whereArgs: [phone, password],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // ============================================================
  // PROFILE
  // ============================================================

  // Save or replace the profile of a specific user.
  Future<void> saveProfile(
    int userId,
    String name,
    String age,
    String crops,
  ) async {
    final db = await instance.database;

    await db.insert(
      'user_profile',
      {
        'user_id': userId,
        'name': name,
        'age': age,
        'crops': crops,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get the profile belonging to a specific user.
  Future<Map<String, dynamic>?> getProfile(
    int userId,
  ) async {
    final db = await instance.database;

    final result = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // Delete a specific user's profile.
  Future<void> deleteProfile(int userId) async {
    final db = await instance.database;

    await db.delete(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // FARM PLOTS
  // ============================================================

  // Add a plot for a specific user.
  Future<void> savePlot(
    int userId,
    String plotName,
    String area,
  ) async {
    final db = await instance.database;

    await db.insert(
      'user_plots',
      {
        'user_id': userId,
        'plot_name': plotName,
        'area': area,
      },
    );
  }

  // Get ONLY the plots belonging to a specific user.
  Future<List<Map<String, dynamic>>> getPlots(
    int userId,
  ) async {
    final db = await instance.database;

    return await db.query(
      'user_plots',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Delete ALL plots belonging to a specific user.
  Future<void> clearAllPlots(
    int userId,
  ) async {
    final db = await instance.database;

    await db.delete(
      'user_plots',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Delete ONE specific plot belonging to a specific user.
  Future<void> deletePlot(
    int userId,
    int plotId,
  ) async {
    final db = await instance.database;

    await db.delete(
      'user_plots',
      where: 'id = ? AND user_id = ?',
      whereArgs: [plotId, userId],
    );
  }
}