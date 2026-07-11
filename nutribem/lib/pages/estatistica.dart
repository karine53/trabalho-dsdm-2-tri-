import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dabase_helper.dart';
import '../models/refeicao.dart';

class EstatisticasPage extends StatefulWidget {
  const EstatisticasPage({super.key});

  @override
  State<EstatisticasPage> createState() => _EstatisticasPageState();
}

class _EstatisticasPageState extends State<EstatisticasPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  String _periodoSelecionado = 'Esta semana';
  bool _carregando = true;

  // Dados para a UI
  int _pontuacaoSemanal = 0;
  double _consumoMedioCalorico = 0;
  List<double> _consumoDiario = List.filled(7, 0.0);
  Map<String, double> _categoriasConsumidas = {
    'Proteína': 0,
    'Carboidrato': 0,
    'Vegetal': 0,
    'Fruta': 0,
  };
  int _totalRefeicoesSemana = 0;
  double _percentualCrescimento = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {

  setState(() => _carregando = true);

  try {

    DateTime agora = DateTime.now();

    DateTime inicioSemana =
        agora.subtract(Duration(days: agora.weekday - 1));

    DateTime fimSemana =
        inicioSemana.add(const Duration(days: 6));


    String dataInicio =
        DateFormat('yyyy-MM-dd').format(inicioSemana);

    String dataFim =
        DateFormat('yyyy-MM-dd').format(fimSemana);



    print("BUSCANDO ESTATISTICAS:");
    print("INICIO: $dataInicio");
    print("FIM: $dataFim");



    final refeicoes =
        await _db.getRefeicoesPorIntervalo(
          dataInicio,
          dataFim,
        );


    print("REFEIÇÕES: ${refeicoes.length}");



    _processarEstatisticas(refeicoes);



  } catch (e) {

    print("ERRO ESTATISTICAS: $e");

  }


  if (mounted) {

    setState(() {

      _carregando = false;

    });

  }

}

  void _processarEstatisticas(List<Refeicao> refeicoes) {
    _totalRefeicoesSemana = refeicoes.length;
    
    double totalCalorias = 0;
    Map<int, double> caloriasPorDia = {};
    Map<String, double> categoriasCount = {
      'Proteína': 0,
      'Carboidrato': 0,
      'Vegetal': 0,
      'Fruta': 0,
    };

    for (var r in refeicoes) {
      totalCalorias += r.calorias;
      
      // Calorias por dia da semana (1-7)
      DateTime data = DateTime.parse(r.data);
      caloriasPorDia[data.weekday] = (caloriasPorDia[data.weekday] ?? 0) + r.calorias;

      // Contagem por categoria
      if (r.categoria != null && categoriasCount.containsKey(r.categoria)) {
        categoriasCount[r.categoria!] = (categoriasCount[r.categoria!] ?? 0) + 1;
      }
    }

    // Média e Pontuação (Lógica simplificada para exemplo)
    _consumoMedioCalorico = refeicoes.isEmpty ? 0 : totalCalorias / 7;
    _pontuacaoSemanal = (_consumoMedioCalorico > 0) ? (87) : 0; // Mock valor da imagem
    
    // Preencher gráfico de barras
    for (int i = 1; i <= 7; i++) {
      _consumoDiario[i - 1] = caloriasPorDia[i] ?? 0;
    }

    // Calcular percentuais de categorias
    double totalCategorias = categoriasCount.values.fold(0, (sum, val) => sum + val);
    if (totalCategorias > 0) {
      _categoriasConsumidas = categoriasCount.map((key, value) => MapEntry(key, (value / totalCategorias) * 100));
    } else {
      // Mock valores da imagem para demonstração se estiver vazio
      _categoriasConsumidas = {
        'Proteína': 38,
        'Carboidrato': 28,
        'Vegetal': 20,
        'Fruta': 14,
      };
    }
    
    _percentualCrescimento = 12; // Mock valor da imagem
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        
      ),
      body: _carregando 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estatísticas',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    ChoiceChip(
                      label: const Text('Esta semana'),
                      selected: _periodoSelecionado == 'Esta semana',
                      onSelected: (val) {},
                      selectedColor: const Color(0xFFE8F5E9),
                      labelStyle: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide.none,
                      showCheckmark: false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildPontuacaoCard(),
                const SizedBox(height: 20),
                _buildConsumoCaloricoCard(),
                const SizedBox(height: 20),
                const Text(
                  'Categoria Mais Consumida',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildCategoriaList(),
                const SizedBox(height: 20),
                _buildTotalRefeicoesCard(),
                const SizedBox(height: 30),
              ],
            ),
          ),
    );
  }

  Widget _buildPontuacaoCard() {
    return Card(
      color: const Color(0xFF1B5E20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pontuação Semanal',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '$_pontuacaoSemanal',
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const Text(
                  ' /100',
                  style: TextStyle(color: Colors.white60, fontSize: 20),
                ),
                const Spacer(),
                Row(
  children: List.generate(5, (index) {
    return Icon(
      index < (_pontuacaoSemanal / 20).round()
          ? Icons.star
          : Icons.star_border,
      color: index < (_pontuacaoSemanal / 20).round()
          ? Colors.amber
          : Colors.white30,
      size: 20,
    );
  }),
)
              ],
            ),
            const Text(
              '↑ +5 pontos em relação à semana passada',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

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
              'Consumo Calórico Semanal',
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
                  double maxVal = _consumoDiario.reduce((a, b) => a > b ? a : b);
                  if (maxVal == 0) maxVal = 1;
                  double heightFactor = (_consumoDiario[index] / maxVal).clamp(0.1, 1.0);
                  bool isTer = _consumoDiario[index] > 0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_consumoDiario[index] > 0)
  Text(
    '${_consumoDiario[index].round()}',
    style: const TextStyle(
      color: Colors.green,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    ),
  ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: 80 * heightFactor,
                        decoration: BoxDecoration(
                          color: isTer ? const Color(0xFF4CAF50) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dias[index],
                        style: TextStyle(color: isTer ? Colors.green : Colors.grey, fontSize: 10),
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

  Widget _buildCategoriaList() {
    final categorias = [
      {'nome': 'Proteína', 'emoji': '🥩', 'cor': Colors.orange},
      {'nome': 'Carboidrato', 'emoji': '🍚', 'cor': Colors.blue},
      {'nome': 'Vegetal', 'emoji': '🥦', 'cor': Colors.green},
      {'nome': 'Fruta', 'emoji': '🍎', 'cor': Colors.red},
    ];

    return Column(
      children: categorias.map((cat) {
        double percent = _categoriasConsumidas[cat['nome']] ?? 0;
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
                          value: percent / 100,
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
                  '${percent.round()}%',
                  style: TextStyle(color: cat['cor'] as Color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

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
              const Text('Total de Refeições esta semana', style: TextStyle(color: Colors.grey, fontSize: 12)),
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