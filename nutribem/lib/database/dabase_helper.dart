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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE refeicoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        tipo TEXT,
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

  // MÉTODO DE INSERT
  Future<int> insertRefeicao(Refeicao refeicao) async {
    final db = await instance.database;
    return await db.insert('refeicoes', refeicao.toMap());
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
    return await db.delete(
      'refeicoes',
      where: 'id = ?',
      whereArgs: [id],
    );
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
}
