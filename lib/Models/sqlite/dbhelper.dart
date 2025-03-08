import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  bool _isInitializing = false;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // Dışarıdan çağrılabilecek public başlatma metodu
  Future<Database> initializeDatabase() async {
    return await database;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Eğer başka bir yerden eş zamanlı başlatma varsa bekle
    while (_isInitializing) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    // Hala null ise başlat
    if (_database == null) {
      _isInitializing = true;
      try {
        _database = await _initDatabase();
      } finally {
        _isInitializing = false;
      }
    }

    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Get the application documents directory
      var databasesPath = await getDatabasesPath();
      var path = join(databasesPath, "sqlite.db");

      // Check if the database exists
      var exists = await databaseExists(path);

      if (!exists) {
        print("Creating new copy from asset");

        // Make sure the parent directory exists
        try {
          await Directory(dirname(path)).create(recursive: true);
        } catch (e) {
          print("Error creating directory: $e");
        }

        // Copy from asset with timeout
        try {
          ByteData data = await rootBundle.load(join("assets/Model", "sqlite.db"))
              .timeout(Duration(seconds: 20),
              onTimeout: () => throw TimeoutException("Loading database asset timed out"));

          List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

          // Write and flush the bytes written with timeout
          await File(path).writeAsBytes(bytes, flush: true)
              .timeout(Duration(seconds: 30),
              onTimeout: () => throw TimeoutException("Writing database to device timed out"));

          print("Database copied from assets successfully");
        } catch (e) {
          print("Error copying database from assets: $e");
          rethrow; // Bu kritik bir hata, yukarı iletilmeli
        }
      } else {
        print("Opening existing database");
      }

      // Open the database with timeout
      return await openDatabase(
          path,
          readOnly: false,
          // Büyük veritabanı için daha uzun timeout süresi
      ).timeout(
          Duration(seconds: 15),
          onTimeout: () => throw TimeoutException("Opening database timed out")
      );
    } catch (e) {
      print("Database initialization error: $e");
      rethrow; // Hatayı yukarı ilet
    }
  }
  Future<List<String>> getTableNames(Database db) async {
    // SQLite main tablosundan tüm tablo isimlerini sorgula
    final List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'");

    // Tablo isimlerini bir liste olarak döndür
    return tables.map((table) => table['name'] as String).toList();
  }

  // Veritabanını kontrollü kapatma metodu
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Kullanıcıya gösterilebilecek veritabanı yükleme durumu için yardımcı metod
  static Future<bool> isDatabaseReady() async {
    try {
      var databasesPath = await getDatabasesPath();
      var path = join(databasesPath, "sqlite.db");
      return await databaseExists(path);
    } catch (e) {
      return false;
    }
  }

  // Veritabanı sorgulama metotları
  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWhere(String table, String whereClause, List<dynamic> whereArgs) async {
    Database db = await database;
    return await db.query(
      table,
      where: whereClause,
      whereArgs: whereArgs,
    );
  }

  // Tam metin arama için metot (FTS tabloları için)
  Future<List<Map<String, dynamic>>> fullTextSearch(String ftsTable, String query) async {
    Database db = await database;
    return await db.rawQuery(
        'SELECT * FROM $ftsTable WHERE $ftsTable MATCH ?',
        [query]
    );
  }

  // Veritabanı yükleme durumunu denetleyen metot
  Future<bool> checkDatabaseLoaded() async {
    try {
      Database db = await database;
      // Basit bir sorgu yaparak veritabanının çalışıp çalışmadığını kontrol et
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      print("Database check error: $e");
      return false;
    }
  }

  // Veritabanı boyutunu almak için metot
  Future<int> getDatabaseSize() async {
    try {
      var databasesPath = await getDatabasesPath();
      var path = join(databasesPath, "sqlite.db");
      File dbFile = File(path);
      if (await dbFile.exists()) {
        return await dbFile.length();
      }
      return 0;
    } catch (e) {
      print("Error getting database size: $e");
      return -1;
    }
  }

  // Veritabanı sürümünü kontrol eden metot
  Future<int> getDatabaseVersion() async {
    try {
      Database db = await database;
      return await db.getVersion();
    } catch (e) {
      print("Error getting database version: $e");
      return -1;
    }
  }
}