import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dabase_helper.dart';
import '../models/refeicao.dart';
import '../models/resumo_nutricional.dart';
import '../pages/adicionar_refeicao.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  DateTime _dataSelecionada = DateTime.now();
  ResumoNutricional? _resumo;
  List<Refeicao> _refeicoes = [];
  bool _carregando = true;

  // Metas diárias
  static const double _metaCalorias = 2000;
  static const double _metaCarbs = 250;
  static const double _metaProteina = 120;
  static const double _metaGordura = 65;
  static const double _metaAgua = 2.0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => _carregando = true);
    try {
      final dataStr = DateFormat('yyyy-MM-dd').format(_dataSelecionada);
      
      // Tenta buscar os dados do banco
      final refeicoes = await _db.getRefeicoesPorData(dataStr);
      final resumo = await _db.getResumoNutricional(dataStr);
      
      if (mounted) {
        setState(() {
          _refeicoes = refeicoes;
          _resumo = resumo;
          _carregando = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados na Home: $e");
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() => _dataSelecionada = picked);
      _carregarDados();
    }
  }

  Future<void> _adicionarRefeicao() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdicionarRefeicaoPage()),
    );
    if (resultado == true) _carregarDados();
  }

  Future<void> _editarRefeicao(Refeicao refeicao) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdicionarRefeicaoPage(refeicaoParaEditar: refeicao),
      ),
    );
    if (resultado == true) _carregarDados();
  }

  Future<void> _excluirRefeicao(Refeicao refeicao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir refeição'),
        content: Text('Deseja excluir "${refeicao.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _db.deleteRefeicao(refeicao.id!);
      _carregarDados();
    }
  }

  String get _dataFormatada {
    try {
      final hoje = DateTime.now();
      final h = DateTime(hoje.year, hoje.month, hoje.day);
      final s = DateTime(_dataSelecionada.year, _dataSelecionada.month, _dataSelecionada.day);
      if (s == h) return DateFormat("EEE, d MMM yyyy", 'pt_BR').format(_dataSelecionada);
      if (s == h.subtract(const Duration(days: 1))) {
        return 'Ontem, ${DateFormat("d MMM", 'pt_BR').format(_dataSelecionada)}';
      }
      return DateFormat("EEE, d MMM yyyy", 'pt_BR').format(_dataSelecionada);
    } catch (e) {
      return "${_dataSelecionada.day}/${_dataSelecionada.month}/${_dataSelecionada.year}";
    }
  }

  double get _totalCalorias => _resumo?.totalCalorias ?? 0;
  double get _totalCarbs    => _resumo?.totalCarbs    ?? 0;
  double get _totalProteina => _resumo?.totalProteina ?? 0;
  double get _totalGordura  => _resumo?.totalGordura  ?? 0;
  double get _totalAgua     => _resumo?.totalAgua     ?? 0;
  int    get _totalRefeicoes => _refeicoes.length;
  double get _pontuacao => ((_totalCalorias / _metaCalorias) * 100).clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        color: const Color(0xFF1B5E20),
        onRefresh: _carregarDados,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _carregando
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
                        )
                      : Column(
                          children: [
                            _buildResumoNutricional(),
                            const SizedBox(height: 10),
                            _buildMacros(),
                            const SizedBox(height: 15),
                            _buildEstatisticas(),
                          ],
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildCabecalhoRefeicoes(),
                    if (!_carregando && _refeicoes.isEmpty)
                      _buildEstadoVazio()
                    else
                      ..._refeicoes.map((r) => _buildMealCard(r)),
                    const SizedBox(height: 20),
                    _buildBotaoAdicionar(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DO HEADER ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 50),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Como está sua\nalimentação hoje?',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search, color: Colors.white, size: 26),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white24,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _selecionarData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_dataFormatada, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE RESUMO ---
  Widget _buildResumoNutricional() {
    final prog = (_totalCalorias / _metaCalorias).clamp(0.0, 1.0);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo Nutricional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Meta diária: ${NumberFormat('#,###', 'pt_BR').format(_metaCalorias.round())} kcal',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  NumberFormat('#,###', 'pt_BR').format(_totalCalorias.round()),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(width: 5),
                const Text('kcal', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const Spacer(),
                Text(
                  'Restam ${NumberFormat('#,###', 'pt_BR').format((_metaCalorias - _totalCalorias).clamp(0, _metaCalorias).round())} kcal',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: prog,
              backgroundColor: const Color(0xFFE0E0E0),
              color: prog >= 1.0 ? Colors.red : const Color(0xFF4CAF50),
              minHeight: 8,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacros() {
    return Row(
      children: [
        Expanded(child: _buildMacroCard('Carbs', '${_totalCarbs.round()}g', Colors.blue, (_totalCarbs / _metaCarbs).clamp(0.0, 1.0))),
        const SizedBox(width: 10),
        Expanded(child: _buildMacroCard('Proteína', '${_totalProteina.round()}g', Colors.orange, (_totalProteina / _metaProteina).clamp(0.0, 1.0))),
        const SizedBox(width: 10),
        Expanded(child: _buildMacroCard('Gordura', '${_totalGordura.round()}g', Colors.red, (_totalGordura / _metaGordura).clamp(0.0, 1.0))),
      ],
    );
  }

  Widget _buildEstatisticas() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('${_pontuacao.round()}', 'Pontuação', Icons.star, Colors.amber)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('$_totalRefeicoes', 'Refeições', Icons.restaurant, Colors.grey)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('${_totalAgua.toStringAsFixed(1)} L', 'Água', Icons.water_drop, Colors.blue)),
      ],
    );
  }

  Widget _buildCabecalhoRefeicoes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Refeições de Hoje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton(onPressed: () {}, child: const Text('Ver todas', style: TextStyle(color: Colors.green))),
      ],
    );
  }

  Widget _buildMealCard(Refeicao r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => _editarRefeicao(r),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.restaurant, color: Colors.green[700]),
        ),
        title: Text(r.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(r.descricao ?? ''),
        trailing: Text('${r.calorias.round()} kcal', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMacroCard(String label, String value, Color color, double progress) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, color: color, backgroundColor: color.withOpacity(0.1), minHeight: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoAdicionar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _adicionarRefeicao,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text('+ Adicionar Refeição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEstadoVazio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Nenhuma refeição registrada', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
