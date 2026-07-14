// Classe responsável por armazenar as configurações do aplicativo.
class AppSettings {

  // Identificador das configurações no banco de dados.
  // Como existe apenas um conjunto de configurações, o valor padrão é 1.
  final int? id;
//adicionar horario para configuraçoes

  bool notificationsEnabled;
  bool waterReminderEnabled;
  bool dailySummaryEnabled;
  String breakfastTime;
  String lunchTime;
  String snackTime;
  String dinnerTime;

  // Construtor da classe com valores padrão.
  AppSettings({
    this.id = 1,
    this.notificationsEnabled = true,
    this.waterReminderEnabled = true,
    this.dailySummaryEnabled = false,
    this.breakfastTime = '07:30',
    this.lunchTime = '12:00',
    this.snackTime = '15:30',
    this.dinnerTime = '19:00',
  });

  // Converte o objeto AppSettings em um Map.
  // Esse formato é utilizado para salvar os dados no banco SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notificationsEnabled': notificationsEnabled ? 1 : 0,
      'waterReminderEnabled': waterReminderEnabled ? 1 : 0,
      'dailySummaryEnabled': dailySummaryEnabled ? 1 : 0,
      'breakfastTime': breakfastTime,
      'lunchTime': lunchTime,
      'snackTime': snackTime,
      'dinnerTime': dinnerTime,
    };
  }

  // Cria um objeto AppSettings a partir dos dados
  // recuperados do banco de dados.
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'],
      notificationsEnabled: map['notificationsEnabled'] == 1,
      waterReminderEnabled: map['waterReminderEnabled'] == 1,
      dailySummaryEnabled: map['dailySummaryEnabled'] == 1,
      breakfastTime: map['breakfastTime'] ?? '07:30',
      lunchTime: map['lunchTime'] ?? '12:00',
      snackTime: map['snackTime'] ?? '15:30',
      dinnerTime: map['dinnerTime'] ?? '19:00',
    );
  }

    // Método responsável por criar uma nova cópia do objeto AppSettings.
  //
  // O método copyWith permite alterar apenas as configurações desejadas,
  // mantendo todas as demais iguais às do objeto original.
  //
  // Isso evita a necessidade de criar um novo objeto preenchendo todos
  // os atributos manualmente sempre que apenas uma configuração precisar
  // ser modificada.
  AppSettings copyWith({

    // Novo estado das notificações (opcional).
    bool? notificationsEnabled,

    // Novo estado do lembrete de água (opcional).
    bool? waterReminderEnabled,

    // Novo estado do resumo diário (opcional).
    bool? dailySummaryEnabled,

    // Novo horário do café da manhã (opcional).
    String? breakfastTime,

    // Novo horário do almoço (opcional).
    String? lunchTime,

    // Novo horário do lanche (opcional).
    String? snackTime,

    // Novo horário do jantar (opcional).
    String? dinnerTime,
  }) {

    // Retorna uma nova instância da classe AppSettings.
    return AppSettings(

      // Mantém o mesmo identificador da configuração.
      id: this.id,

      // Caso um novo valor seja informado para as notificações,
      // ele será utilizado. Caso contrário, mantém o valor atual.
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,

      // Atualiza o lembrete de água apenas se um novo valor for informado.
      // Caso contrário, preserva o valor existente.
      waterReminderEnabled:
          waterReminderEnabled ?? this.waterReminderEnabled,

      // Atualiza a configuração do resumo diário.
      // Se nenhum valor for passado, mantém a configuração atual.
      dailySummaryEnabled:
          dailySummaryEnabled ?? this.dailySummaryEnabled,

      // Atualiza o horário do café da manhã, se necessário.
      breakfastTime: breakfastTime ?? this.breakfastTime,

      // Atualiza o horário do almoço, se necessário.
      lunchTime: lunchTime ?? this.lunchTime,

      // Atualiza o horário do lanche, se necessário.
      snackTime: snackTime ?? this.snackTime,

      // Atualiza o horário do jantar, se necessário.
      dinnerTime: dinnerTime ?? this.dinnerTime,
    );
  }
}