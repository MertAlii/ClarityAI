import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:clarity_ai/models/note.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('clarity_ai.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  reference_text TEXT NOT NULL,
  transcript TEXT,
  score REAL,
  target_audience TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE chat_messages (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  is_user INTEGER NOT NULL,
  timestamp TEXT NOT NULL,
  note_references TEXT
)
''');
  }

  // --- NOTES ---
  Future<int> insertNote(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getAllNotes() async {
    final db = await instance.database;
    final result = await db.query('notes', orderBy: 'created_at DESC');
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<Note?> getNoteById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'notes',
      columns: ['id', 'title', 'reference_text', 'transcript', 'score', 'target_audience', 'created_at'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CHAT MESSAGES ---
  Future<void> insertChatMessage(ChatMessage msg) async {
    final db = await instance.database;
    await db.insert('chat_messages', msg.toMap());
  }

  Future<List<ChatMessage>> getChatMessages({int limit = 50}) async {
    final db = await instance.database;
    final result = await db.query('chat_messages', orderBy: 'timestamp ASC', limit: limit);
    return result.map((json) => ChatMessage.fromMap(json)).toList();
  }

  Future<void> clearChat() async {
    final db = await instance.database;
    await db.delete('chat_messages');
  }
}
