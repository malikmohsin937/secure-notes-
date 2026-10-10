import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'note.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Database? _database;

  Future<String> _getEncryptionKey() async {
    const keyName = 'secure_notes_database_key';

    String? key = await _secureStorage.read(key: keyName);

    if (key != null) {
      return key;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));

    key = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

    await _secureStorage.write(key: keyName, value: key);

    return key;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final key = await _getEncryptionKey();
    final directory = await getDatabasesPath();
    final dbPath = join(directory, 'secure_notes.db');

    _database = await openDatabase(
      dbPath,
      password: key,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  // CREATE
  Future<int> addNote(Note note) async {
    final db = await database;

    return db.insert('notes', note.toMap()..remove('id'));
  }

  // READ
  Future<List<Note>> getNotes({String search = ''}) async {
    final db = await database;

    final results = await db.query(
      'notes',
      where: search.trim().isEmpty ? null : 'title LIKE ?',
      whereArgs: search.trim().isEmpty ? null : ['%${search.trim()}%'],
      orderBy: 'id DESC',
    );

    return results.map(Note.fromMap).toList();
  }

  // UPDATE
  Future<int> updateNote(Note note) async {
    final db = await database;

    return db.update(
      'notes',
      note.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // DELETE
  Future<int> deleteNote(int id) async {
    final db = await database;

    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
