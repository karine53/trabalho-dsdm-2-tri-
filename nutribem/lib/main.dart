import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/pg-inicial.dart';
import 'pages/historico_page.dart';
import 'pages/estatistica.dart';
import 'pages/configuraçoes.dart';
import 'services/notification_service.dart';

/// PONTO DE ENTRADA DO APLICATIVO
/// O método 'main' é onde tudo começa. Usamos 'async' porque a inicialização
/// de bancos de dados e serviços de notificação leva tempo (são operações assíncronas).
void main() async {
  
  WidgetsFlutterBinding.ensureInitialized(); //garante que o flutter esteja totalmente pronto antes da integraçao 

  //adaptaçao do sqlite para diferentes ambientes de de execuçao 
  if (kIsWeb) {
    // Se estiver no navegador, usa a implementação Web.
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Se estiver no Desktop, inicializa o FFI (Foreign Function Interface) para SQLite.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // No Android/iOS, o SQFLITE já funciona nativamente, então não precisa de if extra.
  // Configura as datas para o padrão brasileiro 
  await initializeDateFormatting('pt_BR', null);


  // Só inicializamos se NÃO for Web, pois o pacote usado não suporta navegadores.
  if (!kIsWeb) {
    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint("Aviso: Notificações não inicializadas: $e");
    }
  }

  
  runApp(const NutriBemApp());
}

/// Define o tema visual, as cores e as configurações de idioma globais.
class NutriBemApp extends StatelessWidget {
  const NutriBemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriBem',
      debugShowCheckedModeBanner: false, // Remove a faixa de "Debug" no canto da tela.

      // Configurações de localização para que calendários e inputs entendam PT-BR.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),

      // TEMA VISUAL: Definimos o verde como a cor principal (Seed Color).
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true, // Usa o design system mais moderno do Google.
      ),

      // Define a primeira tela que o usuário verá.
      home: const MainNavigation(),
    );
  }
}

/// Esta classe gerencia a troca entre as 4 abas principais do app.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  
  int _indiceSelecionado = 0; //controla se a aba esta nativa 

  // Retorna o Widget (página) correspondente ao index 
  Widget _obterPagina(int index) {
    switch (index) {
      case 0: return const HomePage();       // Resumo do dia e metas.
      case 1: return const HistoricoPage();   // Lista de refeições passadas.
      case 2: return const EstatisticasPage(); // Gráficos e médias.
      case 3: return const ConfiguracoesPage(); // Notificações e horários.
      default: return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Exibe a página atual baseada no índice.
      body: _obterPagina(_indiceSelecionado),

      // Barra inferior de navegação.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceSelecionado,
        onDestinationSelected: (index) {
          // Atualiza o estado para trocar a página.
          setState(() {
            _indiceSelecionado = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1B5E20).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF1B5E20)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFF1B5E20)),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF1B5E20)),
            label: 'Estatísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF1B5E20)),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}
