import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dabase_helper.dart';
import '../models/refeicao.dart';
import '../pages/adicionar_refeicao.dart';

// Filtros de período exibidos nos chips "Hoje / Ontem / Esta semana / Este mês"
enum _FiltroPeriodo { hoje, ontem, semana, mes }

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  // TextField: controller da barra de pesquisa do histórico
  final TextEditingController _pesquisaController = TextEditingController();

  _FiltroPeriodo _filtroSelecionado = _FiltroPeriodo.hoje;
  String _termoPesquisa = '';
  List<Refeicao> _refeicoes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _pesquisaController.addListener(_onPesquisaAlterada);
  }

  @override
  void dispose() {
    _pesquisaController.removeListener(_onPesquisaAlterada);
    _pesquisaController.dispose();
    super.dispose();
  }

  void _onPesquisaAlterada() {
    setState(() => _termoPesquisa = _pesquisaController.text.trim());
    _carregarDados();
  }

  // ── Calcula intervalo [inicio, fim] (formato yyyy-MM-dd) para o filtro ──────
  (String, String) _intervaloDoFiltro() {
    final hoje = DateTime.now();
    final hojeData = DateTime(hoje.year, hoje.month, hoje.day);

    switch (_filtroSelecionado) {
      case _FiltroPeriodo.hoje:
        final s = DateFormat('yyyy-MM-dd').format(hojeData);
        return (s, s);
      case _FiltroPeriodo.ontem:
        final ontem = hojeData.subtract(const Duration(days: 1));
        final s = DateFormat('yyyy-MM-dd').format(ontem);
        return (s, s);
      case _FiltroPeriodo.semana:
        // Semana atual: de segunda-feira até hoje
        final inicioSemana =
            hojeData.subtract(Duration(days: hojeData.weekday - 1));
        return (
          DateFormat('yyyy-MM-dd').format(inicioSemana),
          DateFormat('yyyy-MM-dd').format(hojeData),
        );
      case _FiltroPeriodo.mes:
        final inicioMes = DateTime(hojeData.year, hojeData.month, 1);
        return (
          DateFormat('yyyy-MM-dd').format(inicioMes),
          DateFormat('yyyy-MM-dd').format(hojeData),
        );
    }
  }

  // ── Busca refeições no banco respeitando filtro de período + pesquisa ──────
  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final (inicio, fim) = _intervaloDoFiltro();
      List<Refeicao> resultado;

      if (_termoPesquisa.isNotEmpty) {
        resultado = await _db.buscarRefeicoes(
          _termoPesquisa,
          dataInicio: inicio,
          dataFim: fim,
        );
      } else if (_filtroSelecionado == _FiltroPeriodo.hoje ||
          _filtroSelecionado == _FiltroPeriodo.ontem) {
        resultado = await _db.getRefeicoesPorData(inicio);
      } else {
        resultado = await _db.getRefeicoesPorIntervalo(inicio, fim);
      }

      setState(() {
        _refeicoes = resultado;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  void _selecionarFiltro(_FiltroPeriodo filtro) {
    setState(() => _filtroSelecionado = filtro);
    _carregarDados();
  }

  // ── Navega para edição e recarrega ao voltar ────────────────────────────────
  Future<void> _editarRefeicao(Refeicao refeicao) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdicionarRefeicaoPage(refeicaoParaEditar: refeicao),
      ),
    );
    if (resultado == true) _carregarDados();
  }

  // ── Confirma e exclui refeição ──────────────────────────────────────────────
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
    if (confirmar == true && refeicao.id != null) {
      await _db.deleteRefeicao(refeicao.id!);
      _carregarDados();
    }
  }

  // ── Agrupa as refeições carregadas por data (yyyy-MM-dd) ────────────────────
  Map<String, List<Refeicao>> get _refeicoesAgrupadas {
    final mapa = <String, List<Refeicao>>{};
    for (final r in _refeicoes) {
      mapa.putIfAbsent(r.data, () => []).add(r);
    }
    return mapa;
  }

  // ── Formata o cabeçalho de cada grupo de data (ex: "Terça-feira, 10 Junho") ─
  String _formatarCabecalhoData(String dataStr) {
    final data = DateFormat('yyyy-MM-dd').parse(dataStr);
    final hoje = DateTime.now();
    final hojeData = DateTime(hoje.year, hoje.month, hoje.day);
    final ontem = hojeData.subtract(const Duration(days: 1));

    if (data == hojeData) return 'Hoje';
    if (data == ontem) return 'Ontem';

    final formatado = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(data);
    // Capitaliza a primeira letra do dia da semana
    return formatado[0].toUpperCase() + formatado.substring(1);
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final gruposOrdenados = _refeicoesAgrupadas.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // mais recente primeiro

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildBarraPesquisa(),
            _buildFiltrosPeriodo(),
            const SizedBox(height: 4),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF1B5E20),
                onRefresh: _carregarDados,
                child: _carregando
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B5E20),
                        ),
                      )
                    : (_refeicoes.isEmpty
                        ? _buildEstadoVazio()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            itemCount: gruposOrdenados.length,
                            itemBuilder: (context, index) {
                              final dataKey = gruposOrdenados[index];
                              final refeicoesDoDia =
                                  _refeicoesAgrupadas[dataKey]!;
                              return _buildGrupoData(dataKey, refeicoesDoDia);
                            },
                          )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Container: cabeçalho branco com título e botão de configurações ────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Text: título "Histórico" conforme anotação "Text" no mockup
          const Text(
            'Histórico',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          // IconButton: engrenagem conforme anotação "iconButton" no mockup
          IconButton(
            onPressed: () { /* TODO: navegar para Configurações */ },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.settings_outlined, color: Colors.green[700]),
            ),
          ),
        ],
      ),
    );
  }

  // ── TextField: barra de pesquisa conforme anotação "textfield" no mockup ───
  Widget _buildBarraPesquisa() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: TextField(
        controller: _pesquisaController,
        decoration: InputDecoration(
          // Icon: ícone de lupa dentro do campo
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          hintText: 'Pesquisar alimento ou refeição...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  // ── Chips de filtro: Hoje / Ontem / Esta semana / Este mês ─────────────────
  Widget _buildFiltrosPeriodo() {
    final opcoes = [
      (_FiltroPeriodo.hoje, 'Hoje'),
      (_FiltroPeriodo.ontem, 'Ontem'),
      (_FiltroPeriodo.semana, 'Esta semana'),
      (_FiltroPeriodo.mes, 'Este mês'),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: opcoes.map((opcao) {
            final filtro = opcao.$1;
            final label = opcao.$2;
            final selecionado = _filtroSelecionado == filtro;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selecionado,
                onSelected: (_) => _selecionarFiltro(filtro),
                selectedColor: const Color(0xFF1B5E20),
                backgroundColor: Colors.grey[100],
                labelStyle: TextStyle(
                  color: selecionado ? Colors.white : Colors.black87,
                  fontWeight:
                      selecionado ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: selecionado
                        ? const Color(0xFF1B5E20)
                        : Colors.grey.shade300,
                  ),
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Estado vazio: nenhuma refeição encontrada no período/pesquisa ──────────
  Widget _buildEstadoVazio() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              Icon(Icons.history, size: 56, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                _termoPesquisa.isNotEmpty
                    ? 'Nenhum resultado para "$_termoPesquisa"'
                    : 'Nenhuma refeição neste período',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Cabeçalho de data + contagem de refeições + lista de cards do dia ──────
  Widget _buildGrupoData(String dataKey, List<Refeicao> refeicoesDoDia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Text: cabeçalho da data (ex: "Terça-feira, 10 Junho")
              Text(
                _formatarCabecalhoData(dataKey),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              // Text: contagem de refeições do dia
              Text(
                '${refeicoesDoDia.length} ${refeicoesDoDia.length == 1 ? 'refeição' : 'refeições'}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
        ...refeicoesDoDia.map((r) => _buildMealCard(r)),
      ],
    );
  }

  // ── card (todos são card): card individual de refeição ──────────────────────
  Widget _buildMealCard(Refeicao refeicao) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon (todos os cards tem o icon): ícone do tipo de refeição
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconePorTipo(refeicao.tipo),
                  color: Colors.green[700],
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text: nome da refeição
                    Text(
                      refeicao.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    // Text: descrição/quantidade
                    if (refeicao.descricao != null &&
                        refeicao.descricao!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          refeicao.descricao!,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // chip (todos os card tem o chip): categoria do alimento
                    if (refeicao.categoria != null &&
                        refeicao.categoria!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _buildChipCategoria(refeicao.categoria!),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text: calorias
                  Text(
                    '${refeicao.calorias.round()} kcal',
                    style: const TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  // Text: horário
                  if (refeicao.horario != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        refeicao.horario!,
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ),
                  const SizedBox(height: 6),
                  // IconButton (todos os cards tem): editar e excluir
                  Row(
                    children: [
                      _buildIconButtonAcao(
                        icone: Icons.edit_outlined,
                        cor: Colors.green[700]!,
                        fundo: Colors.green[50]!,
                        onTap: () => _editarRefeicao(refeicao),
                      ),
                      const SizedBox(width: 6),
                      _buildIconButtonAcao(
                        icone: Icons.delete_outline,
                        cor: Colors.red[400]!,
                        fundo: Colors.red[50]!,
                        onTap: () => _excluirRefeicao(refeicao),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── chip (todos os card tem o chip): categoria nutricional do alimento ─────
  Widget _buildChipCategoria(String categoria) {
    final cor = _corPorCategoria(categoria);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        categoria,
        style: TextStyle(
          color: cor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── IconButton (todos os cards tem): botão pequeno de ação (editar/excluir) ─
  Widget _buildIconButtonAcao({
    required IconData icone,
    required Color cor,
    required Color fundo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icone, size: 16, color: cor),
      ),
    );
  }

  // ── Ícone por tipo de refeição (mesmo padrão usado na Home) ────────────────
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

  // ── Cor do chip por categoria nutricional ───────────────────────────────────
  Color _corPorCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'proteína':
        return Colors.deepOrange;
      case 'carboidrato':
        return Colors.blue;
      case 'vegetal':
        return const Color(0xFF1B5E20);
      default:
        return Colors.grey;
    }
  }
}
