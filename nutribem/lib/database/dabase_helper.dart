import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/refeicao.dart';
import '../models/resumo_nutricional.dart';
import '../models/configuraçoes.dart';

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

  final path = join(
    dbPath,
    filePath,
  );

  return await openDatabase(
    path,
    version: 3,
    onCreate: _createDB,
    onUpgrade: _upgradeDB,
  );
}

  Future _createDB(Database db, int version) async {
    print("Criando banco de dados...");
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

    await _createSettingsTable(db);
  }

  Future _createSettingsTable(Database db) async {
    print("Criando tabela de configurações...");
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY,
        notificationsEnabled INTEGER NOT NULL,
        waterReminderEnabled INTEGER NOT NULL,
        dailySummaryEnabled INTEGER NOT NULL,
        breakfastTime TEXT NOT NULL,
        lunchTime TEXT NOT NULL,
        snackTime TEXT NOT NULL,
        dinnerTime TEXT NOT NULL
      )
    ''');
    
    // Verifica se já existe o registro 1 para não duplicar no onUpgrade
    final List<Map<String, dynamic>> existing = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (existing.isEmpty) {
      print("Inserindo configurações padrão...");
      await db.insert('settings', AppSettings().toMap());
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print("Fazendo upgrade do banco de $oldVersion para $newVersion");
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE refeicoes ADD COLUMN categoria TEXT');
    }
    if (oldVersion < 3) {
      await _createSettingsTable(db);
    }
  }

  // --- MÉTODOS DE CONFIGURAÇÕES ---
  
  Future<AppSettings> getSettings() async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query('settings', where: 'id = ?', whereArgs: [1]);

      if (maps.isNotEmpty) {
        return AppSettings.fromMap(maps.first);
      } else {
        print("Configurações não encontradas, criando padrões...");
        final defaultSettings = AppSettings();
        await db.insert('settings', defaultSettings.toMap());
        return defaultSettings;
      }
    } catch (e) {
      print("Erro ao buscar configurações: $e");
      return AppSettings(); // Retorna padrões em caso de erro crítico
    }
  }

  Future<int> updateSettings(AppSettings settings) async {
    try {
      final db = await instance.database;
      return await db.update(
        'settings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [1],
      );
    } catch (e) {
      print("Erro ao atualizar configurações: $e");
      return 0;
    }
  }

  // --- MÉTODOS DE REFEIÇÃO ---

  Future<int> insertRefeicao(Refeicao refeicao) async {

  print("1 - entrou no insert");

  final db = await instance.database;

  print("2 - banco aberto");


  final id = await db.insert(
    'refeicoes',
    refeicao.toMap(),
  );


  print("3 - salvou id: $id");


  return id;
}

  Future<int> updateRefeicao(Refeicao refeicao) async {
    final db = await instance.database;
    return await db.update(
      'refeicoes',
      refeicao.toMap(),
      where: 'id = ?',
      whereArgs: [refeicao.id],
    );
  }

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

  Future<List<Refeicao>> getAllRefeicoes() async {
    final db = await instance.database;
    final maps = await db.query('refeicoes', orderBy: 'data DESC, horario ASC');
    return List.generate(maps.length, (i) => Refeicao.fromMap(maps[i]));
  }

  Future<List<Refeicao>> getRefeicoesPorIntervalo(String dataInicio, String dataFim) async {
    final db = await instance.database;
    final maps = await db.query(
      'refeicoes',
      where: 'data BETWEEN ? AND ?',
      whereArgs: [dataInicio, dataFim],
      orderBy: 'data DESC, horario ASC',
    );
    return List.generate(maps.length, (i) => Refeicao.fromMap(maps[i]));
  }

  Future<List<Refeicao>> buscarRefeicoes(String termo, {String? dataInicio, String? dataFim}) async {
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
