import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dabase_helper.dart';
import '../models/refeicao.dart';

/// A classe [EstatisticasPage] é um StatefulWidget que exibe estatísticas de refeições.
/// Ela permite ao usuário visualizar dados como pontuação semanal, consumo calórico
/// e distribuição por categoria, com a capacidade de navegar entre semanas.
class EstatisticasPage extends StatefulWidget {
  const EstatisticasPage({super.key});

  @override
  State<EstatisticasPage> createState() => _EstatisticasPageState();
}

class _EstatisticasPageState extends State<EstatisticasPage> {
  // Instância do nosso helper de banco de dados para interagir com o SQLite.
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  // [offsetSemana] controla qual semana estamos visualizando:
  // 0 = semana atual, -1 = semana passada, -2 = duas semanas atrás, etc.
  int _offsetSemana = 0;
  bool _carregando = true; // Flag para mostrar um indicador de carregamento.

  // ── DADOS PARA EXIBIÇÃO NA INTERFACE ───────────────────────────────────────
  // Estas variáveis armazenam os resultados dos cálculos das estatísticas.
  int _pontuacaoSemanal = 0;
  double _consumoMedioCalorico = 0;
  List<double> _consumoDiario = List.filled(7, 0.0); // Calorias por dia da semana.
  
  // [categoriasConsumidas] armazena a porcentagem de cada categoria.
  // A categoria 'Fruta' foi removida conforme solicitado.
  Map<String, double> _categoriasConsumidas = {
    'Proteína': 0,
    'Carboidrato': 0,
    'Vegetal': 0,
  };
  
  int _totalRefeicoesSemana = 0;
  double _percentualCrescimento = 0; // Exemplo de métrica de crescimento.

  @override
  void initState() {
    super.initState();
    // Ao iniciar a tela, carregamos os dados da semana atual.
    _carregarDados();
  }

  /// [carregarDados] é o método assíncrono que busca as refeições no banco de dados
  /// para o período selecionado (definido por [_offsetSemana]) e processa as estatísticas.
  Future<void> _carregarDados() async {
    // Ativa o estado de carregamento para mostrar o CircularProgressIndicator.
    setState(() => _carregando = true);

    try {
      DateTime agora = DateTime.now();
      
      // Calcula o início da semana atual e ajusta com base no [_offsetSemana].
      // Ex: se _offsetSemana for -1, ele subtrai mais 7 dias para pegar a semana anterior.
      DateTime inicioSemana = agora.subtract(Duration(days: (agora.weekday - 1) + (-_offsetSemana * 7)));
      DateTime fimSemana = inicioSemana.add(const Duration(days: 6)); // Fim da semana é 6 dias após o início.

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

  /// [processarEstatisticas] calcula todas as métricas a partir da lista de refeições.
  void _processarEstatisticas(List<Refeicao> refeicoes) {
    _totalRefeicoesSemana = refeicoes.length;
    
    double totalCalorias = 0;
    Map<int, double> caloriasPorDia = {}; // Armazena calorias por dia da semana (1=Seg, 7=Dom).
    
    // Inicializa as contagens de categorias (sem 'Fruta').
    Map<String, double> categoriasCount = {
      'Proteína': 0,
      'Carboidrato': 0,
      'Vegetal': 0,
    };

    // Itera sobre cada refeição para somar calorias e contar categorias.
    for (var r in refeicoes) {
      totalCalorias += r.calorias;
      
      // Acumula calorias para cada dia da semana.
      DateTime data = DateTime.parse(r.data);
      caloriasPorDia[data.weekday] = (caloriasPorDia[data.weekday] ?? 0) + r.calorias;

      // Incrementa a contagem da categoria se ela existir no nosso mapa.
      if (r.categoria != null && categoriasCount.containsKey(r.categoria)) {
        categoriasCount[r.categoria!] = (categoriasCount[r.categoria!] ?? 0) + 1;
      }
    }

    // Calcula o consumo calórico médio por dia.
    _consumoMedioCalorico = refeicoes.isEmpty ? 0 : totalCalorias / 7;
    
    // ── PONTUAÇÃO DINÂMICA (NÃO MAIS FIXA EM 87) ───────────────────────────
    // A pontuação agora reflete a atividade do usuário.
    // Exemplo: 5 pontos por refeição registrada (máximo de 70 pontos para 14 refeições).
    int pontosPorRefeicao = (_totalRefeicoesSemana * 5).clamp(0, 70);
    // Bônus de 30 pontos se todas as categorias (Proteína, Carboidrato, Vegetal) foram consumidas.
    int bonusEquilibrio = (categoriasCount.values.every((v) => v > 0)) ? 30 : 0;
    _pontuacaoSemanal = pontosPorRefeicao + bonusEquilibrio;
    // A pontuação máxima é 100 (70 por refeições + 30 por equilíbrio).
    
    // Preenche a lista [_consumoDiario] para o gráfico de barras.
    for (int i = 1; i <= 7; i++) {
      _consumoDiario[i - 1] = caloriasPorDia[i] ?? 0;
    }

    // Calcula os percentuais de cada categoria consumida.
    double totalCategorias = categoriasCount.values.fold(0, (sum, val) => sum + val);
    if (totalCategorias > 0) {
      _categoriasConsumidas = categoriasCount.map((key, value) => MapEntry(key, (value / totalCategorias) * 100));
    } else {
      // Se não houver refeições, todas as categorias ficam com 0%.
      _categoriasConsumidas = {'Proteína': 0, 'Carboidrato': 0, 'Vegetal': 0};
    }
    
    // [percentualCrescimento] é um valor de exemplo, pode ser calculado com base em semanas anteriores.
    _percentualCrescimento = _totalRefeicoesSemana > 0 ? 12.0 : 0.0;
  }

  /// Retorna o texto para o período selecionado (ex: 'Esta semana', 'Semana passada').
  String _getTextoPeriodo() {
    if (_offsetSemana == 0) return 'Esta semana';
    if (_offsetSemana == -1) return 'Semana passada';
    return 'Há ${-_offsetSemana} semanas'; // Para semanas anteriores a -1.
  }

  @override
  Widget build(BuildContext context) {
    // O Scaffold fornece a estrutura visual básica da tela (AppBar, Body).
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Remove a sombra da AppBar.
        title: const Text('Estatísticas', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), // Botão de voltar para a tela anterior.
        ),
      ),
      // [SingleChildScrollView] permite que o conteúdo da tela seja rolado se for muito grande.
      body: _carregando 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))) // Mostra carregamento.
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── NAVEGAÇÃO ENTRE SEMANAS ───────────────────────────────────────
                // Permite ao usuário ir para a semana anterior ou próxima.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left), // Botão para semana anterior.
                      onPressed: () {
                        setState(() => _offsetSemana--); // Decrementa o offset.
                        _carregarDados(); // Recarrega os dados para a nova semana.
                      },
                    ),
                    Text(
                      _getTextoPeriodo(), // Exibe o texto do período (ex: 'Esta semana').
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right), // Botão para próxima semana.
                      // Desabilita o botão se já estiver na semana atual (_offsetSemana >= 0).
                      onPressed: _offsetSemana >= 0 ? null : () {
                        setState(() => _offsetSemana++); // Incrementa o offset.
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
    // Calcula o número de estrelas com base na pontuação (cada estrela = 20 pontos).
    int estrelas = (_pontuacaoSemanal / 20).round().clamp(0, 5);

    return Card(
      color: const Color(0xFF1B5E20), // Cor de fundo do card.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const Text(
                  ' /100', // Pontuação máxima.
                  style: TextStyle(color: Colors.white60, fontSize: 20),
                ),
                const Spacer(), // Empurra as estrelas para a direita.
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      // Se o índice for menor que o número de estrelas, mostra estrela cheia, senão, vazia.
                      index < estrelas ? Icons.star : Icons.star_border,
                      color: index < estrelas ? Colors.amber : Colors.white30, // Cor da estrela.
                      size: 24,
                    );
                  }),
                )
              ],
            ),
            Text(
              // Mensagem dinâmica baseada na pontuação.
              _pontuacaoSemanal > 50 ? 'Bom desempenho! Continue assim.' : 'Registre mais refeições para pontuar.',
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
      shape: RoundedRectangleBorder(
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
              'Média: ${NumberFormat('#,###', 'pt_BR').format(_consumoMedioCalorico.round())} kcal/dia',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                  // Encontra o valor máximo para escalar as barras do gráfico.
                  double maxVal = _consumoDiario.reduce((a, b) => a > b ? a : b);
                  // Se não houver dados, define um valor base para evitar divisão por zero e barras invisíveis.
                  if (maxVal == 0) maxVal = 1000; 
                  // Calcula a altura da barra proporcionalmente ao valor máximo.
                  double heightFactor = (_consumoDiario[index] / maxVal).clamp(0.05, 1.0); // Garante altura mínima.
                  bool temDados = _consumoDiario[index] > 0;
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (temDados) // Mostra o valor apenas se houver dados para o dia.
                        Text(
                          '${_consumoDiario[index].round()}',
                          style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        width: 25,
                        height: 80 * heightFactor, // Altura da barra.
                        decoration: BoxDecoration(
                          color: temDados ? const Color(0xFF4CAF50) : const Color(0xFFE8F5E9), // Cor da barra.
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dias[index], // Nome do dia da semana.
                        style: TextStyle(color: temDados ? const Color(0xFF1B5E20) : Colors.grey, fontSize: 10),
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

    return Column(
      children: categorias.map((cat) {
        double percent = _categoriasConsumidas[cat['nome']] ?? 0; // Pega o percentual calculado.
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
                Text(cat['emoji'] as String, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat['nome'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percent / 100, // Valor do progresso (0.0 a 1.0).
                          backgroundColor: Colors.grey.shade100,
                          color: cat['cor'] as Color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  '${percent.round()}%', // Exibe o percentual arredondado.
                  style: TextStyle(color: cat['cor'] as Color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
              Text('Total de Refeições ${_getTextoPeriodo().toLowerCase()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$_totalRefeicoesSemana', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Text('refeições\nregistradas', style: TextStyle(color: Colors.grey, fontSize: 10)),
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
                Text(' ${_percentualCrescimento.round()}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
        ],
      ),
    );
  }
}
