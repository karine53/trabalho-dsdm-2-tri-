// Classe que representa uma refeição cadastrada no aplicativo.
class Refeicao {

  // Identificador único da refeição no banco de dados.
  // É opcional porque o banco gera esse valor automaticamente.
  final int? id;

  // Nome da refeição ou alimento.
  final String nome;

  // Descrição opcional da refeição.
  final String? descricao;

  // Tipo da refeição (Ex.: Café da Manhã, Almoço, Lanche, Jantar ou Ceia).
  final String? tipo;

  // Categoria nutricional da refeição
  // (Ex.: Proteína, Vegetal ou Carboidrato).
  final String? categoria;

  // Quantidade de calorias da refeição.
  final double calorias;

  // Quantidade de carboidratos (em gramas).
  final double carbs;

  // Quantidade de proteínas (em gramas).
  final double proteina;

  // Quantidade de gorduras (em gramas).
  final double gordura;

  // Quantidade de água consumida (em litros).
  final double agua;

  // Data da refeição no formato yyyy-MM-dd.
  final String data;

  // Horário da refeição no formato HH:mm.
  final String? horario;

  // Construtor da classe.
  const Refeicao({
    this.id,
    required this.nome,
    this.descricao,
    this.tipo,
    this.categoria,
    required this.calorias,
    this.carbs = 0,
    this.proteina = 0,
    this.gordura = 0,
    this.agua = 0,
    required this.data,
    this.horario,
  });

  // Converte o objeto Refeicao em um Map.
  // Esse formato é utilizado para salvar os dados no banco SQLite.
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'nome': nome,
        'descricao': descricao,
        'tipo': tipo,
        'categoria': categoria,
        'calorias': calorias,
        'carbs': carbs,
        'proteina': proteina,
        'gordura': gordura,
        'agua': agua,
        'data': data,
        'horario': horario,
      };

  // Cria um objeto Refeicao a partir de um Map
  // recebido do banco de dados.
  factory Refeicao.fromMap(Map<String, dynamic> map) => Refeicao(
        id: map['id'] as int?,
        nome: map['nome'] as String,
        descricao: map['descricao'] as String?,
        tipo: map['tipo'] as String?,
        categoria: map['categoria'] as String?,
        calorias: (map['calorias'] as num).toDouble(),
        carbs: (map['carbs'] as num? ?? 0).toDouble(),
        proteina: (map['proteina'] as num? ?? 0).toDouble(),
        gordura: (map['gordura'] as num? ?? 0).toDouble(),
        agua: (map['agua'] as num? ?? 0).toDouble(),
        data: map['data'] as String,
        horario: map['horario'] as String?,
      );

  // Retorna uma nova instância da classe permitindo
  // alterar apenas os atributos desejados, mantendo
  // os demais valores inalterados.
  Refeicao copyWith({
    int? id,
    String? nome,
    String? descricao,
    String? tipo,
    String? categoria,
    double? calorias,
    double? carbs,
    double? proteina,
    double? gordura,
    double? agua,
    String? data,
    String? horario,
  }) =>
      Refeicao(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        descricao: descricao ?? this.descricao,
        tipo: tipo ?? this.tipo,
        categoria: categoria ?? this.categoria,
        calorias: calorias ?? this.calorias,
        carbs: carbs ?? this.carbs,
        proteina: proteina ?? this.proteina,
        gordura: gordura ?? this.gordura,
        agua: agua ?? this.agua,
        data: data ?? this.data,
        horario: horario ?? this.horario,
      );
}