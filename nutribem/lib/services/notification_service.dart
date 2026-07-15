import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import '../models/configuraçoes.dart';
import 'dart:io' show Platform;


class NotificationService {
  // instancia principal para integrar com o sistema de notificaçoes local do dispositivo 
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Deve ser chamado no main.dart antes do runApp.
  static Future<void> init() async {
    try {
//detecta o fuso horario local do dispositivo 
      tz_data.initializeTimeZones();
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone)); //garante que o horario programado seja o teu msm 
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');//comando interno do android que diz va ate essa paste e veja esse arquivo
          //define o icone de notificaçao na barra de status 

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
                AndroidFlutterLocalNotificationsPlugin>(); //serve para acessar as implementaçoes especificas do android 
        //permite que o usuario controle as configuraçoes de son 
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
          await Permission.scheduleExactAlarm.request(); //para o android 12+
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

  /// AGENDAMENTO DE NOTIFICAÇÃO
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
      await _notificationsPlugin.zonedSchedule( //serve para agendar notificaçoes que se repetem 
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
            UILocalNotificationDateInterpretation.absoluteTime, //usa o exato horario que foi passado
      
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, //executa o alarme mesmo com o modo de suspensao no cllr 
      
        matchDateTimeComponents: DateTimeComponents.time,//repete o alarme todos os dias no mesmo horario definido 
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
        hora: int.parse(settings.dinnerTime.split(':')[0]),// o split corta em pedaços tipo hora e minutos 
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
      await _notificationsPlugin.cancelAll(); //remove todas as  notificaçoes pendentes 
      print("Todas as notificações canceladas.");
    } catch (e) {
      print("Erro ao cancelar notificações: $e");
    }
  }
}
