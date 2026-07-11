import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../models/configuraçoes.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // ESSENCIAL: sem isso, nenhuma notificação funciona.
    await _notificationsPlugin.initialize(settings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'nutribem_lembretes',
      'Lembretes NutriBem',
      description: 'Notificações de refeições e água',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Chame isso antes de ligar o switch "Ativar Notificações".
  /// Retorna true se o usuário permitiu, false se negou.
  static Future<bool> solicitarPermissao() async {
    await init();

    final status = await Permission.notification.status;

    if (status.isPermanentlyDenied) {
      return false;
    }

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Abre a tela de configurações do app (usado quando a permissão
  /// foi negada permanentemente).
  static Future<void> abrirConfiguracoes() async {
    await openAppSettings();
  }

  /// Cancela tudo e reagenda de acordo com o AppSettings atual.
  /// Chame sempre que o usuário mudar um switch ou um horário.
  static Future<void> agendarNotificacoes(AppSettings settings) async {
    await init();
    await _notificationsPlugin.cancelAll();

    if (!settings.notificationsEnabled) {
      return; // notificações desligadas: não agenda nada
    }

    await _agendar(
      id: 1,
      titulo: '☕ Café da manhã',
      corpo: 'Está na hora do seu café da manhã!',
      horario: settings.breakfastTime,
    );

    await _agendar(
      id: 2,
      titulo: '🍛 Almoço',
      corpo: 'Está na hora do almoço!',
      horario: settings.lunchTime,
    );

    await _agendar(
      id: 3,
      titulo: '🍎 Lanche',
      corpo: 'Hora do seu lanche!',
      horario: settings.snackTime,
    );

    await _agendar(
      id: 4,
      titulo: '🍽 Jantar',
      corpo: 'Está na hora do jantar!',
      horario: settings.dinnerTime,
    );
  }

  static Future<void> _agendar({
    required int id,
    required String titulo,
    required String corpo,
    required String horario,
  }) async {
    final partes = horario.split(':');
    final hora = int.parse(partes[0]);
    final minuto = int.parse(partes[1]);

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
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
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

  static Future<void> cancelarNotificacoes() async {
    await _notificationsPlugin.cancelAll();
  }
}