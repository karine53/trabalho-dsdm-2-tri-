import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;


class NotificationService {

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();


  static Future<void> init() async {

    tz_data.initializeTimeZones();

    final timezone = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(
      tz.getLocation(timezone),
    );


    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');


    const InitializationSettings settings =
        InitializationSettings(
          android: androidSettings,
        );


    //await _notificationsPlugin.initialize(settings);


    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
          'nutribem_lembretes',
          'Lembretes NutriBem',
          description: 'Notificações de refeições e água',
          importance: Importance.max,
        );


    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }



  static Future<void> solicitarPermissao() async {

   // await Permission.notification.request();

  }




  static Future<void> mostrarNotificacao({
    required String titulo,
    required String corpo,
  }) async {


    const AndroidNotificationDetails android =
        AndroidNotificationDetails(
          'nutribem_lembretes',
          'Lembretes NutriBem',
          channelDescription:
              'Notificações de refeições e água',
          importance: Importance.max,
          priority: Priority.high,
        );


    await _notificationsPlugin.show(
      0,
      titulo,
      corpo,
      const NotificationDetails(
        android: android,
      ),
    );
  }





 static Future<void> agendarNotificacao({
  required int id,
  required String titulo,
  required String corpo,
  required int hora,
  required int minuto,
}) async {
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
    androidScheduleMode:
        AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents:
        DateTimeComponents.time,
  );
}





  static tz.TZDateTime _proximaData(
      int hora,
      int minuto,
      ) {

    final agora = tz.TZDateTime.now(tz.local);


    var data = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day,
      hora,
      minuto,
    );


    if(data.isBefore(agora)){
      data = data.add(
        const Duration(days: 1),
      );
    }


    return data;

  }





  static Future<void> configurarHorarios() async {


    final prefs =
        await SharedPreferences.getInstance();


    final cafe =
        prefs.getString('cafe') ?? '08:00';

    final almoco =
        prefs.getString('almoco') ?? '12:00';

    final lanche =
        prefs.getString('lanche') ?? '15:30';

    final janta =
        prefs.getString('janta') ?? '19:30';

    final agua =
        prefs.getString('agua') ?? '10:00';



    await agendarNotificacao(
      id: 1,
      titulo: '☕ Café da manhã',
      corpo: 'Está na hora do seu café da manhã!',
      hora: int.parse(cafe.split(':')[0]),
      minuto: int.parse(cafe.split(':')[1]),
    );


    await agendarNotificacao(
      id: 2,
      titulo: '🍛 Almoço',
      corpo: 'Está na hora do almoço!',
      hora: int.parse(almoco.split(':')[0]),
      minuto: int.parse(almoco.split(':')[1]),
    );


    await agendarNotificacao(
      id: 3,
      titulo: '🍎 Lanche',
      corpo: 'Hora do seu lanche!',
      hora: int.parse(lanche.split(':')[0]),
      minuto: int.parse(lanche.split(':')[1]),
    );


    await agendarNotificacao(
      id: 4,
      titulo: '🍽 Jantar',
      corpo: 'Está na hora do jantar!',
      hora: int.parse(janta.split(':')[0]),
      minuto: int.parse(janta.split(':')[1]),
    );


    await agendarNotificacao(
      id: 5,
      titulo: '💧 Água',
      corpo: 'Não esqueça de beber água!',
      hora: int.parse(agua.split(':')[0]),
      minuto: int.parse(agua.split(':')[1]),
    );

  }





  static Future<void> cancelarNotificacoes() async {

    await _notificationsPlugin.cancelAll();

  }

}