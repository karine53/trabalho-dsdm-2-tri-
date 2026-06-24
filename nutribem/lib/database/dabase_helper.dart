import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/refeicao.dart';
import '../models/resumo_nutricional.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nutribem.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE refeicoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        tipo TEXT,
        categoria TEXT,
        calorias REAL NOT NULL,
        carbs REAL,
        proteina REAL,
        gordura REAL,
        agua REAL,
        data TEXT NOT NULL,
        horario TEXT
      )
    ''');
  }

  // ── Migração: adiciona a coluna "categoria" em bancos já existentes ────────
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE refeicoes ADD COLUMN categoria TEXT');
    }
  }

  // MÉTODO DE INSERT
  Future<int> insertRefeicao(Refeicao refeicao) async {
    final db = await instance.database;

    final id = await db.insert('refeicoes', refeicao.toMap());

    print('SALVOU ID: $id');

    return id;
  }

  // MÉTODO DE UPDATE (Necessário para a edição que criamos!)
  Future<int> updateRefeicao(Refeicao refeicao) async {
    final db = await instance.database;
    return await db.update(
      'refeicoes',
      refeicao.toMap(),
      where: 'id = ?',
      whereArgs: [refeicao.id],
    );
  }

  // MÉTODO DE DELETE
  Future<int> deleteRefeicao(int id) async {
    final db = await instance.database;
    return await db.delete('refeicoes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Refeicao>> getRefeicoesPorData(String data) async {
    final db = await instance.database;
    final maps = await db.query(
      'refeicoes',
      where: 'data = ?',
      whereArgs: [data],
      orderBy: 'horario ASC',
    );

    return List.generate(maps.length, (i) => Refeicao.fromMap(maps[i]));
  }

  Future<ResumoNutricional> getResumoNutricional(String data) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'refeicoes',
      where: 'data = ?',
      whereArgs: [data],
    );

    double cal = 0, carb = 0, prot = 0, gord = 0, agua = 0;
    for (var m in maps) {
      cal += (m['calorias'] as num).toDouble();
      carb += (m['carbs'] as num?)?.toDouble() ?? 0;
      prot += (m['proteina'] as num?)?.toDouble() ?? 0;
      gord += (m['gordura'] as num?)?.toDouble() ?? 0;
      agua += (m['agua'] as num?)?.toDouble() ?? 0;
    }

    return ResumoNutricional(
      totalCalorias: cal,
      totalCarbs: carb,
      totalProteina: prot,
      totalGordura: gord,
      totalAgua: agua,
    );
  }

  // ── Todas as refeições, mais recentes primeiro ──────────────────────────────
  Future<List<Refeicao>> getAllRefeicoes() async {
    final db = await instance.database;
    final maps = await db.query('refeicoes', orderBy: 'data DESC, horario ASC');
    return List.generate(maps.length, (i) => Refeicao.fromMap(maps[i]));
  }

  // ── Refeições dentro de um intervalo de datas (inclusive) ───────────────────
  // Usado no Histórico para os filtros "Esta semana" / "Este mês"
  Future<List<Refeicao>> getRefeicoesPorIntervalo(
    String dataInicio,
    String dataFim,
  ) async {
    final db = await instance.database;
    final maps = await db.query(
      'refeicoes',
      where: 'data BETWEEN ? AND ?',
      whereArgs: [dataInicio, dataFim],
      orderBy: 'data DESC, horario ASC',
    );
    return List.generate(maps.length, (i) => Refeicao.fromMap(maps[i]));
  }

  // ── Busca por nome ou descrição (barra de pesquisa do Histórico) ───────────
  // Pode ser combinada com um intervalo de datas.
  Future<List<Refeicao>> buscarRefeicoes(
    String termo, {
    String? dataInicio,
    String? dataFim,
  }) async {
    final db = await instance.database;
    final condicoes = <String>['(nome LIKE ? OR descricao LIKE ?)'];
    final args = <Object?>['%$termo%', '%$termo%'];

    if (dataInicio != null && dataFim != null) {
      condicoes.add('data BETWEEN ? AND ?');
      args.addAll([dataInicio, dataFim]);
    }

    final maps = await db.query(
      'refeicoes',
      where: condicoes.join(' AND '),
      whereArgs: args,
      orderBy: 'data DESC, horario ASC',
    );
    return List.generate(maps.length, (i) => Refeicao.fromMap(maps[i]));
  }
}
