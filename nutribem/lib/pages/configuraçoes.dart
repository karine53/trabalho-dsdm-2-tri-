// Importa os widgets básicos do Flutter.
import 'package:flutter/material.dart';

// "Molde" das configurações do app (horários, notificações ligadas/
// desligadas, etc), incluindo o método copyWith usado bastante aqui.
import '../models/configuraçoes.dart';

// Classe que centraliza todo o acesso ao banco de dados.
import '../database/dabase_helper.dart';

// Serviço responsável por pedir permissão e agendar as notificações.
import '../services/notification_service.dart';

// Widget "casca" da tela de Configurações. Delega toda a lógica e
// estado pra classe _ConfiguracoesPageState logo abaixo.
class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  //objeto que guarda informações que podem mudar
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

// Classe que guarda o estado da tela: as configurações carregadas, se
// ainda está carregando, e alguma mensagem de erro pra mostrar.
class _ConfiguracoesPageState extends State<ConfiguracoesPage> {

  // Configurações atuais do usuário. Começa nula até carregar do banco.
  //settings guarda objeto da classe appsettings
  AppSettings? _settings;

  // Controla se mostra o spinner de carregando ou já tem dados prontos.
  bool _isLoading = true;

  // Guarda o texto de um erro, caso algo dê errado ao carregar (nulo =
  // sem erro nenhum).
  String? _errorMessage;

  // Chamado automaticamente uma vez, quando a tela é criada.
  @override
  void initState() {
    super.initState();
    // Já busca as configurações salvas assim que a tela abre.
    _refreshSettings();
  }

  // Busca as configurações no banco de dados.
  Future<void> _refreshSettings() async {
    try {
      // Liga o spinner e limpa qualquer erro anterior antes de tentar
      // buscar de novo.
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Busca as configurações no banco, mas com um limite de tempo:
      // se demorar mais de 5 segundos (ex: banco travado), desiste e
      // lança um erro em vez de ficar esperando pra sempre.
      final settings = await DatabaseHelper.instance.getSettings().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception("Tempo limite excedido ao acessar o banco"),
      );
      
      // Se a tela ainda estiver aberta, guarda as configurações
      // encontradas e desliga o spinner.
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }

      // Se as notificações já estavam ligadas antes (configuração
      // salva), reagenda os lembretes com esses horários — sem pedir
      // permissão de novo, já que o usuário já tinha aceitado antes.
      if (settings.notificationsEnabled) {
        await NotificationService.agendarNotificacoes(settings);
      }
    } catch (e) {
      // Se qualquer parte acima falhar (banco travado, erro de leitura,
      // etc), mostra um aviso na tela em vez de travar tudo.
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erro ao carregar configurações: $e";
          // Usa configurações padrão como "plano B", pra tela não ficar
          // branca/quebrada esperando um valor que nunca vai vir.
          _settings = AppSettings(); 
        });
      }
    }
  }

  // Salva uma alteração de configuração (chamado toda vez que o usuário
  // mexe no switch de notificações ou muda algum horário).
  Future<void> _updateSetting(AppSettings newSettings) async {

    // Detecta se essa alteração está LIGANDO as notificações agora
    // (estava desligado antes e o novo valor é ligado). O "??" garante
    // que, se _settings ainda for nulo por algum motivo, assume "false"
    // como estado anterior.
    final ligandoNotificacoes = newSettings.notificationsEnabled &&
        !(_settings?.notificationsEnabled ?? false);

    // Só pede permissão de notificação nesse momento exato de "ligar
    // pela primeira vez" — não fica pedindo de novo toda vez que o
    // usuário só muda um horário, por exemplo.
    if (ligandoNotificacoes) {
      // É aqui que aparece o diálogo "NutriBem deseja enviar notificações?"
      final permitido = await NotificationService.solicitarPermissao();

      // Se o usuário negou a permissão...
      if (!permitido) {
        // ...checa se a tela ainda existe antes de tentar usar o
        // "context" (evita erro caso o usuário tenha saído da tela
        // enquanto o popup de permissão estava aberto).
        if (!mounted) return;

        // Mostra um aviso na parte de baixo da tela (SnackBar),
        // explicando que precisa da permissão, com um botão de atalho
        // pra abrir as configurações do celular.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Você precisa permitir notificações para ativar os lembretes.',
            ),
            action: SnackBarAction(
              label: 'Configurações',
              onPressed: NotificationService.abrirConfiguracoes,
            ),
          ),
        );
        // Para a função aqui: não salva a mudança, não liga o switch
        // visualmente, e não agenda nenhuma notificação.
        return;
      }
    }

    // Salva a nova configuração no banco de dados.
    await DatabaseHelper.instance.updateSettings(newSettings);

    // Atualiza o estado local com os novos valores, fazendo a tela
    // (switch, horários) refletir a mudança imediatamente.
    setState(() {
      _settings = newSettings;
    });

    // Reagenda TODOS os lembretes com base no novo estado — seja porque
    // ligou, desligou, ou mudou algum horário específico.
    await NotificationService.agendarNotificacoes(newSettings);
  }

  // Abre o seletor de horário nativo (relógio) pra escolher um novo
  // horário de lembrete, e chama "onSelected" com o resultado formatado.
  Future<void> _selectTime(BuildContext context, String currentLabel, String currentTime, Function(String) onSelected) async {
    try {
      // Quebra o horário salvo (ex: "08:00") em hora e minuto separados,
      // pra usar como ponto de partida no seletor.
      final parts = currentTime.split(':');
      final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        // Personaliza as cores do seletor de horário pra combinar com
        // o verde do app, em vez de usar o azul padrão do Android.
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF1B5E20),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      
      // Se o usuário escolheu um horário (não cancelou o seletor)...
      if (picked != null) {
        // ...formata de volta pro padrão "HH:mm" com zero à esquerda
        // (ex: hora 8 vira "08", não "8"), e chama a função passada
        // por quem invocou esse seletor.
        final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        onSelected(formattedTime);
      }
    } catch (e) {
      // Se algo der errado (ex: horário salvo num formato inesperado),
      // avisa o usuário em vez de travar a tela.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao selecionar horário: $e")),
      );
    }
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {

    // Enquanto ainda está carregando as configurações do banco, mostra
    // só um spinner central com uma mensagem, em vez da tela inteira.
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Carregando configurações..."),
            ],
          ),
        ),
      );
    }

    // A partir daqui, _settings sempre tem um valor (ou veio do banco,
    // ou veio do "plano B" no catch de _refreshSettings), então é
    // seguro usar "_settings!" nos widgets abaixo.
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner vermelho de erro, só aparece se _errorMessage
              // não for nulo (ou seja, se algo deu errado ao carregar).
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.red[100],
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),

              const Text(
                'Configurações',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Seção de notificações: título + o switch de ligar/desligar.
              _buildSectionTitle('Notificações'),
              _buildSwitchCard(
                'Ativar Notificações',
                'Receba lembretes de refeição',
                _settings!.notificationsEnabled,
                // Quando o switch muda, cria uma cópia das configurações
                // atuais só com "notificationsEnabled" trocado (copyWith
                // evita ter que reescrever todos os outros campos).
                (val) => _updateSetting(_settings!.copyWith(notificationsEnabled: val)),
              ),
              
              const SizedBox(height: 24),
              
              // Seção de horários: título + um card clicável pra cada
              // refeição, cada um abrindo o seletor de horário ao tocar.
              _buildSectionTitle('Horários dos Lembretes'),
              _buildTimeCard(
                Icons.wb_sunny_outlined,
                'Café da Manhã',
                _settings!.breakfastTime,
                () => _selectTime(context, 'Café da Manhã', _settings!.breakfastTime, 
                  (time) => _updateSetting(_settings!.copyWith(breakfastTime: time))),
              ),
              _buildTimeCard(
                Icons.wb_sunny,
                'Almoço',
                _settings!.lunchTime,
                () => _selectTime(context, 'Almoço', _settings!.lunchTime, 
                  (time) => _updateSetting(_settings!.copyWith(lunchTime: time))),
              ),
              _buildTimeCard(
                Icons.cloud_outlined,
                'Lanche',
                _settings!.snackTime,
                () => _selectTime(context, 'Lanche', _settings!.snackTime, 
                  (time) => _updateSetting(_settings!.copyWith(snackTime: time))),
              ),
              _buildTimeCard(
                Icons.nightlight_round,
                'Jantar',
                _settings!.dinnerTime,
                () => _selectTime(context, 'Jantar', _settings!.dinnerTime, 
                  (time) => _updateSetting(_settings!.copyWith(dinnerTime: time))),
              ),
              
              const SizedBox(height: 40),
              // Rodapé simples com nome/versão do app, centralizado.
              Center(
                child: Text(
                  'NutriBem v1.0.0 • Feito com ❤️ para uma vida mais saudável',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Título cinza pequeno usado pra separar as seções da tela
  // ("Notificações", "Horários dos Lembretes").
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
      ),
    );
  }

  // Card com título, subtítulo e um Switch (liga/desliga) à direita.
  // Reaproveitável pra qualquer configuração do tipo "sim/não".
  Widget _buildSwitchCard(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Expanded faz o texto ocupar todo o espaço restante,
            // empurrando o Switch pra ponta direita do card.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              // Cores customizadas: quando ligado, a "bolinha" fica
              // branca sobre trilho verde; quando desligado, bolinha
              // branca sobre trilho cinza.
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF1B5E20),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  // Card clicável representando um horário configurável (ex: "Café da
  // Manhã — 08:00"). Ao tocar, executa o callback recebido (que abre o
  // seletor de horário).
  Widget _buildTimeCard(IconData icon, String title, String time, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 12),

            // Expanded empurra a "pilulazinha" de horário pra ponta
            // direita, deixando o título alinhado à esquerda.
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            ),

            // Só essa parte (a pilulazinha verde com o horário) reage
            // ao toque — não o card inteiro — por isso o GestureDetector
            // está só em volta dela.
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}