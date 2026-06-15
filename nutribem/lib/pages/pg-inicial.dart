import 'package:flutter/material.dart';

void main() {
  runApp(const NutritionApp());
}

class NutritionApp extends StatelessWidget {
  const NutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D5A27)),
      ),
      home: const NutritionHomeScreen(),
    );
  }
}

class NutritionHomeScreen extends StatelessWidget {
  const NutritionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Verde
                const HeaderSection(),
                
                // Conteúdo Principal com Overlap
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        // Card Resumo Nutricional
                        const NutritionalSummaryCard(),
                        const SizedBox(height: 16),
                        
                        // Cards de Macros
                        const Row(
                          children: [
                            Expanded(child: MacroCard(label: 'Carbs', value: '168g', progress: 0.7, color: Colors.blue)),
                            SizedBox(width: 12),
                            Expanded(child: MacroCard(label: 'Proteína', value: '62g', progress: 0.5, color: Colors.orange)),
                            SizedBox(width: 12),
                            Expanded(child: MacroCard(label: 'Gordura', value: '44g', progress: 0.4, color: Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Estatísticas Rápidas
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            StatItem(icon: Icons.star_outline, value: '82', label: 'Pontuação', iconColor: Colors.amber),
                            StatItem(icon: Icons.restaurant_menu, value: '4', label: 'Refeições', iconColor: Colors.grey),
                            StatItem(icon: Icons.water_drop_outlined, value: '1,4 L', label: 'Água', iconColor: Colors.blue),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Seção Refeições de Hoje
                        const MealsHeader(),
                        const SizedBox(height: 16),
                        const MealListItem(
                          icon: Icons.wb_sunny_outlined,
                          title: 'Café da Manhã',
                          subtitle: 'Aveia + Banana + Mel',
                          calories: '380 kcal',
                          time: '07:30',
                        ),
                        const MealListItem(
                          icon: Icons.wb_cloudy_outlined,
                          title: 'Almoço',
                          subtitle: 'Frango grelhado + Arroz + Salada',
                          calories: '620 kcal',
                          time: '12:15',
                        ),
                        const MealListItem(
                          icon: Icons.wb_twilight_outlined,
                          title: 'Lanche',
                          subtitle: 'Iogurte + Granola',
                          calories: '210 kcal',
                          time: '16:00',
                        ),
                        const SizedBox(height: 100), // Espaço para o botão
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Botão Adicionar Refeição
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Adicionar Refeição',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 60),
      decoration: const BoxDecoration(
        color: Color(0xFF2D5A27),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como está sua\nalimentação hoje?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Ter, 10 Jun 2025',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class NutritionalSummaryCard extends StatelessWidget {
  const NutritionalSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo Nutricional',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Text(
            'Meta diária: 2.000 kcal',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '1.340',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'kcal',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.67,
              minHeight: 8,
              backgroundColor: Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }
}

class MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const MacroCard({
    super.key,
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const StatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class MealsHeader extends StatelessWidget {
  const MealsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Refeições de Hoje',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          'Ver todas',
          style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class MealListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String calories;
  final String time;

  const MealListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.calories,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2D5A27), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      calories,
                      style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2D5A27),
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant_outlined), label: 'Refeições'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Histórico'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Estatísticas'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Configurações'),
      ],
    );
  }
}
