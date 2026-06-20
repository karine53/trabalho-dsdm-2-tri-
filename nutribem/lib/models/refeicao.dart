class Refeicao {
  final int? id;
  final String nome;
  final String? descricao;
  final String? tipo; // 'Café da Manhã', 'Almoço', 'Lanche', 'Jantar', 'Ceia'
  final double calorias;
  final double carbs;
  final double proteina;
  final double gordura;
  final double agua; // em litros
  final String data; // 'yyyy-MM-dd'
  final String? horario; // 'HH:mm'

  const Refeicao({
    this.id,
    required this.nome,
    this.descricao,
    this.tipo,
    required this.calorias,
    this.carbs = 0,
    this.proteina = 0,
    this.gordura = 0,
    this.agua = 0,
    required this.data,
    this.horario,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nome': nome,
    'descricao': descricao,
    'tipo': tipo,
    'calorias': calorias,
    'carbs': carbs,
    'proteina': proteina,
    'gordura': gordura,
    'agua': agua,
    'data': data,
    'horario': horario,
  };

  factory Refeicao.fromMap(Map<String, dynamic> map) => Refeicao(
    id: map['id'] as int?,
    nome: map['nome'] as String,
    descricao: map['descricao'] as String?,
    tipo: map['tipo'] as String?,
    calorias: (map['calorias'] as num).toDouble(),
    carbs: (map['carbs'] as num? ?? 0).toDouble(),
    proteina: (map['proteina'] as num? ?? 0).toDouble(),
    gordura: (map['gordura'] as num? ?? 0).toDouble(),
    agua: (map['agua'] as num? ?? 0).toDouble(),
    data: map['data'] as String,
    horario: map['horario'] as String?,
  );

  Refeicao copyWith({
    int? id,
    String? nome,
    String? descricao,
    String? tipo,
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
        calorias: calorias ?? this.calorias,
        carbs: carbs ?? this.carbs,
        proteina: proteina ?? this.proteina,
        gordura: gordura ?? this.gordura,
        agua: agua ?? this.agua,
        data: data ?? this.data,
        horario: horario ?? this.horario,
      );
}