import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/pg-inicial.dart';
// import 'pages/refeicoes_page.dart';   // adicione quando criar
// import 'pages/historico_page.dart';   // adicione quando criar
// import 'pages/estatisticas_page.dart'; // adicione quando criar
// import 'pages/configuracoes_page.dart'; // adicione quando criar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const NutritionApp());
}

class NutritionApp extends StatelessWidget {
  const NutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nutrição App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5A27),
        ),
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
    const Placeholder(), // HistoricoPage()
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
        indicatorColor: const Color(0xFF2D5A27).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF2D5A27)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant, color: Color(0xFF2D5A27)),
            label: 'Refeições',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFF2D5A27)),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF2D5A27)),
            label: 'Estatísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF2D5A27)),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}