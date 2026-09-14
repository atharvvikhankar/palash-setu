import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/seed_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    Directory docsDir = await getApplicationDocumentsDirectory();
    String path = join(docsDir.path, 'palash_setu.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE correction_entries ADD COLUMN language TEXT NOT NULL DEFAULT 'sat_Olck'");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Teacher Profile Table
    await db.execute('''
      CREATE TABLE teacher_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        mobile TEXT,
        uiLanguage TEXT NOT NULL DEFAULT 'en',
        contentPair TEXT NOT NULL DEFAULT 'hi-sat',
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. Lessons Table
    await db.execute('''
      CREATE TABLE lessons (
        id TEXT PRIMARY KEY,
        grade INTEGER NOT NULL,
        subject TEXT NOT NULL,
        type TEXT NOT NULL,
        hindiText TEXT NOT NULL,
        santaliText TEXT,
        phoneticGuide TEXT,
        santaliAudioRef TEXT,
        confidence TEXT,
        outcomeIds TEXT
      )
    ''');

    // 3. Vocabulary Entries Table
    await db.execute('''
      CREATE TABLE vocabulary_entries (
        id TEXT PRIMARY KEY,
        hindiWord TEXT NOT NULL,
        santaliWord TEXT,
        phoneticGuide TEXT,
        category TEXT NOT NULL,
        santaliAudioRef TEXT,
        iconRef TEXT,
        confidence TEXT
      )
    ''');

    // 4. Outcomes Table
    await db.execute('''
      CREATE TABLE outcomes (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    // 5. Correction Entries Table
    await db.execute('''
      CREATE TABLE correction_entries (
        id TEXT PRIMARY KEY,
        sourceText TEXT NOT NULL,
        originalOutput TEXT NOT NULL,
        correctedOutput TEXT NOT NULL,
        correctorType TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'sat_Olck',
        syncedToServer INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // 6. App Settings Table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed Data Initialization
    for (var lesson in SeedData.lessons) {
      await db.insert('lessons', lesson);
    }
    for (var voc in SeedData.vocabulary) {
      await db.insert('vocabulary_entries', voc);
    }
    for (var outcome in SeedData.outcomes) {
      await db.insert('outcomes', outcome);
    }
  }

  // --- QUERY METHODS ---

  Future<List<Map<String, dynamic>>> getLessons({int? grade, String? subject}) async {
    final db = await database;
    String where = '';
    List<dynamic> args = [];
    if (grade != null) {
      where += 'grade = ?';
      args.add(grade);
    }
    if (subject != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'subject = ?';
      args.add(subject);
    }
    return await db.query('lessons', where: where.isNotEmpty ? where : null, whereArgs: args.isNotEmpty ? args : null);
  }

  Future<List<Map<String, dynamic>>> getVocabulary({String? category}) async {
    final db = await database;
    if (category != null && category.isNotEmpty) {
      return await db.query('vocabulary_entries', where: 'category = ?', whereArgs: [category]);
    }
    return await db.query('vocabulary_entries');
  }

  Future<Map<String, dynamic>?> searchTranslation(String text) async {
    final db = await database;
    String cleanText = text.trim().toLowerCase();
    
    // Check lessons first
    List<Map<String, dynamic>> lessonMatches = await db.query(
      'lessons',
      where: 'LOWER(hindiText) LIKE ? OR LOWER(santaliText) LIKE ?',
      whereArgs: ['%$cleanText%', '%$cleanText%'],
      limit: 1,
    );
    if (lessonMatches.isNotEmpty) {
      return lessonMatches.first;
    }

    // Check vocabulary
    List<Map<String, dynamic>> vocMatches = await db.query(
      'vocabulary_entries',
      where: 'LOWER(hindiWord) LIKE ? OR LOWER(santaliWord) LIKE ?',
      whereArgs: ['%$cleanText%', '%$cleanText%'],
      limit: 1,
    );
    if (vocMatches.isNotEmpty) {
      final v = vocMatches.first;
      return {
        'hindiText': v['hindiWord'],
        'santaliText': v['santaliWord'],
        'phoneticGuide': v['phoneticGuide'],
        'santaliAudioRef': v['santaliAudioRef'],
        'confidence': v['confidence'],
      };
    }
    return null;
  }

  Future<void> saveCorrection({
    required String id,
    required String sourceText,
    required String originalOutput,
    required String correctedOutput,
    required String correctorType,
    required String language,
  }) async {
    final db = await database;
    await db.insert('correction_entries', {
      'id': id,
      'sourceText': sourceText,
      'originalOutput': originalOutput,
      'correctedOutput': correctedOutput,
      'correctorType': correctorType,
      'language': language,
      'syncedToServer': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCorrections() async {
    final db = await database;
    return await db.query('correction_entries', where: 'syncedToServer = 0');
  }

  Future<void> markCorrectionsSynced(List<String> ids) async {
    final db = await database;
    for (String id in ids) {
      await db.update('correction_entries', {'syncedToServer': 1}, where: 'id = ?', whereArgs: [id]);
    }
  }

  /// Attempts to sync unsynced corrections to the backend
  Future<void> syncCorrectionsToServer(String backendUrl) async {
    final unsynced = await getUnsyncedCorrections();
    if (unsynced.isEmpty) return;

    try {
      final dio = Dio();
      final response = await dio.post(
        '$backendUrl/api/corrections/sync',
        data: {'corrections': unsynced},
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final List<String> idsToMark = unsynced.map((e) => e['id'] as String).toList();
        await markCorrectionsSynced(idsToMark);
        debugPrint('Synced \${idsToMark.length} corrections to Community Corpus.');
      }
    } catch (e) {
      debugPrint('Failed to sync corrections: \$e');
    }
  }
}
