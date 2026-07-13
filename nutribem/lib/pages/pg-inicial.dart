import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dabase_helper.dart';
import '../models/refeicao.dart';
import '../models/resumo_nutricional.dart';
import '../pages/adicionar_refeicao.dart';

/// PÁGINA HOME (ESTADO INICIAL DO APP)
/// O 'StatefulWidget' é usado porque esta tela precisa se redesenhar 
/// sempre que os dados mudam (ex: quando você adiciona uma refeição).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Instância do banco de dados (usando o padrão Singleton para ter uma conexão única).
  final DatabaseHelper _db = DatabaseHelper.instance;

  // VARIÁVEIS DE ESTADO
  DateTime _dataSelecionada = DateTime.now(); // Controla o dia exibido (padrão: hoje).
  ResumoNutricional? _resumo;                // Objeto que contém a soma de calorias e macros.
  List<Refeicao> _refeicoes = [];            // Lista dinâmica das refeições cadastradas.
  bool _carregando = true;                   // Controla a exibição do indicador de progresso.

  // METAS DIÁRIAS (Constantes usadas para os cálculos de progresso).
  static const double _metaCalorias = 2000;
  static const double _metaCarbs = 250;
  static const double _metaProteina = 120;
  static const double _metaGordura = 65;
  static const double _metaAgua = 2000;

  /// CICLO DE VIDA: 'initState' é o primeiro método executado quando a tela nasce.
  @override
  void initState() {
    super.initState();//o super é usado para acessar a classe pai que é aquela hamepagestate
    _carregarDados(); // Busca os dados no banco assim que abre o app.
  }

  /// BUSCA DE DADOS NO BANCO (SQLite)
  /// Usamos 'async' porque a leitura de arquivos/banco é demorada e não pode travar a UI.
  Future<void> _carregarDados() async { //cria o metodo carregardados que n retorna nada só executa a bysca dos dados
    if (!mounted) return; // usa o mounted pra ver se a tela ainda está aberta Segurança: evita atualizar a tela se o usuário já saiu dela.
    setState(() => _carregando = true); // Inicia a animação de carregamento.
    
    try {
      // Formata a data para String (YYYY-MM-DD) para filtrar no SQL.
      final dataStr = DateFormat('yyyy-MM-dd').format(_dataSelecionada);
      
      // 'await' espera a resposta do banco antes de continuar.
      final refeicoes = await _db.getRefeicoesPorData(dataStr);//final pq o valor só é definido uma vez
      final resumo = await _db.getResumoNutricional(dataStr);//esse get é um metodo que recebe uma data e procura todas as coisas salvas nela
      // e no final retorna o objeto reumo nutricional e o await é pq o banco demora p responder
      
      if (mounted) {//se a pagina estgiver aberta
        setState(() {//informa que os dados da tela mjudaram
          _refeicoes = refeicoes;//atualiza refeições e resujmos
          _resumo = resumo;
          _carregando = false; // Para a animação de carregamento.
        });
      }
    } catch (e) {//o catch "pega" qualquer erro que aconteceu n o carregamento dos dados
      debugPrint("Erro ao carregar dados na Home: $e");
      if (mounted) {
        setState(() => _carregando = false);//mesmo se ocorrer erro, o carregamento é encerrado
      }
    }
  }

  /// SELETOR DE DATA (Calendário)
  Future<void> _selecionarData() async {
    final picked = await showDatePicker(//abre o calendario e quando o usuario escolhe uma data ela fica armazenada em picked
      context: context,//informa em qual tela o calendario tem q exibir
      initialDate: _dataSelecionada,
      firstDate: DateTime(2024),//a primeira data que o usuario pode selecionar
      lastDate: DateTime.now(), // Não permite selecionar datas futuras.
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
        ),
        child: child!,
      ),
    );
    // Se o usuário escolheu uma data e ela é diferente da atual, recarrega tudo.
    if (picked != null && picked != _dataSelecionada) {//verifica se o usuario escolheu uma data e se ela é diferente da atual
      setState(() => _dataSelecionada = picked);///atualiza a data da tela
      _carregarDados();//busca dnv as refeicoes e o resumo  nutricional daquela data
    }
  }

  /// NAVEGAÇÃO: Ir para a tela de adicionar refeição.
  Future<void> _adicionarRefeicao() async {
    // Navigator.push abre a nova tela e o '.then' ou 'await' espera o retorno.
    final resultado = await Navigator.push<bool>(//o bool retorna um valorr booleano
      context,
      MaterialPageRoute(builder: (_) => const AdicionarRefeicaoPage()),
    );
    // Se a tela de adicionar retornar 'true', significa que algo foi salvo.
    if (resultado == true) _carregarDados();
  }

  /// EDIÇÃO: Abre a tela de cadastro preenchida com os dados da refeição selecionada.
  Future<void> _editarRefeicao(Refeicao refeicao) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdicionarRefeicaoPage(refeicaoParaEditar: refeicao),
      ),
    );
    if (resultado == true) _carregarDados();
  }

  /// EXCLUSÃO: Diálogo de confirmação.
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

  /// LÓGICA DE FORMATAÇÃO DE DATA
  /// Retorna "Ontem", "Hoje" ou a data formatada em português.
  String get _dataFormatada {//o get cria um getter que é um metodo que pode ser usado como variavel
  //o getter retorna a data de um jeito mais bonitinho(frufru)
    try {//tenta executar um código e se der erro o catch é executado
      final hoje = DateTime.now();
      final h = DateTime(hoje.year, hoje.month, hoje.day);//cria uma nova data contendo apenas ano mes e dia
      final s = DateTime(_dataSelecionada.year, _dataSelecionada.month, _dataSelecionada.day);//faz a mesma coisa mas com a data que o usuario escolheu
      //a data selecionada é hj? se for retorna a data naquele formato ali
      if (s == h) return DateFormat("EEE, d MMM yyyy", 'pt_BR').format(_dataSelecionada);
      //o subtracté um metodo do datetime que subtrai um periodo de tempo
      // de uma data, ele faz isso pra aparecer o dia de ontem
      if (s == h.subtract(const Duration(days: 1))) {
        return 'Ontem, ${DateFormat("d MMM", 'pt_BR').format(_dataSelecionada)}';
      }
      //se n é hoje nem ontem retorna apenas a data normal
      return DateFormat("EEE, d MMM yyyy", 'pt_BR').format(_dataSelecionada);
    } catch (e) {//se der algum erro retorna apenas a data num formato simples
      return "${_dataSelecionada.day}/${_dataSelecionada.month}/${_dataSelecionada.year}";
    }
  }

  // GETTERS: Facilitam o acesso aos dados do resumo nutricional.
  //metodo getter que retorna um valor e o double retorna um numero decimal, no caso o total de calorias
  double get _totalCalorias => _resumo?.totalCalorias ?? 0;
  double get _totalCarbs    => _resumo?.totalCarbs    ?? 0;
  double get _totalProteina => _resumo?.totalProteina ?? 0;
  double get _totalGordura  => _resumo?.totalGordura  ?? 0;
  double get _totalAgua     => _resumo?.totalAgua     ?? 0;
  int    get _totalRefeicoes => _refeicoes.length;
  // Calcula a pontuação baseada na meta de calorias (máximo 100%).
  double get _pontuacao => ((_totalCalorias / _metaCalorias) * 100).clamp(0, 100);

  /// MÉTODO BUILD: Constrói a interface visual da tela.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // RefreshIndicator: Permite puxar a tela para baixo para atualizar os dados.
      body: RefreshIndicator(
        color: const Color(0xFF1B5E20),

        onRefresh: _carregarDados,
        child: SingleChildScrollView(//permite que toda a tela seja rolada para cima
        // e para baixo quando o conteudo é maior que o espaço disponivel
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(), // Cabeçalho verde.
              
              // Transform.translate move os cards para cima do cabeçalho.
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
                            _buildResumoNutricional(), // Card principal.
                            const SizedBox(height: 10),
                            _buildMacros(),            // Barras de Carb, Prot e Gordura.
                            const SizedBox(height: 15),
                            _buildEstatisticas(),      // Estrelas e Água.
                          ],
                        ),
                ),
              ),
              
              // Seção de listagem de refeições.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildCabecalhoRefeicoes(),
                    if (!_carregando && _refeicoes.isEmpty)
                      _buildEstadoVazio()
                    else
                      ..._refeicoes.map((r) => _buildMealCard(r)), // Cria um card para cada refeição.
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

  // --- WIDGETS DO HEADER (TOPO VERDE) ---
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
          // Botão de seleção de data (Calendário).
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

  // --- WIDGETS DE RESUMO (CARD PRINCIPAL) ---
  Widget _buildResumoNutricional() {
    // Calcula o valor da barra de progresso (de 0.0 a 1.0).
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
            // Barra de progresso visual.
            LinearProgressIndicator(
              value: prog,
              backgroundColor: const Color(0xFFE0E0E0),
              color: prog >= 1.0 ? Colors.red : const Color(0xFF4CAF50), // Fica vermelho se bater a meta.
              minHeight: 8,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
          ],
        ),
      ),
    );
  }

  // Linha com os três cards de macronutrientes.
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

  // Linha com pontuação, contador de refeições e água.
  Widget _buildEstatisticas() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('${_pontuacao.round()}', 'Pontuação', Icons.star, Colors.amber)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('$_totalRefeicoes', 'Refeições', Icons.restaurant, Colors.grey)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('${_totalAgua.toStringAsFixed(1)} ml', 'Água', Icons.water_drop, Colors.blue)),
      ],
    );
  }

  // Cabeçalho da lista de refeições.
  Widget _buildCabecalhoRefeicoes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Refeições de Hoje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton(onPressed: () {}, child: const Text('Ver todas', style: TextStyle(color: Colors.green))),
      ],
    );
  }

  // Card individual de cada refeição na lista.
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
        subtitle: Text(r.descricao ?? 'Sem descrição'),
        trailing: Text('${r.calorias.round()} kcal', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Widget exibido quando não há refeições cadastradas.
  Widget _buildEstadoVazio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Nenhuma refeição registrada hoje.', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  // Widget reutilizável para os cards de macros (Carb/Prot/Gord).
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

  // Widget reutilizável para os cards de estatísticas (Estrela/Água).
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

  // Botão grande na parte inferior para adicionar nova refeição.
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
}
