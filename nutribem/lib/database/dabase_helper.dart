// Importa o pacote sqflite, que fornece as classes/funções pra abrir,
// consultar e gravar num banco de dados SQLite (Database, openDatabase, etc).
import 'package:sqflite/sqflite.dart';

// Importa o pacote path, usado pra montar caminhos de arquivo de forma
// correta (a função join() junta pedaços de caminho com a "/" certa pro SO).
import 'package:path/path.dart';

// Importa só a constante kIsWeb do pacote foundation do Flutter.
// kIsWeb é true quando o app está rodando dentro de um navegador (web)
// e false quando está rodando como app nativo (Windows, Android, iOS...).
import 'package:flutter/foundation.dart' show kIsWeb;

// Importa a classe Refeicao (o "molde" de uma refeição: nome, calorias etc).
import '../models/refeicao.dart';

// Importa a classe ResumoNutricional (usada pra somar totais de um dia).
import '../models/resumo_nutricional.dart';

// Importa a classe AppSettings (as configurações do app: horários,
// notificações etc).
import '../models/configuraçoes.dart';

// Classe responsável por TODO o acesso ao banco de dados do app.
// Centralizar aqui evita espalhar código de SQL pelas telas.
class DatabaseHelper {
  // Cria UMA única instância dessa classe pra ser reaproveitada em todo
  // o app (padrão de projeto chamado "Singleton"). Assim todo mundo usa
  // a mesma conexão com o banco, em vez de abrir várias sem necessidade.
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Variável que vai guardar a conexão aberta com o banco.
  // Começa como null (ainda não foi aberta) e é do tipo Database?
  // (a "?" indica que pode ser nula).
  static Database? _database;

  // Construtor privado (o "_" no nome impede que outras partes do
  // código criem um DatabaseHelper novo com "DatabaseHelper()").
  // Só a própria classe pode chamá-lo, através do "instance" acima.
  DatabaseHelper._init();

  // Getter assíncrono: toda vez que alguém pede "database", esse método
  // decide se abre o banco de novo ou devolve o que já está aberto.
  Future<Database> get database async {
    // Se _database já foi preenchido antes (não é null), reaproveita ele
    // em vez de abrir o banco de novo (evita abrir várias conexões).
    if (_database != null) return _database!;

    // Se ainda não existe, abre o banco chamando _initDB e guarda o
    // resultado em _database pra próxima vez não precisar abrir de novo.
    _database = await _initDB('nutribem.db');

    // Devolve o banco recém-aberto. O "!" diz ao Dart "tenho certeza que
    // não é null aqui", já que acabamos de atribuir valor a ele.
    return _database!;
  }

// Função interna que realmente abre (ou cria) o arquivo do banco de dados.
// Recebe o nome do arquivo (ex: "nutribem.db") e devolve a conexão aberta.
Future<Database> _initDB(String filePath) async {

  // Variável que vai guardar o "caminho" final usado pra abrir o banco.
  // Na Web isso não é uma pasta de verdade, é só um nome identificador.
  String path;

  // Se o app está rodando no navegador (Chrome, etc)...
  if (kIsWeb) {
    // ...usa só o nome do arquivo direto, sem montar caminho de pasta,
    // porque na Web não existe sistema de arquivos real: o navegador
    // guarda o banco internamente (via WebAssembly) usando esse nome
    // como identificador.
    path = filePath;
  } else {
    // Se NÃO é web (ou seja, é Windows, Android, iOS, etc)...

    // Pergunta ao sistema operacional qual é a pasta padrão onde os
    // bancos de dados do app devem ficar guardados.
    final dbPath = await getDatabasesPath();

    // Junta essa pasta com o nome do arquivo (ex: "C:/.../nutribem.db"),
    // formando o caminho completo do arquivo do banco.
    path = join(
      dbPath,
      filePath,
    );
  }

  // Abre o banco de dados nesse caminho. Se o arquivo ainda não existe,
  // ele é criado do zero e o Flutter chama automaticamente onCreate.
  // Se já existe mas está numa versão mais antiga, chama onUpgrade.
  return await openDatabase(
    path,
    // Número da versão atual do banco. Aumentar esse número é o jeito
    // de avisar o sqflite que a estrutura das tabelas mudou.
    version: 3,
    // Função chamada só na primeira vez, quando o banco ainda não existe.
    onCreate: _createDB,
    // Função chamada quando o banco já existe mas está em versão antiga,
    // pra atualizar a estrutura sem apagar os dados que já tinha.
    onUpgrade: _upgradeDB,
  );
}

  // Função executada apenas na criação do banco (primeira vez que o app
  // roda, ou quando o banco foi apagado). Cria as tabelas do zero.
  Future _createDB(Database db, int version) async {
    // Mensagem de depuração no console, só pra acompanhar o processo.
    print("Criando banco de dados...");

    // Executa um comando SQL bruto que cria a tabela "refeicoes".
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
    // id: identificador único de cada refeição, gerado automaticamente.
    // nome: nome do alimento/refeição, obrigatório (NOT NULL).
    // descricao: texto livre opcional.
    // tipo: café da manhã / almoço / jantar / lanche.
    // categoria: proteína / vegetal / carboidrato.
    // calorias, carbs, proteina, gordura, agua: valores nutricionais.
    // data: data da refeição (guardada como texto, ex: "2026-07-11").
    // horario: hora da refeição (guardada como texto, ex: "14:38").

    // Depois de criar a tabela de refeições, cria também a de
    // configurações, chamando a função auxiliar abaixo.
    await _createSettingsTable(db);
  }

  // Função separada pra criar a tabela de configurações, porque ela
  // também precisa ser chamada depois (no onUpgrade), não só na criação.
  Future _createSettingsTable(Database db) async {
    print("Criando tabela de configurações...");

    // CREATE TABLE IF NOT EXISTS: só cria se a tabela ainda não existir,
    // evitando erro caso ela já tenha sido criada antes.
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
    // id: sempre vai ser 1 (só existe UM registro de configurações).
    // notificationsEnabled: 1 (ligado) ou 0 (desligado) — SQLite não tem
    //   tipo boolean de verdade, então se usa INTEGER pra representar.
    // waterReminderEnabled: liga/desliga lembrete de beber água.
    // dailySummaryEnabled: liga/desliga resumo diário.
    // breakfastTime/lunchTime/snackTime/dinnerTime: horários configurados
    //   pelo usuário pra cada tipo de refeição, guardados como texto.

    // Verifica se já existe uma linha com id = 1 na tabela settings,
    // pra não inserir duplicado quando essa função for chamada de novo
    // durante um onUpgrade (banco que já tinha configurações salvas).
    final List<Map<String, dynamic>> existing = await db.query('settings', where: 'id = ?', whereArgs: [1]);

    // Se a busca não encontrou nenhuma linha (lista vazia)...
    if (existing.isEmpty) {
      print("Inserindo configurações padrão...");
      // ...insere uma linha com valores padrão, usando o construtor
      // sem parâmetros de AppSettings() e convertendo pra Map com toMap().
      await db.insert('settings', AppSettings().toMap());
    }
  }

  // Função chamada automaticamente pelo sqflite quando detecta que o
  // banco no dispositivo está numa versão mais antiga que a atual (3).
  // Serve pra "migrar" dados existentes sem perder o que já tinha salvo.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print("Fazendo upgrade do banco de $oldVersion para $newVersion");

    // Se a versão antiga era menor que 2, significa que a coluna
    // "categoria" ainda não existia — então ela é adicionada agora.
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE refeicoes ADD COLUMN categoria TEXT');
    }

    // Se a versão antiga era menor que 3, significa que a tabela de
    // configurações ainda não existia — então ela é criada agora,
    // reaproveitando a mesma função usada na criação do banco.
    if (oldVersion < 3) {
      await _createSettingsTable(db);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // A partir daqui: métodos "públicos" que as telas do app chamam
  // pra ler/gravar dados, sem precisar saber SQL nem detalhes do banco.
  // ──────────────────────────────────────────────────────────────

  // --- MÉTODOS DE CONFIGURAÇÕES ---

  // Busca as configurações salvas no banco e devolve como um AppSettings.
  Future<AppSettings> getSettings() async {
    try {
      // Pega a conexão aberta com o banco (abre se ainda não tiver).
      final db = await instance.database;

      // Busca a linha de configurações (sempre a de id = 1).
      final List<Map<String, dynamic>> maps = await db.query('settings', where: 'id = ?', whereArgs: [1]);

      // Se encontrou pelo menos uma linha...
      if (maps.isNotEmpty) {
        // ...converte o primeiro (e único) resultado num objeto AppSettings.
        return AppSettings.fromMap(maps.first);
      } else {
        // Se não encontrou nada (banco novo, sem configurações ainda)...
        print("Configurações não encontradas, criando padrões...");

        // Cria um objeto de configurações com os valores padrão.
        final defaultSettings = AppSettings();

        // Salva esses valores padrão no banco, pra da próxima vez já
        // existir uma linha.
        await db.insert('settings', defaultSettings.toMap());

        // Devolve os valores padrão pra quem chamou a função.
        return defaultSettings;
      }
    } catch (e) {
      // Se der qualquer erro inesperado no meio do processo (ex: banco
      // corrompido), evita que o app quebre: mostra o erro no console...
      print("Erro ao buscar configurações: $e");
      // ...e devolve configurações padrão mesmo assim, pra tela não
      // travar esperando um valor que nunca vai vir.
      return AppSettings();
    }
  }

  // Atualiza as configurações salvas com os novos valores passados.
  Future<int> updateSettings(AppSettings settings) async {
    try {
      final db = await instance.database;

      // UPDATE na linha de id = 1, trocando os valores pelos novos.
      // Devolve quantas linhas foram alteradas (deveria ser sempre 1).
      return await db.update(
        'settings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [1],
      );
    } catch (e) {
      print("Erro ao atualizar configurações: $e");
      // Devolve 0 pra indicar que nenhuma linha foi alterada (falhou).
      return 0;
    }
  }

  // --- MÉTODOS DE REFEIÇÃO ---

  // Insere uma nova refeição no banco e devolve o id gerado pra ela.
  Future<int> insertRefeicao(Refeicao refeicao) async {

  // Prints de depuração, úteis pra acompanhar no console se o processo
  // está travando em alguma etapa específica (abrir banco vs inserir).
  print("1 - entrou no insert");

  // Pega a conexão com o banco (abre se ainda não estiver aberta).
  final db = await instance.database;

  print("2 - banco aberto");

  // Insere a refeição na tabela "refeicoes", convertendo o objeto
  // Refeicao num Map (par chave/valor) através de refeicao.toMap().
  // O sqflite devolve o id gerado automaticamente pra essa nova linha.
  final id = await db.insert(
    'refeicoes',
    refeicao.toMap(),
  );

  print("3 - salvou id: $id");

  // Devolve o id da refeição recém-criada pra quem chamou a função.
  return id;
}

  // Atualiza uma refeição já existente, identificada pelo seu id.
  Future<int> updateRefeicao(Refeicao refeicao) async {
    final db = await instance.database;

    // UPDATE na linha cujo id bate com refeicao.id, trocando os valores.
    // Devolve quantas linhas foram alteradas (1 se encontrou, 0 se não).
    return await db.update(
      'refeicoes',
      refeicao.toMap(),
      where: 'id = ?',
      whereArgs: [refeicao.id],
    );
  }

  // Apaga uma refeição do banco, dado o seu id.
  Future<int> deleteRefeicao(int id) async {
    final db = await instance.database;

    // DELETE na linha com esse id. Devolve quantas linhas foram apagadas.
    return await db.delete('refeicoes', where: 'id = ?', whereArgs: [id]);
  }

  // Busca todas as refeições cadastradas numa data específica.
  Future<List<Refeicao>> getRefeicoesPorData(String data) async {
    final db = await instance.database;

    // Filtra pela coluna "data" e ordena pelo horário, do mais cedo
    // pro mais tarde (ASC = crescente).
    final maps = await db.query(
      'refeicoes',
      where: 'data = ?',
      whereArgs: [data],
      orderBy: 'horario ASC',
    );

    // Converte cada linha (Map) do resultado num objeto Refeicao,
    // formando uma lista de refeições prontas pra tela usar.
    return List.generate(maps.length, (i) => Refeicao.fromMap(maps[i]));
  }

  // Calcula o total de calorias/carboidratos/proteína/gordura/água
  // somando todas as refeições de uma data específica.
  Future<ResumoNutricional> getResumoNutricional(String data) async {
    final db = await instance.database;

    // Busca todas as refeições daquela data (sem ordenação, aqui não
    // importa a ordem já que só vai somar os valores).
    final List<Map<String, dynamic>> maps = await db.query(
      'refeicoes',
      where: 'data = ?',
      whereArgs: [data],
    );

    // Variáveis acumuladoras, começando em zero.
    double cal = 0, carb = 0, prot = 0, gord = 0, agua = 0;

    // Percorre cada refeição encontrada e vai somando os valores.
    for (var m in maps) {
      // "calorias" é obrigatório no banco (NOT NULL), então converte
      // direto pra double sem precisar de valor padrão.
      cal += (m['calorias'] as num).toDouble();

      // Os demais campos podem ser nulos no banco, então usa "?? 0"
      // pra somar zero caso o valor seja null (evita erro de null).
      carb += (m['carbs'] as num?)?.toDouble() ?? 0;
      prot += (m['proteina'] as num?)?.toDouble() ?? 0;
      gord += (m['gordura'] as num?)?.toDouble() ?? 0;
      agua += (m['agua'] as num?)?.toDouble() ?? 0;
    }

    // Devolve um objeto ResumoNutricional já com os totais calculados.
    return ResumoNutricional(
      totalCalorias: cal,
      totalCarbs: carb,
      totalProteina: prot,
      totalGordura: gord,
      totalAgua: agua,
    );
  }

  // Busca TODAS as refeições cadastradas no banco, sem filtro de data.
  Future<List<Refeicao>> getAllRefeicoes() async {
    final db = await instance.database;

    // Ordena primeiro pela data mais recente (DESC = decrescente) e,
    // dentro do mesmo dia, pelo horário mais cedo primeiro (ASC).
    final maps = await db.query('refeicoes', orderBy: 'data DESC, horario ASC');

    // Converte cada linha em objeto Refeicao, igual nos outros métodos.
    return List.generate(maps.length, (i) => Refeicao.fromMap(maps[i]));
  }

  // Busca refeições dentro de um intervalo de datas (ex: última semana).
  Future<List<Refeicao>> getRefeicoesPorIntervalo(String dataInicio, String dataFim) async {
    final db = await instance.database;

    // BETWEEN filtra as linhas cuja "data" esteja entre dataInicio e
    // dataFim (incluindo os dois extremos).
    final maps = await db.query(
      'refeicoes',
      where: 'data BETWEEN ? AND ?',
      whereArgs: [dataInicio, dataFim],
      orderBy: 'data DESC, horario ASC',
    );
    return List.generate(maps.length, (i) => Refeicao.fromMap(maps[i]));
  }

  // Busca refeições cujo nome ou descrição contenha o termo procurado,
  // com filtro opcional de intervalo de datas.
  Future<List<Refeicao>> buscarRefeicoes(String termo, {String? dataInicio, String? dataFim}) async {
    final db = await instance.database;

    // Lista de condições SQL que vão sendo montadas dinamicamente.
    // Começa sempre com a busca por nome OU descrição usando LIKE
    // (comparação de texto que permite "conter" o termo, não só igual).
    final condicoes = <String>['(nome LIKE ? OR descricao LIKE ?)'];

    // Lista de valores que serão usados nas "?" acima, na mesma ordem.
    // "%$termo%" significa "qualquer coisa antes e depois do termo",
    // ou seja, busca o termo em qualquer parte do texto.
    final args = <Object?>['%$termo%', '%$termo%'];

    // Se o chamador passou um intervalo de datas (os dois parâmetros
    // opcionais não são nulos)...
    if (dataInicio != null && dataFim != null) {
      // ...adiciona mais essa condição à lista, combinada com AND.
      condicoes.add('data BETWEEN ? AND ?');
      // E adiciona os valores correspondentes na mesma ordem.
      args.addAll([dataInicio, dataFim]);
    }

    // Executa a busca juntando todas as condições da lista com " AND ",
    // formando a cláusula WHERE final (com ou sem filtro de data).
    final maps = await db.query(
      'refeicoes',
      where: condicoes.join(' AND '),
      whereArgs: args,
      orderBy: 'data DESC, horario ASC',
    );
    return List.generate(maps.length, (i) => Refeicao.fromMap(maps[i]));
  }
}