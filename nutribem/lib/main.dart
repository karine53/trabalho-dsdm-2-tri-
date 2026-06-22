import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Novo import
import 'pages/pg-inicial.dart';

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
      home: const HomePage(),
    );
  }
}
