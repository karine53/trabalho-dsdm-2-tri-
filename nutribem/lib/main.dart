import 'package:flutter/material.dart';
import 'pages/pg-inicial.dart'; // Importa o arquivo que você salvou

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D5A27)),
      ),
      // Chama a tela principal que está no arquivo pg-inicial.dart
      home: const NutritionHomeScreen(), 
    );
  }
}
