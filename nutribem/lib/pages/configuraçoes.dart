import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';


class ConfiguracoesPage extends StatefulWidget {

  const ConfiguracoesPage({super.key});


  @override
  State<ConfiguracoesPage> createState() =>
      _ConfiguracoesPageState();

}



class _ConfiguracoesPageState
    extends State<ConfiguracoesPage> {


  bool notificacoesAtivas = false;


  Map<String,String> horarios = {

    "Café da manhã": "08:00",
    "Almoço": "12:00",
    "Lanche": "15:30",
    "Jantar": "19:30",
    "Água": "10:00",

  };



  @override
  void initState() {

    super.initState();

    carregarConfiguracoes();

  }





  Future<void> carregarConfiguracoes() async {

    final prefs =
        await SharedPreferences.getInstance();


    setState(() {

      notificacoesAtivas =
          prefs.getBool('notificacoes') ?? false;


      horarios["Café da manhã"] =
          prefs.getString('cafe') ?? "08:00";

      horarios["Almoço"] =
          prefs.getString('almoco') ?? "12:00";

      horarios["Lanche"] =
          prefs.getString('lanche') ?? "15:30";

      horarios["Jantar"] =
          prefs.getString('janta') ?? "19:30";

      horarios["Água"] =
          prefs.getString('agua') ?? "10:00";

    });

  }





  Future<void> salvarSwitch(bool valor) async {


    final prefs =
        await SharedPreferences.getInstance();


    await prefs.setBool(
      'notificacoes',
      valor,
    );


    setState(() {

      notificacoesAtivas = valor;

    });



    if(valor){

      await NotificationService.solicitarPermissao();

      await NotificationService.configurarHorarios();


    }else{

      await NotificationService.cancelarNotificacoes();

    }

  }







  Future<void> escolherHorario(String nome) async {


    final horarioAtual =
        horarios[nome]!.split(":");


    final TimeOfDay? escolhido =
        await showTimePicker(

          context: context,

          initialTime: TimeOfDay(

            hour: int.parse(horarioAtual[0]),

            minute: int.parse(horarioAtual[1]),

          ),

        );



    if(escolhido != null){


      String novoHorario =

          "${escolhido.hour.toString().padLeft(2,'0')}:"
          "${escolhido.minute.toString().padLeft(2,'0')}";



      final prefs =
          await SharedPreferences.getInstance();


      setState(() {

        horarios[nome] = novoHorario;

      });



      if(nome=="Café da manhã"){

        await prefs.setString(
            'cafe',
            novoHorario);

      }


      if(nome=="Almoço"){

        await prefs.setString(
            'almoco',
            novoHorario);

      }


      if(nome=="Lanche"){

        await prefs.setString(
            'lanche',
            novoHorario);

      }


      if(nome=="Jantar"){

        await prefs.setString(
            'janta',
            novoHorario);

      }


      if(nome=="Água"){

        await prefs.setString(
            'agua',
            novoHorario);

      }



      if(notificacoesAtivas){

        await NotificationService.configurarHorarios();

      }

    }


  }







  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor: Colors.grey[100],


      appBar: AppBar(

        title: const Text(

          "Configurações",

          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),

        ),

        centerTitle: true,

        backgroundColor: Colors.white,

        foregroundColor: Colors.black,

        elevation: 0,

      ),



      body: ListView(

        padding: const EdgeInsets.all(20),


        children: [



          Card(

            shape: RoundedRectangleBorder(

              borderRadius:
              BorderRadius.circular(15),

            ),


            child: SwitchListTile(

              secondary: const Icon(

                Icons.notifications,

                color: Color(0xFF1B5E20),

              ),


              title: const Text(

                "Notificações Diárias",

                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),

              ),


              subtitle: const Text(

                "Lembretes de refeições e água",

              ),


              activeColor:
              const Color(0xFF1B5E20),


              value: notificacoesAtivas,


              onChanged: salvarSwitch,

            ),

          ),





          const SizedBox(height:25),



          const Text(

            "HORÁRIOS",

            style: TextStyle(

              fontWeight: FontWeight.bold,

              color: Colors.grey,

            ),

          ),



          const SizedBox(height:10),





          ...horarios.entries.map((item){


            return Card(

              child: ListTile(

                leading: const Icon(

                  Icons.access_time,

                  color: Color(0xFF1B5E20),

                ),


                title: Text(item.key),


                trailing: Text(

                  item.value,

                  style: const TextStyle(

                    fontWeight: FontWeight.bold,

                  ),

                ),


                onTap: () =>
                    escolherHorario(item.key),

              ),

            );


          }),


        ],


      ),


    );

  }

}