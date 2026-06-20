import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/refeicao.dart';
import '../models/resumo_nutricional.dart';

class DatabaseHelper {
  static const _dbName = 'nutricao.db';
  static const _dbVersion = 1;
  static const _tabelaRefeicoes = 'refeicoes';

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final caminho = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      caminho,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tabelaRefeicoes (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        nome     TEXT    NOT NULL,
        descricao TEXT,
        tipo     TEXT,
        calorias REAL    NOT NULL DEFAULT 0,
        carbs    REAL    NOT NULL DEFAULT 0,
        proteina REAL    NOT NULL DEFAULT 0,
        gordura  REAL    NOT NULL DEFAULT 0,
        agua     REAL    NOT NULL DEFAULT 0,
        data     TEXT    NOT NULL,
        horario  TEXT
      )
    ''');
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<int> insertRefeicao(Refeicao refeicao) async {
    final db = await database;
    return await db.insert(_tabelaRefeicoes, refeicao.toMap());
  }

  Future<int> updateRefeicao(Refeicao refeicao) async {
    final db = await database;
    return await db.update(
      _tabelaRefeicoes,
      refeicao.toMap(),
      where: 'id = ?',
      whereArgs: [refeicao.id],
    );
  }

  Future<int> deleteRefeicao(int id) async {
    final db = await database;
    return await db.delete(
      _tabelaRefeicoes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── QUERIES ─────────────────────────────────────────────────────────────────

  /// Refeições de um dia específico, ordenadas por horário
  Future<List<Refeicao>> getRefeicoesPorData(String data) async {
    final db = await database;
    final rows = await db.query(
      _tabelaRefeicoes,
      where: 'data = ?',
      whereArgs: [data],
      orderBy: 'horario ASC',
    );
    return rows.map(Refeicao.fromMap).toList();
  }

  /// Soma dos macros/calorias/água de um dia (retorna zeros se não houver dados)
  Future<ResumoNutricional> getResumoNutricional(String data) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(calorias), 0) AS totalCalorias,
        COALESCE(SUM(carbs),    0) AS totalCarbs,
        COALESCE(SUM(proteina), 0) AS totalProteina,
        COALESCE(SUM(gordura),  0) AS totalGordura,
        COALESCE(SUM(agua),     0) AS totalAgua
      FROM $_tabelaRefeicoes
      WHERE data = ?
    ''', [data]);

    return ResumoNutricional.fromMap(rows.first);
  }

  /// Todas as refeições (para a tela "Ver todas")
  Future<List<Refeicao>> getAllRefeicoes() async {
    final db = await database;
    final rows = await db.query(
      _tabelaRefeicoes,
      orderBy: 'data DESC, horario ASC',
    );
    return rows.map(Refeicao.fromMap).toList();
  }
}