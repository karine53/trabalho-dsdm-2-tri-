import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Novo import
import 'pages/pg-inicial.dart';
import 'pages/historico_page.dart';

void main() async {
  // 1. Garante inicialização total do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa SQLite para Desktop
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 3. Inicializa TODAS as localidades disponíveis para evitar o erro
await initializeDateFormatting();

  runApp(const NutriBemApp());
}

class NutriBemApp extends StatelessWidget {
  const NutriBemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriBem',
      debugShowCheckedModeBanner: false,
      // 4. Define explicitamente o idioma do App
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _indiceSelecionado = 0;

  // Quando criar as outras páginas, substitua o Placeholder pela página real
  final List<Widget> _paginas = [
    const HomePage(),
    const Placeholder(), // RefeicoesPaage()
    const HistoricoPage(),
    const Placeholder(), // EstatisticasPage()
    const Placeholder(), // ConfiguracoesPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indiceSelecionado,
        children: _paginas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceSelecionado,
        onDestinationSelected: (index) {
          setState(() => _indiceSelecionado = index);
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
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant, color: Color(0xFF1B5E20)),
            label: 'Refeições',
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