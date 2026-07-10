import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'pages/pg-inicial.dart';
import 'pages/historico_page.dart';
import 'pages/estatistica.dart';
import 'pages/configuraçoes.dart';

import 'services/notification_service.dart';



// Configura horário local do celular para notificações
Future<void> configurarTimezone() async {

  tz.initializeTimeZones();

  final timezone =
      await FlutterTimezone.getLocalTimezone();

  tz.setLocalLocation(
    tz.getLocation(timezone),
  );

}



void main() async {

  WidgetsFlutterBinding.ensureInitialized();


  // Configura notificações
  if (!kIsWeb) {
  await configurarTimezone();
  await NotificationService.init();
}



  // Inicializa SQLite para Desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}



  // Datas em português
  await initializeDateFormatting(
    'pt_BR',
    null,
  );


  runApp(
    const NutriBemApp(),
  );

}





class NutriBemApp extends StatelessWidget {

  const NutriBemApp({super.key});


  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      title: 'NutriBem',

      debugShowCheckedModeBanner: false,


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

        colorScheme: ColorScheme.fromSeed(

          seedColor: const Color(0xFF1B5E20),

        ),

        useMaterial3: true,

      ),


      home: const MainNavigation(),

    );

  }

}







class MainNavigation extends StatefulWidget {

  const MainNavigation({super.key});


  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();

}





class _MainNavigationState
    extends State<MainNavigation> {


  int _indiceSelecionado = 0;



  Widget _obterPagina(int index) {


    switch(index){


      case 0:

        return const HomePage();



      case 1:

        return const HistoricoPage();



      case 2:

        return const EstatisticasPage();



      case 3:

        return const ConfiguracoesPage();



      default:

        return const HomePage();

    }

  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(


      body: _obterPagina(
        _indiceSelecionado,
      ),



      bottomNavigationBar:
      NavigationBar(


        selectedIndex:
        _indiceSelecionado,



        onDestinationSelected: (index){


          setState(() {

            _indiceSelecionado = index;

          });


        },



        backgroundColor:
        Colors.white,



        indicatorColor:
        const Color(0xFF1B5E20)
            .withOpacity(0.15),




        destinations: const [


          NavigationDestination(

            icon: Icon(
              Icons.home_outlined,
            ),

            selectedIcon: Icon(

              Icons.home,

              color:
              Color(0xFF1B5E20),

            ),

            label: 'Home',

          ),




          NavigationDestination(

            icon: Icon(
              Icons.history_outlined,
            ),

            selectedIcon: Icon(

              Icons.history,

              color:
              Color(0xFF1B5E20),

            ),

            label: 'Histórico',

          ),





          NavigationDestination(

            icon: Icon(
              Icons.bar_chart_outlined,
            ),

            selectedIcon: Icon(

              Icons.bar_chart,

              color:
              Color(0xFF1B5E20),

            ),

            label: 'Estatísticas',

          ),





          NavigationDestination(

            icon: Icon(
              Icons.settings_outlined,
            ),

            selectedIcon: Icon(

              Icons.settings,

              color:
              Color(0xFF1B5E20),

            ),

            label: 'Configurações',

          ),



        ],

      ),

    );

  }

}