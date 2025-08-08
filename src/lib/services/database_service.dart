import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/calculation_models.dart';

class DatabaseService {
  static Database? _database;
  static const String tableName = 'my_accounts';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'interest_calculator.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        bankName TEXT NOT NULL,
        principal REAL NOT NULL,
        interestRate REAL NOT NULL,
        earlyTerminationRate REAL DEFAULT 0.0,
        earlyTerminationInterestType INTEGER DEFAULT 0,
        periodMonths INTEGER NOT NULL,
        startDate INTEGER NOT NULL,
        interestType INTEGER NOT NULL,
        accountType INTEGER NOT NULL,
        taxType INTEGER NOT NULL,
        customTaxRate REAL DEFAULT 0.0,
        monthlyDeposit REAL DEFAULT 0.0
      )
    ''');
  }

  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add earlyTerminationRate column
      await db.execute('ALTER TABLE $tableName ADD COLUMN earlyTerminationRate REAL DEFAULT 0.0');
    }
    if (oldVersion < 3) {
      // Add earlyTerminationInterestType column
      await db.execute('ALTER TABLE $tableName ADD COLUMN earlyTerminationInterestType INTEGER DEFAULT 0');
    }
  }

  static Future<int> insertAccount(MyAccount account) async {
    final db = await database;
    return await db.insert(tableName, account.toMap());
  }

  static Future<List<MyAccount>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) => MyAccount.fromMap(maps[i]));
  }

  static Future<MyAccount?> getAccount(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return MyAccount.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> updateAccount(MyAccount account) async {
    final db = await database;
    return await db.update(
      tableName,
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  static Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}