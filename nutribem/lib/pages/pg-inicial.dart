// Importa os widgets básicos do Flutter.
import 'package:flutter/material.dart';

// Pacote usado pra formatar datas e números (ex: "1.234" em vez de "1234").
import 'package:intl/intl.dart';

// Classe que centraliza todo o acesso ao banco de dados.
import '../database/dabase_helper.dart';

// "Molde" de uma refeição individual.
import '../models/refeicao.dart';

// "Molde" do resumo nutricional (totais somados de um dia).
import '../models/resumo_nutricional.dart';

// Página de adicionar/editar refeição, aberta quando o usuário toca no
// botão "+ Adicionar Refeição" ou em algum card existente.
import '../pages/adicionar_refeicao.dart';

// Widget "casca" da tela inicial (Home). Delega toda a lógica e estado
// pra classe _HomePageState logo abaixo.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Classe que guarda o estado da Home: quais dados estão carregados, se
// está carregando, qual data está sendo visualizada, etc.
class _HomePageState extends State<HomePage> {

  // Atalho pra instância única do banco de dados.
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Qual dia está sendo exibido na tela. Começa sempre em hoje.
  DateTime _dataSelecionada = DateTime.now();

  // Totais nutricionais do dia selecionado (soma de todas as refeições).
  // Começa nulo até o primeiro carregamento terminar.
  ResumoNutricional? _resumo;

  // Lista de refeições cadastradas no dia selecionado.
  List<Refeicao> _refeicoes = [];

  // Controla se mostra o "spinner" de carregando ou já tem dados prontos.
  bool _carregando = true;

  // ── Metas diárias ────────────────────────────────────────────────────────
  // Valores fixos usados como referência pra calcular as barrinhas de
  // progresso (quanto falta pra bater a meta do dia). "static const"
  // significa que são compartilhados por todas as instâncias da classe
  // e nunca mudam durante a execução.
  static const double _metaCalorias = 2000;
  static const double _metaCarbs = 250;
  static const double _metaProteina = 120;
  static const double _metaGordura = 65;
  static const double _metaAgua = 2.0;

  // Chamado automaticamente uma vez, quando a tela é criada.
  @override
  void initState() {
    super.initState();
    // Já busca os dados de hoje assim que a Home abre.
    _carregarDados();
  }

  // Busca no banco as refeições e o resumo nutricional do dia selecionado.
  Future<void> _carregarDados() async {
    // "mounted" indica se essa tela ainda está "viva" na árvore de
    // widgets. Evita chamar setState numa tela que já foi fechada
    // (o que causaria um erro).
    if (!mounted) return;

    // Liga o spinner e manda redesenhar mostrando ele.
    setState(() => _carregando = true);

    try {
      // Converte a data selecionada pro formato usado no banco
      // (ex: "2026-07-12").
      final dataStr = DateFormat('yyyy-MM-dd').format(_dataSelecionada);

      // Busca a lista de refeições daquele dia...
      final refeicoes = await _db.getRefeicoesPorData(dataStr);
      // ...e os totais nutricionais somados daquele mesmo dia.
      final resumo = await _db.getResumoNutricional(dataStr);

      // Só atualiza a tela se ela ainda estiver "viva" (checagem dupla,
      // já que essas buscas são assíncronas e a tela pode ter fechado
      // enquanto elas rodavam).
      if (mounted) {
        setState(() {
          _refeicoes = refeicoes;
          _resumo = resumo;
          _carregando = false;
        });
      }
    } catch (e) {
      // Se der qualquer erro (ex: banco não abriu direito), mostra no
      // console pra facilitar debug, mas não deixa a tela travada
      // girando o spinner pra sempre.
      debugPrint("Erro ao carregar dados na Home: $e");
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  // Abre o seletor de data nativo, pra o usuário escolher ver outro dia
  // além de hoje.
  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada, // começa mostrando o dia atualmente selecionado
      firstDate: DateTime(2024),     // não deixa escolher datas antes de 2024
      lastDate: DateTime.now(),      // não deixa escolher datas futuras
      // Personaliza a cor do calendário pra combinar com o app (verde).
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
        ),
        child: child!,
      ),
    );

    // Se o usuário escolheu uma data (não cancelou) e ela é diferente
    // da que já estava selecionada...
    if (picked != null && picked != _dataSelecionada) {
      // ...atualiza a data selecionada e busca os dados desse novo dia.
      setState(() => _dataSelecionada = picked);
      _carregarDados();
    }
  }

  // Abre a página de adicionar refeição (sem passar nenhuma refeição
  // existente, então ela abre em modo "criar nova").
  Future<void> _adicionarRefeicao() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdicionarRefeicaoPage()),
    );
    // Se a página sinalizou que algo foi salvo, recarrega a Home pra
    // mostrar a refeição nova na lista.
    if (resultado == true) _carregarDados();
  }

  // Abre a página de adicionar refeição, mas em modo "editar", passando
  // a refeição que deve ser alterada.
  Future<void> _editarRefeicao(Refeicao refeicao) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdicionarRefeicaoPage(refeicaoParaEditar: refeicao),
      ),
    );
    if (resultado == true) _carregarDados();
  }

  // Mostra um popup de confirmação e, se aceito, apaga a refeição.
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
      // "!" aqui assume que o id nunca é nulo numa refeição já salva no
      // banco (só é nulo antes de ser inserida pela primeira vez).
      await _db.deleteRefeicao(refeicao.id!);
      _carregarDados();
    }
  }

  // ── Getter que formata a data selecionada pra exibir no cabeçalho ──────────
  // Mostra "Hoje"/"Ontem" de forma amigável, ou a data por extenso pros
  // demais dias (ex: "Sex, 10 Jul 2026").
  String get _dataFormatada {
    try {
      final hoje = DateTime.now();
      // Zera hora/minuto/segundo pra comparar só o "dia" em si.
      final h = DateTime(hoje.year, hoje.month, hoje.day);
      final s = DateTime(_dataSelecionada.year, _dataSelecionada.month, _dataSelecionada.day);

      if (s == h) return DateFormat("EEE, d MMM yyyy", 'pt_BR').format(_dataSelecionada);

      if (s == h.subtract(const Duration(days: 1))) {
        return 'Ontem, ${DateFormat("d MMM", 'pt_BR').format(_dataSelecionada)}';
      }

      // Qualquer outro dia: mostra a data completa por extenso.
      return DateFormat("EEE, d MMM yyyy", 'pt_BR').format(_dataSelecionada);
    } catch (e) {
      // Se a formatação por algum motivo falhar (ex: problema com o
      // pacote de localização "pt_BR"), cai num formato bem simples
      // "dia/mês/ano" que sempre funciona, pra nunca quebrar a tela.
      return "${_dataSelecionada.day}/${_dataSelecionada.month}/${_dataSelecionada.year}";
    }
  }

  // ── Getters de conveniência pros totais do resumo ───────────────────────────
  // Cada um devolve o valor somado do dia, ou 0 se o resumo ainda não
  // foi carregado (evita erro de "usar null" espalhado pela tela toda).
  double get _totalCalorias => _resumo?.totalCalorias ?? 0;
  double get _totalCarbs    => _resumo?.totalCarbs    ?? 0;
  double get _totalProteina => _resumo?.totalProteina ?? 0;
  double get _totalGordura  => _resumo?.totalGordura  ?? 0;
  double get _totalAgua     => _resumo?.totalAgua     ?? 0;

  // Quantidade de refeições cadastradas no dia.
  int get _totalRefeicoes => _refeicoes.length;

  // "Pontuação" do dia: percentual de quanto da meta de calorias já foi
  // atingido, limitado entre 0 e 100 (clamp evita passar de 100%).
  double get _pontuacao => ((_totalCalorias / _metaCalorias) * 100).clamp(0, 100);

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        // Permite "puxar pra baixo" pra recarregar os dados manualmente.
        color: const Color(0xFF1B5E20),
        onRefresh: _carregarDados,
        child: SingleChildScrollView(
          // Mantém o gesto de "puxar pra atualizar" funcionando mesmo
          // quando o conteúdo é curto e não enche a tela.
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Cabeçalho verde com saudação, busca e seletor de data.
              _buildHeader(),

              // Transform.translate "puxa" esse bloco pra cima, fazendo
              // o card de resumo se sobrepor à parte de baixo do
              // cabeçalho verde (efeito visual de "cartão flutuante").
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

              // Lista de refeições do dia, com cabeçalho e botão de
              // adicionar logo abaixo.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildCabecalhoRefeicoes(),

                    // Mostra mensagem de "vazio" só se já terminou de
                    // carregar E não tem nenhuma refeição; senão, lista
                    // os cards de cada refeição encontrada.
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
  // Cabeçalho verde no topo da tela, com cantos arredondados embaixo,
  // saudação, botão de busca e o seletor de data.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      // Padding maior em cima (60) pra dar espaço da barra de status do
      // celular, e maior embaixo (50) pro efeito de sobreposição do card.
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
              // Botão de busca — ainda sem ação (onPressed vazio),
              // provavelmente um recurso planejado pra depois.
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

          // "Pílula" clicável mostrando a data atual — toca pra abrir
          // o seletor de data.
          GestureDetector(
            onTap: _selecionarData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min, // ocupa só o espaço necessário, não a linha toda
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
  // Card grande mostrando o total de calorias do dia, a meta, e uma
  // barra de progresso visual.
  Widget _buildResumoNutricional() {
    // Calcula o progresso (0.0 a 1.0) em relação à meta de calorias,
    // travando em 1.0 no máximo pra barra nunca "estourar" visualmente.
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

            // NumberFormat('#,###', 'pt_BR') formata o número com separador
            // de milhar no padrão brasileiro (ex: 2.000 em vez de 2000).
            Text('Meta diária: ${NumberFormat('#,###', 'pt_BR').format(_metaCalorias.round())} kcal',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),

            const SizedBox(height: 15),
            Row(
              // Alinha os textos pela linha de base (baseline), fazendo
              // "kcal" (menor) ficar alinhado com a base do número grande,
              // em vez de centralizado com ele.
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  NumberFormat('#,###', 'pt_BR').format(_totalCalorias.round()),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(width: 5),
                const Text('kcal', style: TextStyle(color: Colors.grey, fontSize: 16)),

                // Spacer empurra o texto seguinte pro canto direito,
                // preenchendo todo o espaço vazio no meio da Row.
                const Spacer(),

                Text(
                  // Calcula quanto ainda falta pra bater a meta,
                  // nunca deixando esse valor ficar negativo (clamp).
                  'Restam ${NumberFormat('#,###', 'pt_BR').format((_metaCalorias - _totalCalorias).clamp(0, _metaCalorias).round())} kcal',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Barra de progresso: fica vermelha se passou da meta
            // (prog >= 1.0), verde enquanto ainda não bateu.
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

  // Linha com os 3 cards de macronutrientes (carboidrato, proteína,
  // gordura), cada um ocupando um terço igual da largura (Expanded).
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

  // Linha com os 3 cards de estatísticas gerais: pontuação, número de
  // refeições e total de água bebida.
  Widget _buildEstatisticas() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('${_pontuacao.round()}', 'Pontuação', Icons.star, Colors.amber)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('$_totalRefeicoes', 'Refeições', Icons.restaurant, Colors.grey)),
        const SizedBox(width: 10),
        // toStringAsFixed(1) mostra sempre 1 casa decimal (ex: "1.5 L").
        Expanded(child: _buildStatCard('${_totalAgua.toStringAsFixed(1)} L', 'Água', Icons.water_drop, Colors.blue)),
      ],
    );
  }

  // Título "Refeições de Hoje" + botão "Ver todas" (ainda sem ação
  // definida — provavelmente deveria navegar pro Histórico).
  Widget _buildCabecalhoRefeicoes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Refeições de Hoje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton(onPressed: () {}, child: const Text('Ver todas', style: TextStyle(color: Colors.green))),
      ],
    );
  }

  // Card de uma refeição na lista da Home (mais simples que o card do
  // Histórico — usa ListTile pronto em vez de montar tudo manualmente).
  Widget _buildMealCard(Refeicao r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        // Tocar no card inteiro já abre a edição dessa refeição.
        onTap: () => _editarRefeicao(r),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.restaurant, color: Colors.green[700]),
        ),
        title: Text(r.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        // "??" garante que nunca tenta mostrar "null" como texto, caso
        // a descrição não tenha sido preenchida.
        subtitle: Text(r.descricao ?? ''),
        trailing: Text('${r.calorias.round()} kcal', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Card pequeno de um macronutriente: nome, valor e barrinha de
  // progresso colorida.
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

  // Card pequeno de uma estatística genérica: ícone, valor grande e
  // rótulo pequeno embaixo. Reaproveitado pra pontuação, refeições e água.
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

  // Botão verde grande no final da lista, que abre a tela de adicionar
  // uma nova refeição.
  Widget _buildBotaoAdicionar() {
    return SizedBox(
      width: double.infinity, // ocupa toda a largura disponível
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

  // Mensagem exibida quando o dia selecionado não tem nenhuma refeição
  // cadastrada ainda.
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