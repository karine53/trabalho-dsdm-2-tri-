import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // formata numeros no padrao brasileiro
import '../database/dabase_helper.dart'; // permite buscar refeiçoes salvas no sqlite
import '../models/refeicao.dart'; // importa o modelo da refeiçao

// é um stetefulwidget pq os dados musam quando troca
// a semana ou cadastra novas refeiçoes
class EstatisticasPage extends StatefulWidget {
  const EstatisticasPage({super.key});
  //superKey passa uma chave pro pai que ajuda o flutter identificar o widget

  @override
  State<EstatisticasPage> createState() => _EstatisticasPageState();
}

class _EstatisticasPageState extends State<EstatisticasPage> {
  // aq fica tudo o que pode mudar na tela
  final DatabaseHelper _db = DatabaseHelper.instance;
  // cria uma referencia ao banco

  // [offsetSemana] controla qual semana estamos visualizando:
  // 0 = semana atual, -1 = semana passada, -2 = duas semanas atrás, etc.
  int _offsetSemana = 0;
  bool _carregando = true; // controla se a tela esta carregando

  // Estas variáveis armazenam os resultados dos cálculos das estatísticas.
  int _pontuacaoSemanal = 0;
  double _consumoMedioCalorico = 0;
  List<double> _consumoDiario = List.filled(
    7,
    0.0,
  ); // cria uma lista com 7 posiçoes (dias da semana, e depois recebe os valores)

  // [categoriasConsumidas] armazena a porcentagem de cada categoria.
  Map<String, double> _categoriasConsumidas = {
    'Proteína': 0,
    'Carboidrato': 0,
    'Vegetal': 0,
  };

  int _totalRefeicoesSemana = 0; // qntd de refeiçoes registradas na semana
  double _percentualCrescimento =
      0; // guarda o percentual de crescimento comparado a semana passada

  @override
  void initState() {
    super.initState();
    // Ao iniciar a tela, carregamos os dados da semana atual.
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    // Ativa o estado de carregamento para mostrar o CircularProgressIndicator.
    setState(() => _carregando = true); // indorma que esta carregando os dados

    try {
      DateTime agora = DateTime.now();
      //pega a data atual e calcula ate o inicio da semana, calcula quantos dias precisa para voltar para segunda
      // of set semana se for -1 volta uma semana assim vai
      DateTime inicioSemana = agora.subtract(
        Duration(days: (agora.weekday - 1) + (-_offsetSemana * 7)),
      );
      DateTime fimSemana = inicioSemana.add(
        const Duration(days: 6),
      ); // Fim da semana é 6 dias após o início.

      // Formata as datas para o padrão 'yyyy-MM-dd' que o banco de dados espera.
      String dataInicio = DateFormat('yyyy-MM-dd').format(inicioSemana);
      String dataFim = DateFormat('yyyy-MM-dd').format(fimSemana);

      // Busca as refeições no banco de dados para o intervalo calculado.
      final refeicoes = await _db.getRefeicoesPorIntervalo(dataInicio, dataFim);

      // Processa os dados brutos para gerar as estatísticas.
      _processarEstatisticas(refeicoes);
    } catch (e) {
      // Em caso de erro, imprime no console para depuração.
      debugPrint("ERRO ESTATISTICAS: $e");
    }

    // Se o widget ainda estiver montado, desativa o estado de carregamento.
    if (mounted) {
      setState(() => _carregando = false);
    }
  }

  // recebe uma lista de objetos refeicao
  void _processarEstatisticas(List<Refeicao> refeicoes) {
    _totalRefeicoesSemana = refeicoes.length; // total de refeiçoes
    /// .length retorna o tamanho da lista
    double totalCalorias =
        0; //cria uma variavel que guarda a soma de todas as calorias
    Map<int, double> caloriasPorDia =
        {}; // cria um mapa vazio que vai guardar o dia da semana

    // Inicializa as contagens de categorias
    Map<String, double> categoriasCount = {
      // cria um mapa para contar quantas refeiçoes existem em cada refeiçao
      'Proteína': 0,
      'Carboidrato': 0,
      'Vegetal': 0,
    }; // se nao tiver nada o valor vira 0

    // soma as calorias
    for (var r in refeicoes) {
      totalCalorias += r.calorias;
      //pega cada refeiçao da lista que vira o r e vai vendo quantas calorias tem
      // faz isso com tudo depois soma

      DateTime data = DateTime.parse(
        r.data,
      ); // transforma a string em uma data (datatime)
      caloriasPorDia[data.weekday] =
          (caloriasPorDia[data.weekday] ?? 0) +
          r.calorias; // busca o valor de caloruas esse dia, se existir usa ele se nao usa 0, e depois soma com as demais refeiçoes
      //data.weekday descobre o dia da semana
      // Incrementa a contagem da categoria se ela existir no nosso mapa.
      if (r.categoria != null && // verifica se a refeiçao tem caloria 
      categoriasCount.containsKey(r.categoria)) { // verifica se a categoria existe no mapa 
        categoriasCount[r.categoria!] =
            (categoriasCount[r.categoria!] ?? 0) + 1; // aumenta a quantidade daquela categoria 
      }
    }

    // Calcula o consumo calórico médio por dia.
    _consumoMedioCalorico = refeicoes.isEmpty ? 0 : totalCalorias / 7;
    //refeicoes.isEmpty ve se a lista de refeiçoes esta vazia

    
    int pontosPorRefeicao =
     (_totalRefeicoesSemana * 5)// cada refeiçao vale 5 pontos, ai pega o total de refeiçao multiplica por 5 
     .clamp(0, 70);// nao pode passar de 70 entao o maximo é 70 
    // Bônus de 30 pontos se todas as categorias (Proteína, Carboidrato, Vegetal) foram consumidas.
    int bonusEquilibrio =
     (categoriasCount.values//.values pega os valores 
     .every((v) => v > 0)) // ve se todos sao maiores que 0 
      ? 30 : 0; 
    _pontuacaoSemanal = pontosPorRefeicao + bonusEquilibrio;
    // a pontuaçao semanal vai ser a soma dos pontos por refeiçao mais o bonus 

    
    for (int i = 1; i <= 7; i++) { // percorre todos os dias da semana e ve a quantidade de calorias 
      _consumoDiario[i - 1] = caloriasPorDia[i] ?? 0; // i-1 pq a lista comeca no 0 
      // ve se na segunda que é o 0 foram consumidas quantas calorias, se nao tiver usa 0 
    }

    // Calcula os percentuais de cada categoria consumida.
    double totalCategorias = categoriasCount.values // pega somente os valores da categoria 
    .fold( // acomula os valores comeca em 0 
      0,
      (sum, val) => sum + val, // sum = valor inicial na primeira vez e nas outras a soma 
                               // val = valor que quer somar 
    );
    if (totalCategorias > 0) { // ve se existe alguma refeiçao cadastrada 
      _categoriasConsumidas = 
      categoriasCount.map(
        (key, value) =>  // => significa retorna 
        MapEntry(key, (value / totalCategorias) * 100), // divide o total de alguma refeiçao pelo total de todas as categorias 
      );
    } else {
      // Se não houver refeições, todas as categorias ficam com 0%.
      _categoriasConsumidas = {'Proteína': 0, 'Carboidrato': 0, 'Vegetal': 0};
    }
 

 // percentual fixo 
    _percentualCrescimento =
     _totalRefeicoesSemana > 0 ? 12.0 : 0.0; // tem que ter pelo menos uma refeiçao, se sim vai o valor, se nao vai 0 
  }

  /// Retorna o texto para o período selecionado (ex: 'Esta semana', 'Semana passada').
  String _getTextoPeriodo() {
    if (_offsetSemana == 0) return 'Esta semana'; // ofsetsemana - deslocamento de semanas 
    if (_offsetSemana == -1) return 'Semana passada';
    return 'Há ${-_offsetSemana} semanas'; // Para semanas anteriores a -1.
  }

  @override
  Widget build(BuildContext context) {
    // O Scaffold fornece a estrutura visual básica da tela (AppBar, Body).
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar( // barra superior da pg 
        backgroundColor: Colors.white,
        elevation: 0, // Remove a sombra da AppBar.
        title: const Text(
          'Estatísticas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pop(context), // Botão de voltar para a tela anterior.
        ),
      ),
  
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)), // mostra um circulo carregano a pg enquanto os dados estao sendo carregados 
            ) 
          : SingleChildScrollView( // permite rolar a pg se tiver muito conteudo 
            // terminou de carregar e mostra a tela 
              padding: const EdgeInsets.symmetric(horizontal: 20), // cria margem lateral 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // alinha tudo no começo da esquerda  
                children: [
                  // ── NAVEGAÇÃO ENTRE SEMANAS ───────────────────────────────────────
                  // Permite ao usuário ir para a semana anterior ou próxima.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // deixa os elementos um do lado do outro mas mais espaçado 
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                        ), // Botão para semana anterior.
                        onPressed: () {
                          setState(
                            () => _offsetSemana--,
                          ); // atualiza o valor do deslocamento da semana 
                          _carregarDados(); // Recarrega os dados para a nova semana.
                        },
                      ),
                      Text(
                        _getTextoPeriodo(), // Exibe o texto do período (ex: 'Esta semana').
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                        ), // Botão para próxima semana.
                        // Desabilita o botão se já estiver na semana atual (_offsetSemana >= 0).
                        onPressed: _offsetSemana >= 0
                            ? null
                            : () {
                                setState(
                                  () => _offsetSemana++,
                                ); // Incrementa o offset.
                                _carregarDados(); // Recarrega os dados.
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildPontuacaoCard(), // Card de pontuação.
                  const SizedBox(height: 20),
                  _buildConsumoCaloricoCard(), // Card do gráfico de calorias.
                  const SizedBox(height: 20),
                  const Text(
                    'Distribuição por Categoria', // Título da seção de categorias.
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildCategoriaList(), // Lista de categorias com barras de progresso.
                  const SizedBox(height: 20),
                  _buildTotalRefeicoesCard(), // Card de total de refeições.
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  /// [buildPontuacaoCard] constrói o card que exibe a pontuação semanal e as estrelas.
  Widget _buildPontuacaoCard() {
    
    int estrelas = (_pontuacaoSemanal / 20) //pega a pontuaçao e divide por 20 pq cada estrela vale 20 pontos 
    .round() // arrenda o numero 
    .clamp(0, 5); //limita para ser no maximo ate 5
    return Card( // o metodo retorna um card 
      color: const Color(0xFF1B5E20), // Cor de fundo do card.
      shape: RoundedRectangleBorder(// define o formato do card 
        borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, //alinha todos os widgets a esquerda 
          children: [
            const Text(
              'Pontuação de Saúde', // Título do card.
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '$_pontuacaoSemanal', // Exibe a pontuação calculada dinamicamente.
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' /100', // Pontuação máxima.
                  style: TextStyle(color: Colors.white60, fontSize: 20),
                ),
                const Spacer(), // Empurra as estrelas para a direita. spacer ocupa todo o espaço vazio da tela 
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      // Se o índice for menor que o número de estrelas, mostra estrela cheia, senão, vazia.
                      index < estrelas ? Icons.star // mostra a estrela cheia 
                       : Icons.star_border, //mostra a estrela vazia 
                      color: index < estrelas
                          ? Colors.amber
                          : Colors.white30, // Cor da estrela.
                      size: 24,
                    );
                  }),
                ),
              ],
            ),
            Text(
              // Mensagem dinâmica baseada na pontuação.
              _pontuacaoSemanal > 50
                  ? 'Bom desempenho! Continue assim.' // se for maior que 50 :-> se for verdadeira 
                  : 'Registre mais refeições para pontuar.', // caso contrario ?-> caso ao contrario 
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// [buildConsumoCaloricoCard] constrói o card com o gráfico de barras do consumo calórico diário.
  Widget _buildConsumoCaloricoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder( //define o formato do cartao
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consumo Calórico Diário', // Título do gráfico.
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Média: ${NumberFormat('#,###', 'pt_BR').format(_consumoMedioCalorico.round())} kcal/dia', //formata para o padrao brasileiro depois arredonda o consumo medio
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // distribui igualmente as barras 
                crossAxisAlignment: CrossAxisAlignment.end, //alinha todas as barras pela parte inferior, assim elas descem para cima 
                children: List.generate(7, (index) { //cria 7 barras
                  final dias = [
                    'Seg',
                    'Ter',
                    'Qua',
                    'Qui',
                    'Sex',
                    'Sáb',
                    'Dom',
                  ];
                  // Encontra o valor máximo para escalar as barras do gráfico.
                  double maxVal  //cria uma variavel
                  = _consumoDiario.reduce( // o metodo redece percorre toda a lista procurando o maior valor 
                    (a, b) => a > b ? a : b, // compara os dois valores, se a for maior retorna a caso contrario retorna b 
                  );
                  // Se não houver dados, define um valor base para evitar divisão por zero e barras invisíveis.
                  if (maxVal == 0) maxVal = 1000; //verifica se ninguem registrou as refeiçao ai define um valor padrao 
                  // Calcula a altura da barra proporcionalmente ao valor máximo.
                  double heightFactor = (_consumoDiario[index] / maxVal)// pega o consumo daquele dia e divide pelo maior valor encontrado 
                  .clamp(  //limita o valor 
                    0.05, // nunca menor que 5%
                    1.0, //nunca maior que 100%
                  ); // Garante altura mínima.
                  bool temDados =  /// cria uma variavel booleana 
                  _consumoDiario[index] > 0; // se o consumo for maior que 0 tem dados  verdadeiros 

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end, 
                    children: [
                      if (temDados) // Mostra o valor apenas se houver dados para o dia.
                        Text(
                          '${_consumoDiario[index].round()}', // mostra as calorias daquele dia 
                          style: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        width: 25,
                        height: 80 * heightFactor, // Altura da barra.
                        decoration: BoxDecoration(
                          color: temDados
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE8F5E9), // Cor da barra.
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dias[index], // Nome do dia da semana.
                        style: TextStyle(
                          color: temDados
                              ? const Color(0xFF1B5E20)
                              : Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [buildCategoriaList] constrói a lista de categorias com barras de progresso.
  Widget _buildCategoriaList() {
    // Lista de categorias a serem exibidas (sem 'Fruta').
    final categorias = [
      {'nome': 'Proteína', 'emoji': '🥩', 'cor': Colors.orange},
      {'nome': 'Carboidrato', 'emoji': '🍚', 'cor': Colors.blue},
      {'nome': 'Vegetal', 'emoji': '🥦', 'cor': Colors.green},
    ];

    return Column( // cat representa cada elemento da lista 
      children: categorias.map((cat) { //percorre todos os elementos a lista 
        double percent =
            _categoriasConsumidas[cat['nome']] ?? //procura o percentual correspondente 
            0; // Pega o percentual calculado.
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Text(
                  cat['emoji'] as String,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded( // faz a parte central ocupar todo o espaço disponivel
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, //alinha tudo a esquerda 
                    children: [
                      Text(
                        cat['nome'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect( //recorta os cantos da barra
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value:
                              percent / 100, // Valor do progresso (0.0 a 1.0).
                          backgroundColor: Colors.grey.shade100,
                          color: cat['cor'] as Color,
                          minHeight: 6, //altura minima
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  '${percent.round()}%', // Exibe o percentual arredondado.
                  style: TextStyle(
                    color: cat['cor'] as Color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),// transforma os widgets em uma lista que a column consegue exibir 
    );
  }

  /// [buildTotalRefeicoesCard] exibe o número total de refeições registradas na semana.
  Widget _buildTotalRefeicoesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total de Refeições ${_getTextoPeriodo().toLowerCase()}', //retorna o periodo selecionado e o toLowe converte o texto para letras minusculas
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline, //alinha os textos pela linha base das letras 
                textBaseline: TextBaseline.alphabetic, //informa que o alinhamento sera feito usando a base do alfabeto 
                children: [
                  Text(
                    '$_totalRefeicoesSemana', //mostra o numero de refeiçoes registradas 
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'refeições\nregistradas',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Exibe o percentual de crescimento apenas se houver refeições registradas.
          if (_totalRefeicoesSemana > 0)
            Row(
              children: [
                const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                Text(
                  ' ${_percentualCrescimento.round()}%',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
