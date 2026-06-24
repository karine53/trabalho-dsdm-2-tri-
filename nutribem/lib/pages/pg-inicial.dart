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
  bool _verTodas = false;

  // Metas diárias (podem vir de configurações futuramente)
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

  // ── Busca refeições e resumo do dia no banco ─────────────────────────────────
  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final dataStr = DateFormat('yyyy-MM-dd').format(_dataSelecionada);

      print('BUSCANDO DATA: $dataStr');

      final refeicoes = await _db.getRefeicoesPorData(dataStr);

      print('REFEIÇÕES ENCONTRADAS: ${refeicoes.length}');

      final resumo = await _db.getResumoNutricional(dataStr);
      setState(() {
        _refeicoes = refeicoes;
        _resumo = resumo;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  // ── Abre DatePicker para trocar o dia visualizado ────────────────────────────
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

  // ── Navega para AdicionarRefeicaoPage e recarrega ao voltar ─────────────────
  Future<void> _adicionarRefeicao() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdicionarRefeicaoPage()),
    );
    if (resultado == true) _carregarDados();
  }

  // ── Navega para edição passando a refeição existente ────────────────────────
  Future<void> _editarRefeicao(Refeicao refeicao) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdicionarRefeicaoPage(refeicaoParaEditar: refeicao),
      ),
    );
    if (resultado == true) _carregarDados();
  }

  // ── Confirma e exclui refeição ───────────────────────────────────────────────
  Future<void> _excluirRefeicao(Refeicao refeicao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir refeição'),
        content: Text('Deseja excluir "${refeicao.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
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

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String get _dataFormatada {
    final hoje = DateTime.now();
    final h = DateTime(hoje.year, hoje.month, hoje.day);
    final s = DateTime(
      _dataSelecionada.year,
      _dataSelecionada.month,
      _dataSelecionada.day,
    );
    if (s == h)
      return DateFormat("EEE, d MMM yyyy", 'pt_BR').format(_dataSelecionada);
    if (s == h.subtract(const Duration(days: 1))) {
      return 'Ontem, ${DateFormat("d MMM", 'pt_BR').format(_dataSelecionada)}';
    }
    return DateFormat("EEE, d MMM yyyy", 'pt_BR').format(_dataSelecionada);
  }

  double get _totalCalorias => _resumo?.totalCalorias ?? 0;
  double get _totalCarbs => _resumo?.totalCarbs ?? 0;
  double get _totalProteina => _resumo?.totalProteina ?? 0;
  double get _totalGordura => _resumo?.totalGordura ?? 0;
  double get _totalAgua => _resumo?.totalAgua ?? 0;
  int get _totalRefeicoes => _refeicoes.length;
  double get _pontuacao =>
      ((_totalCalorias / _metaCalorias) * 100).clamp(0, 100);

  // ── BUILD ────────────────────────────────────────────────────────────────────
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
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1B5E20),
                            ),
                          ),
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
                    else ...[
                      ...(_verTodas
                              ? _refeicoes
                              : _refeicoes.take(3).toList())
                          .map((r) => _buildMealCard(r)),
                      if (!_verTodas && _refeicoes.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Center(
                            child: Text(
                              '+ ${_refeicoes.length - 3} refeição(ões) ocultada(s) — toque em "Ver todas"',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
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

  // ── Header verde ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 50),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como está sua\nalimentação hoje?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _selecionarData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _dataFormatada,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card Resumo Nutricional ───────────────────────────────────────────────────
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
            const Text(
              'Resumo Nutricional',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Meta diária: ${NumberFormat('#,###', 'pt_BR').format(_metaCalorias.round())} kcal',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  NumberFormat('#,###', 'pt_BR').format(_totalCalorias.round()),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'kcal',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
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

  // ── Row de macros ─────────────────────────────────────────────────────────────
  Widget _buildMacros() {
    return Row(
      children: [
        Expanded(
          child: _buildMacroCard(
            'Carbs',
            '${_totalCarbs.round()}g',
            Colors.blue,
            (_totalCarbs / _metaCarbs).clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMacroCard(
            'Proteína',
            '${_totalProteina.round()}g',
            Colors.orange,
            (_totalProteina / _metaProteina).clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMacroCard(
            'Gordura',
            '${_totalGordura.round()}g',
            Colors.red,
            (_totalGordura / _metaGordura).clamp(0.0, 1.0),
          ),
        ),
      ],
    );
  }

  // ── Row de estatísticas ───────────────────────────────────────────────────────
  Widget _buildEstatisticas() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '${_pontuacao.round()}',
            'Pontuação',
            Icons.star,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            '$_totalRefeicoes',
            'Refeições',
            Icons.restaurant,
            Colors.grey,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            '${_totalAgua.toStringAsFixed(1)} L',
            'Água',
            Icons.water_drop,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  // ── Cabeçalho refeições ───────────────────────────────────────────────────────
  Widget _buildCabecalhoRefeicoes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Refeições de Hoje',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        if (_refeicoes.length > 3)
          TextButton(
            onPressed: () => setState(() => _verTodas = !_verTodas),
            child: Text(
              _verTodas ? 'Ver menos' : 'Ver todas',
              style: const TextStyle(color: Colors.green),
            ),
          ),
      ],
    );
  }

  // ── Estado vazio ──────────────────────────────────────────────────────────────
  Widget _buildEstadoVazio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Nenhuma refeição registrada',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque em "+ Adicionar Refeição" para começar',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── ElevatedButton Adicionar ──────────────────────────────────────────────────
  Widget _buildBotaoAdicionar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _adicionarRefeicao,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          '+ Adicionar Refeição',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Card de macro ─────────────────────────────────────────────────────────────
  Widget _buildMacroCard(
    String label,
    String value,
    Color color,
    double progress,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 4,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card de estatística ───────────────────────────────────────────────────────
  Widget _buildStatCard(
    String value,
    String label,
    IconData iconData,
    Color iconColor,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
            Icon(iconData, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card de refeição individual ───────────────────────────────────────────────
  Widget _buildMealCard(Refeicao refeicao) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key('refeicao_${refeicao.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          await _excluirRefeicao(refeicao);
          return false;
        },
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          child: InkWell(
            onTap: () => _editarRefeicao(refeicao),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconePorTipo(refeicao.tipo),
                      color: Colors.green[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          refeicao.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (refeicao.descricao != null &&
                            refeicao.descricao!.isNotEmpty)
                          Text(
                            refeicao.descricao!,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${refeicao.calorias.round()} kcal',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (refeicao.horario != null)
                        Text(
                          refeicao.horario!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Ícone por tipo de refeição ────────────────────────────────────────────────
  IconData _iconePorTipo(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'café da manhã':
        return Icons.wb_sunny_outlined;
      case 'almoço':
        return Icons.wb_cloudy_outlined;
      case 'lanche':
        return Icons.cookie_outlined;
      case 'jantar':
        return Icons.nightlight_outlined;
      case 'ceia':
        return Icons.bedtime_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }
}