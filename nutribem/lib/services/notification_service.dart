import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import '../models/configuraçoes.dart';
import 'dart:io' show Platform;

/// CLASSE DE SERVIÇO DE NOTIFICAÇÕES
/// Centraliza toda a lógica de permissões, agendamento e exibição de alertas.
class NotificationService {
  // Instância única do plugin de notificações locais.
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// INICIALIZAÇÃO DO SERVIÇO
  /// Deve ser chamado no main.dart antes do runApp.
  static Future<void> init() async {
    try {
      // 1. Inicializa o banco de dados de fusos horários (Timezones).
      tz_data.initializeTimeZones();
      
      // 2. Detecta o fuso horário local do dispositivo (ex: America/Sao_Paulo).
      final timezone = await FlutterTimezone.getLocalTimezone();
      
      // 3. Define esse fuso como o padrão para os cálculos de agendamento.
      tz.setLocalLocation(tz.getLocation(timezone));

      // Configuração específica para o Android (define o ícone que aparecerá na barra de status).
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );

      // Inicializa o plugin com as configurações acima.
      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (details) {
          // Callback executado quando o usuário toca na notificação.
          print("Notificação clicada: ${details.payload}");
        },
      );

      // No Android, precisamos criar um "Canal de Notificação" (exigência desde o Android 8.0).
      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            'nutribem_lembretes',      // ID único do canal.
            'Lembretes NutriBem',      // Nome visível nas configurações do Android.
            description: 'Notificações de refeições e água',
            importance: Importance.max, // Define que a notificação deve fazer barulho/aparecer no topo.
            enableVibration: true,
          ),
        );
      }
    } catch (e) {
      print("Erro ao inicializar notificações: $e");
    }
  }

  /// SOLICITAÇÃO DE PERMISSÕES
  /// Essencial para Android 12, 13 e 14.
  static Future<bool> solicitarPermissao() async {
    try {
      // 1. Permissão de Postar Notificações (Obrigatória no Android 13+).
      final status = await Permission.notification.request();
      
      // 2. Permissão de Alarme Exato (Obrigatória no Android 12+ para notificações agendadas).
      // Sem isso, o sistema pode atrasar ou ignorar o horário exato da refeição.
      if (Platform.isAndroid) {
        if (await Permission.scheduleExactAlarm.isDenied) {
          print("Solicitando permissão de alarme exato...");
          await Permission.scheduleExactAlarm.request();
        }
      }

      return status.isGranted;
    } catch (e) {
      print("Erro ao solicitar permissão: $e");
      return true;
    }
  }

  /// ABRE CONFIGURAÇÕES DO SISTEMA
  /// Caso o usuário tenha negado a permissão, levamos ele direto para a tela de ajustes.
  static Future<void> abrirConfiguracoes() async {
    await openAppSettings();
  }

  /// EXIBE NOTIFICAÇÃO IMEDIATA
  /// Usada para testes ou avisos que não precisam de agendamento.
  static Future<void> mostrarNotificacao({
    required String titulo,
    required String corpo,
  }) async {
    try {
      const AndroidNotificationDetails android = AndroidNotificationDetails(
        'nutribem_lembretes',
        'Lembretes NutriBem',
        channelDescription: 'Notificações de refeições e água',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      await _notificationsPlugin.show(
        0, // ID da notificação (0 sobrescreve a anterior).
        titulo,
        corpo,
        const NotificationDetails(android: android),
      );
    } catch (e) {
      print("Erro ao mostrar notificação imediata: $e");
    }
  }

  /// AGENDAMENTO DE NOTIFICAÇÃO (O CORAÇÃO DO SISTEMA)
  /// Agenda um lembrete para um horário específico que se repete diariamente.
  static Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required int hora,
    required int minuto,
  }) async {
    try {
      // Checagem de segurança para Alarmes Exatos no Android.
      if (Platform.isAndroid) {
        final status = await Permission.scheduleExactAlarm.status;
        if (status.isDenied) {
          print("Aviso: Permissão de alarme exato negada. A notificação pode atrasar.");
        }
      }

      // Agenda a notificação usando fusos horários (Zoned Schedule).
      await _notificationsPlugin.zonedSchedule(
        id,
        titulo,
        corpo,
        _proximaData(hora, minuto), // Calcula se o horário é hoje ou amanhã.
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'nutribem_lembretes',
            'Lembretes NutriBem',
            channelDescription: 'Notificações de refeições e água',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // AndroidScheduleMode.exactAllowWhileIdle: Garante que toque mesmo em modo economia.
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Repete todos os dias no mesmo horário.
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("Agendado: $titulo para $hora:$minuto");
    } catch (e) {
      print("Erro ao agendar notificação '$titulo': $e");
    }
  }

  /// CÁLCULO DA PRÓXIMA DATA
  /// Se o horário já passou hoje (ex: 8h da manhã e agora são 10h), agenda para amanhã.
  static tz.TZDateTime _proximaData(int hora, int minuto) {
    final agora = tz.TZDateTime.now(tz.local);
    var data = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day,
      hora,
      minuto,
    );

    if (data.isBefore(agora)) {
      data = data.add(const Duration(days: 1));
    }
    return data;
  }

  /// REAGENDAMENTO GLOBAL
  /// Chamado sempre que o usuário muda as configurações no app.
  static Future<void> agendarNotificacoes(AppSettings settings) async {
    // 1. Limpa todos os agendamentos antigos para evitar duplicidade.
    await cancelarNotificacoes();

    // 2. Se as notificações estiverem desligadas, para por aqui.
    if (!settings.notificationsEnabled) {
      print("Notificações desativadas nas configurações.");
      return;
    }

    try {
      // 3. Agenda cada refeição convertendo o texto "HH:mm" em inteiros.
      
      // Café da manhã
      await agendarNotificacao(
        id: 1,
        titulo: '☕ Café da manhã',
        corpo: 'Está na hora do seu café da manhã!',
        hora: int.parse(settings.breakfastTime.split(':')[0]),
        minuto: int.parse(settings.breakfastTime.split(':')[1]),
      );

      // Almoço
      await agendarNotificacao(
        id: 2,
        titulo: '🍛 Almoço',
        corpo: 'Está na hora do almoço!',
        hora: int.parse(settings.lunchTime.split(':')[0]),
        minuto: int.parse(settings.lunchTime.split(':')[1]),
      );

      // Lanche
      await agendarNotificacao(
        id: 3,
        titulo: '🍎 Lanche',
        corpo: 'Hora do seu lanche!',
        hora: int.parse(settings.snackTime.split(':')[0]),
        minuto: int.parse(settings.snackTime.split(':')[1]),
      );

      // Jantar
      await agendarNotificacao(
        id: 4,
        titulo: '🍽 Jantar',
        corpo: 'Está na hora do jantar!',
        hora: int.parse(settings.dinnerTime.split(':')[0]),
        minuto: int.parse(settings.dinnerTime.split(':')[1]),
      );

      // Água (Lembrete fixo às 10h se ativado).
      if (settings.waterReminderEnabled) {
        await agendarNotificacao(
          id: 5,
          titulo: '💧 Água',
          corpo: 'Não esqueça de beber água!',
          hora: 10,
          minuto: 0,
        );
      }
    } catch (e) {
      print("Erro no processamento dos horários: $e");
    }
  }

  /// CANCELAMENTO
  /// Remove todos os lembretes do sistema.
  static Future<void> cancelarNotificacoes() async {
    try {
      await _notificationsPlugin.cancelAll();
      print("Todas as notificações canceladas.");
    } catch (e) {
      print("Erro ao cancelar notificações: $e");
    }
  }
}
