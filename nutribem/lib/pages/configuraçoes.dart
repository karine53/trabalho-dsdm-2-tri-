import 'package:flutter/material.dart';
import '../models/configuraçoes.dart';
import '../database/dabase_helper.dart';
import '../services/notification_service.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  AppSettings? _settings;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refreshSettings();
  }

  Future<void> _refreshSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Tenta buscar as configurações com um tempo limite
      final settings = await DatabaseHelper.instance.getSettings().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception("Tempo limite excedido ao acessar o banco"),
      );
      
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }

      // Reagenda com base no que já estava salvo (sem pedir permissão de novo).
      if (settings.notificationsEnabled) {
        await NotificationService.agendarNotificacoes(settings);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erro ao carregar configurações: $e";
          // Fallback para evitar tela branca infinita
          _settings = AppSettings(); 
        });
      }
    }
  }

  Future<void> _updateSetting(AppSettings newSettings) async {
    final ligandoNotificacoes = newSettings.notificationsEnabled &&
        !(_settings?.notificationsEnabled ?? false);

    if (ligandoNotificacoes) {
      // É aqui que aparece o diálogo "NutriBem deseja enviar notificações?"
      final permitido = await NotificationService.solicitarPermissao();

      if (!permitido) {
        if (!mounted) return;

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
        return; // não salva, não liga o switch, não agenda nada
      }
    }

    await DatabaseHelper.instance.updateSettings(newSettings);

    setState(() {
      _settings = newSettings;
    });

    // Reagenda tudo com base no novo estado (liga, desliga, ou muda horário).
    await NotificationService.agendarNotificacoes(newSettings);
  }

  Future<void> _selectTime(BuildContext context, String currentLabel, String currentTime, Function(String) onSelected) async {
    try {
      final parts = currentTime.split(':');
      final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
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
      
      if (picked != null) {
        final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        onSelected(formattedTime);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao selecionar horário: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

    // Se houver erro, mas temos configurações de fallback, mostramos um aviso
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              
              _buildSectionTitle('Notificações'),
              _buildSwitchCard(
                'Ativar Notificações',
                'Receba lembretes de refeição',
                _settings!.notificationsEnabled,
                (val) => _updateSetting(_settings!.copyWith(notificationsEnabled: val)),
              ),
              
              const SizedBox(height: 24),
              
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
      ),
    );
  }

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
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            ),
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