// Importa o pacote principal de notificações locais: fornece a classe
// FlutterLocalNotificationsPlugin e todos os tipos usados pra configurar
// e disparar notificações (AndroidNotificationDetails, etc).
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Importa o timezone (apelidado de "tz"), usado pra calcular a próxima
// data/hora exata em que uma notificação agendada deve disparar,
// respeitando o fuso horário do usuário.
import 'package:timezone/timezone.dart' as tz;

// Plugin que descobre automaticamente o fuso horário configurado no
// dispositivo do usuário (ex: "America/Sao_Paulo").
import 'package:flutter_timezone/flutter_timezone.dart';

// Banco de dados com todos os fusos horários do mundo. Precisa ser
// carregado antes de usar qualquer fuso horário específico.
import 'package:timezone/data/latest.dart' as tz_data;

// Pacote usado pra pedir permissão de notificação ao usuário e pra
// abrir a tela de configurações do app dentro do sistema operacional.
import 'package:permission_handler/permission_handler.dart';

// Importa o "molde" das configurações do app (horários de cada
// refeição, se as notificações estão ligadas, etc), que vem
// diretamente do banco de dados agora.
import '../models/configuraçoes.dart';

// Classe responsável por TODA a lógica de notificações do app: iniciar
// o plugin, pedir permissão, mostrar notificações imediatas e agendar
// os lembretes com base nas configurações salvas pelo usuário.
//
// IMPORTANTE: a versão do flutter_local_notifications usada aqui
// (18.0.1) ainda NÃO tem suporte oficial pro Windows — só chegou em
// versões mais novas do pacote. Por isso, TODA função que mexe com
// _notificationsPlugin está envolvida em try/catch: no Android, tudo
// funciona normalmente; no Windows, se algo falhar, o erro é só
// registrado no console em vez de derrubar a tela inteira do app.
class NotificationService {

  // Instância única (compartilhada por toda a classe) do plugin de
  // notificações. "static final" significa que é criada uma vez só,
  // na primeira vez que a classe é usada, e reaproveitada sempre depois.
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Função que prepara tudo que é necessário ANTES de conseguir mostrar
  // ou agendar qualquer notificação. Deve ser chamada uma vez, no
  // início do app (é chamada lá no main.dart).
  static Future<void> init() async {
    try {
      // Carrega na memória a lista de todos os fusos horários existentes.
      // Sem isso, tz.getLocation não teria de onde puxar a informação.
      tz_data.initializeTimeZones();

      // Pergunta ao sistema operacional qual é o fuso horário configurado
      // no aparelho do usuário (de forma assíncrona, por isso o "await").
      final timezone = await FlutterTimezone.getLocalTimezone();

      // Define esse fuso horário do dispositivo como o "fuso local" padrão
      // que o pacote timezone vai usar daqui pra frente em todos os cálculos.
      tz.setLocalLocation(
        tz.getLocation(timezone),
      );

      // Configurações específicas do Android: informa qual ícone usar
      // nas notificações (o mesmo ícone do launcher/app na tela inicial).
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Agrupa as configurações de cada plataforma num único objeto.
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );

      // Inicializa DE VERDADE o plugin de notificações com as configurações
      // acima. Esse passo é OBRIGATÓRIO: sem ele, qualquer tentativa de
      // usar o plugin depois quebra com "LateInitializationError".
      await _notificationsPlugin.initialize(settings);

      // Define um "canal" de notificação (exigido pelo Android 8+), que
      // agrupa notificações parecidas sob um mesmo nome/descrição/prioridade.
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'nutribem_lembretes',
        'Lembretes NutriBem',
        description: 'Notificações de refeições e água',
        importance: Importance.max,
      );

      // Pega a implementação específica do Android dentro do plugin
      // (pode ser nula em outras plataformas, por isso o "?.") e,
      // se existir, cria o canal de notificação configurado acima.
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      // Se qualquer parte acima falhar (por exemplo, numa plataforma
      // sem suporte total, como o Windows nessa versão do plugin),
      // mostra o erro no console mas não deixa o app inteiro quebrar.
      print("Erro ao inicializar notificações: $e");
    }
  }

  // Pede ao sistema permissão pra mandar notificações. Devolve "true"
  // se o usuário permitiu, "false" se negou — a tela de Configurações
  // usa esse retorno pra decidir se liga o switch ou mostra um aviso.
  static Future<bool> solicitarPermissao() async {
    try {
      // Dispara o popup do sistema pedindo permissão de notificação
      // (no Android 13+; em versões mais antigas costuma já vir
      // liberado por padrão).
      final status = await Permission.notification.request();

      // status.isGranted é true só se o usuário realmente aceitou.
      return status.isGranted;
    } catch (e) {
      // Se a plataforma atual não suportar essa checagem (ex: Windows),
      // assume que está liberado, pra não travar o fluxo do usuário.
      print("Erro ao solicitar permissão: $e");
      return true;
    }
  }

  // Abre a tela de configurações do próprio app dentro do sistema
  // operacional, pra o usuário poder ativar notificações manualmente
  // caso tenha negado a permissão antes. Usada como callback direto
  // (sem parênteses) no botão do SnackBar da tela de Configurações.
  static Future<void> abrirConfiguracoes() async {
    try {
      await openAppSettings();
    } catch (e) {
      print("Erro ao abrir configurações: $e");
    }
  }

  // Mostra uma notificação IMEDIATA na tela (não agendada pro futuro).
  static Future<void> mostrarNotificacao({
    required String titulo, // título que aparece em negrito na notificação
    required String corpo,  // texto/corpo da notificação
  }) async {
    try {
      // Detalhes específicos do Android pra essa notificação.
      const AndroidNotificationDetails android = AndroidNotificationDetails(
        'nutribem_lembretes',
        'Lembretes NutriBem',
        channelDescription: 'Notificações de refeições e água',
        importance: Importance.max,
        priority: Priority.high,
      );

      // Manda o plugin exibir a notificação agora mesmo.
      await _notificationsPlugin.show(
        0, // id fixo: cada nova notificação imediata substitui a anterior
        titulo,
        corpo,
        const NotificationDetails(
          android: android,
        ),
      );
    } catch (e) {
      print("Erro ao mostrar notificação: $e");
    }
  }

  // Agenda uma notificação pra disparar automaticamente numa hora
  // específica do dia (e repetir todo dia nesse mesmo horário).
  static Future<void> agendarNotificacao({
    required int id,      // id único (permite ter várias agendadas ao mesmo tempo)
    required String titulo,
    required String corpo,
    required int hora,    // hora do dia (0-23) em que deve disparar
    required int minuto,  // minuto (0-59) em que deve disparar
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        titulo,
        corpo,
        // Calcula a próxima data/hora exata em que deve tocar.
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
        // Faz a notificação repetir todos os dias no mesmo horário.
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Captura falhas específicas dessa notificação (ex: no Windows,
      // onde o plugin ainda não tem suporte completo) sem travar as
      // outras notificações que ainda serão agendadas em seguida.
      print("Erro ao agendar notificação '$titulo': $e");
    }
  }

  // Função auxiliar que calcula a próxima data/hora em que um horário
  // (ex: 08:00) vai ocorrer — hoje mesmo, se ainda não passou, ou
  // amanhã, se esse horário já passou hoje.
  static tz.TZDateTime _proximaData(
    int hora,
    int minuto,
  ) {
    // Pega o momento atual, já no fuso horário local configurado.
    final agora = tz.TZDateTime.now(tz.local);

    // Monta uma data com o dia de hoje, mas com a hora/minuto pedidos.
    var data = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      agora.day,
      hora,
      minuto,
    );

    // Se esse horário de hoje já passou...
    if (data.isBefore(agora)) {
      // ...soma 1 dia, pra agendar pra amanhã nesse mesmo horário.
      data = data.add(
        const Duration(days: 1),
      );
    }

    return data;
  }

  // Reagenda TODOS os lembretes com base nas configurações atuais do
  // usuário (vindas direto do banco de dados via AppSettings, sem
  // depender mais do shared_preferences). Chamada toda vez que o
  // usuário liga/desliga notificações ou muda algum horário.
  static Future<void> agendarNotificacoes(AppSettings settings) async {

    // Cancela tudo que estava agendado antes de recriar, pra não
    // ficar com notificações duplicadas ou com horários antigos.
    await cancelarNotificacoes();

    // Se as notificações estiverem desligadas, não agenda nada e para
    // por aqui.
    if (!settings.notificationsEnabled) {
      return;
    }

    // Agenda o lembrete de café da manhã, convertendo o texto "08:00"
    // em hora (split(':')[0]) e minuto (split(':')[1]) separados.
    await agendarNotificacao(
      id: 1,
      titulo: '☕ Café da manhã',
      corpo: 'Está na hora do seu café da manhã!',
      hora: int.parse(settings.breakfastTime.split(':')[0]),
      minuto: int.parse(settings.breakfastTime.split(':')[1]),
    );

    // Agenda o lembrete de almoço.
    await agendarNotificacao(
      id: 2,
      titulo: '🍛 Almoço',
      corpo: 'Está na hora do almoço!',
      hora: int.parse(settings.lunchTime.split(':')[0]),
      minuto: int.parse(settings.lunchTime.split(':')[1]),
    );

    // Agenda o lembrete de lanche.
    await agendarNotificacao(
      id: 3,
      titulo: '🍎 Lanche',
      corpo: 'Hora do seu lanche!',
      hora: int.parse(settings.snackTime.split(':')[0]),
      minuto: int.parse(settings.snackTime.split(':')[1]),
    );

    // Agenda o lembrete de jantar.
    await agendarNotificacao(
      id: 4,
      titulo: '🍽 Jantar',
      corpo: 'Está na hora do jantar!',
      hora: int.parse(settings.dinnerTime.split(':')[0]),
      minuto: int.parse(settings.dinnerTime.split(':')[1]),
    );

    // O lembrete de água só existe se o usuário tiver essa opção
    // ligada nas configurações. Como o AppSettings não guarda um
    // horário customizado pra água, usamos um horário fixo (10h).
    if (settings.waterReminderEnabled) {
      await agendarNotificacao(
        id: 5,
        titulo: '💧 Água',
        corpo: 'Não esqueça de beber água!',
        hora: 10,
        minuto: 0,
      );
    }
  }

  // Cancela TODAS as notificações agendadas (chamado quando o usuário
  // desliga notificações, ou antes de reagendar tudo do zero).
  static Future<void> cancelarNotificacoes() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      print("Erro ao cancelar notificações: $e");
    }
  }
}