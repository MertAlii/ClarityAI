import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:clarity_ai/models/v2_models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('clarity_ai_v3.db');
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
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        colorHex TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folderId INTEGER,
        title TEXT,
        targetAudience TEXT,
        score REAL,
        isStarred INTEGER,
        priority INTEGER,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE note_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        noteId INTEGER,
        type TEXT,
        title TEXT,
        content TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        noteId INTEGER,
        type TEXT,
        contentJson TEXT,
        score REAL,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE quizzes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        noteId INTEGER,
        type TEXT,
        contentJson TEXT,
        score REAL,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_sessions (
        id TEXT PRIMARY KEY,
        title TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        sessionId TEXT,
        noteId INTEGER,
        content TEXT,
        isUser INTEGER,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        dateStr TEXT,
        type TEXT,
        colorHex TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE token_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider TEXT,
        tokensUsed INTEGER,
        requestsCount INTEGER,
        quotaLimit INTEGER
      )
    ''');
  }

  // --- Folders ---
  Future<int> insertFolder(Folder folder) async {
    final db = await instance.database;
    return await db.insert('folders', folder.toMap());
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await instance.database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await instance.database;
    return await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await instance.database;
    final result = await db.query('folders', orderBy: 'createdAt DESC');
    return result.map((map) => Folder.fromMap(map)).toList();
  }

  // --- Notes ---
  Future<int> insertNote(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> getAllNotes({int? folderId}) async {
    final db = await instance.database;
    final where = folderId != null ? 'folderId = ?' : null;
    final whereArgs = folderId != null ? [folderId] : null;
    final result = await db.query(
      'notes',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getNoteById(int id) async {
    final db = await instance.database;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  // --- NoteMaterials ---
  Future<int> insertNoteMaterial(NoteMaterial material) async {
    final db = await instance.database;
    return await db.insert('note_materials', material.toMap());
  }

  Future<int> deleteNoteMaterial(int id) async {
    final db = await instance.database;
    return await db.delete('note_materials', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<NoteMaterial>> getMaterialsForNote(int noteId) async {
    final db = await instance.database;
    final result = await db.query(
      'note_materials',
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'createdAt ASC',
    );
    return result.map((map) => NoteMaterial.fromMap(map)).toList();
  }

  // --- AiReports ---
  Future<int> insertAiReport(AiReportData report) async {
    final db = await instance.database;
    return await db.insert('ai_reports', report.toMap());
  }

  Future<int> deleteAiReport(int id) async {
    final db = await instance.database;
    return await db.delete('ai_reports', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AiReportData>> getReportsForNote(int noteId) async {
    final db = await instance.database;
    final result = await db.query(
      'ai_reports',
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => AiReportData.fromMap(map)).toList();
  }

  // --- Quizzes ---
  Future<int> insertQuiz(QuizData quiz) async {
    final db = await instance.database;
    return await db.insert('quizzes', quiz.toMap());
  }

  Future<int> deleteQuiz(int id) async {
    final db = await instance.database;
    return await db.delete('quizzes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateQuizScore(int id, double score) async {
    final db = await instance.database;
    return await db.update(
      'quizzes',
      {'score': score},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<QuizData>> getQuizzesForNote(int noteId) async {
    final db = await instance.database;
    final result = await db.query(
      'quizzes',
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => QuizData.fromMap(map)).toList();
  }

  // --- ChatSessions ---
  Future<int> insertChatSession(ChatSession session) async {
    final db = await instance.database;
    return await db.insert('chat_sessions', session.toMap());
  }

  Future<int> deleteChatSession(String id) async {
    final db = await instance.database;
    return await db.delete('chat_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ChatSession>> getAllChatSessions() async {
    final db = await instance.database;
    final result = await db.query('chat_sessions', orderBy: 'createdAt DESC');
    return result.map((map) => ChatSession.fromMap(map)).toList();
  }

  // --- ChatMessages ---
  Future<int> insertChatMessage(ChatMessage message) async {
    final db = await instance.database;
    return await db.insert('chat_messages', message.toMap());
  }

  Future<List<ChatMessage>> getMessagesForSession(String sessionId) async {
    final db = await instance.database;
    final result = await db.query(
      'chat_messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return result.map((map) => ChatMessage.fromMap(map)).toList();
  }

  // --- Events ---
  Future<int> insertEvent(Event event) async {
    final db = await instance.database;
    return await db.insert('events', event.toMap());
  }

  Future<int> updateEvent(Event event) async {
    final db = await instance.database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await instance.database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Event>> getAllEvents() async {
    final db = await instance.database;
    final result = await db.query('events');
    return result.map((map) => Event.fromMap(map)).toList();
  }

  // --- TokenUsage ---
  Future<void> incrementTokenUsage(String provider, int tokens) async {
    final db = await instance.database;
    final usage = await getTokenUsage(provider);

    if (usage != null) {
      await db.update(
        'token_usage',
        {
          'tokensUsed': usage.tokensUsed + tokens,
          'requestsCount': usage.requestsCount + 1,
        },
        where: 'id = ?',
        whereArgs: [usage.id],
      );
    } else {
      await db.insert('token_usage', {
        'provider': provider,
        'tokensUsed': tokens,
        'requestsCount': 1,
        'quotaLimit': 0, // Default quota
      });
    }
  }

  Future<TokenUsage?> getTokenUsage(String provider) async {
    final db = await instance.database;
    final result = await db.query(
      'token_usage',
      where: 'provider = ?',
      whereArgs: [provider],
    );
    if (result.isNotEmpty) {
      return TokenUsage.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateQuota(String provider, int quota) async {
    final db = await instance.database;
    final usage = await getTokenUsage(provider);

    if (usage != null) {
      return await db.update(
        'token_usage',
        {'quotaLimit': quota},
        where: 'id = ?',
        whereArgs: [usage.id],
      );
    } else {
      return await db.insert('token_usage', {
        'provider': provider,
        'tokensUsed': 0,
        'requestsCount': 0,
        'quotaLimit': quota,
      });
    }
  }
}
