import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import '../models/configuraçoes.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone));

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (details) {
          // Aqui você pode tratar o clique na notificação
          print("Notificação clicada: ${details.payload}");
        },
      );

      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            'nutribem_lembretes',
            'Lembretes NutriBem',
            description: 'Notificações de refeições e água',
            importance: Importance.max,
            enableVibration: true,
          ),
        );
      }
    } catch (e) {
      print("Erro ao inicializar notificações: $e");
    }
  }

  static Future<bool> solicitarPermissao() async {
    try {
      // 1. Permissão de Postar Notificações (Android 13+)
      final status = await Permission.notification.request();
      
      // 2. Permissão de Alarme Exato (Android 12+)
      // Essencial para o zonedSchedule funcionar com precisão
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

  static Future<void> abrirConfiguracoes() async {
    await openAppSettings();
  }

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
        0,
        titulo,
        corpo,
        const NotificationDetails(android: android),
      );
    } catch (e) {
      print("Erro ao mostrar notificação imediata: $e");
    }
  }

  static Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required int hora,
    required int minuto,
  }) async {
    try {
      // Verifica se temos permissão de alarme exato antes de tentar agendar
      // No Android 13/14, se tentar agendar sem permissão o app pode travar.
      if (Platform.isAndroid) {
        final status = await Permission.scheduleExactAlarm.status;
        if (status.isDenied) {
          print("Aviso: Permissão de alarme exato negada. A notificação pode atrasar.");
        }
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        titulo,
        corpo,
        _proximaData(hora, minuto),
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("Agendado: $titulo para $hora:$minuto");
    } catch (e) {
      print("Erro ao agendar notificação '$titulo': $e");
    }
  }

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

  static Future<void> agendarNotificacoes(AppSettings settings) async {
    await cancelarNotificacoes();

    if (!settings.notificationsEnabled) {
      print("Notificações desativadas nas configurações.");
      return;
    }

    try {
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

  static Future<void> cancelarNotificacoes() async {
    try {
      await _notificationsPlugin.cancelAll();
      print("Todas as notificações canceladas.");
    } catch (e) {
      print("Erro ao cancelar notificações: $e");
    }
  }
}
