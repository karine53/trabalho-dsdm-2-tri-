// Importa os widgets básicos do Flutter (Scaffold, Text, Column, etc).
import 'package:flutter/material.dart';

// Importa o pacote intl, usado aqui pra formatar datas (ex: transformar
// "2026-07-12" em "Terça-feira, 12 de Julho").
import 'package:intl/intl.dart';

// Importa a classe que centraliza todo o acesso ao banco de dados.
import '../database/dabase_helper.dart';

// Importa o "molde" de uma refeição (nome, calorias, data, etc).
import '../models/refeicao.dart';

// Importa a página de adicionar/editar refeição, usada aqui quando o
// usuário toca em "editar" num card do histórico.
import '../pages/adicionar_refeicao.dart';

// Enum (lista fixa de opções) que representa os filtros de período
// mostrados como "chips" no topo da tela: Hoje / Ontem / Esta semana / Este mês.
// Usar um enum em vez de String evita erros de digitação e deixa o
// código mais seguro (o compilador garante que só esses 4 valores existem).
enum _FiltroPeriodo { hoje, ontem, semana, mes }

// Widget "casca" da página de Histórico. Como StatefulWidget, ele delega
// toda a lógica e estado pra classe _HistoricoPageState logo abaixo.
class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

// Classe que guarda o estado da tela (os dados que podem mudar e fazem
// a tela se redesenhar) e toda a lógica de carregar/filtrar/exibir.
class _HistoricoPageState extends State<HistoricoPage> {

  // Atalho pra instância única do banco de dados (evita repetir
  // "DatabaseHelper.instance" toda vez).
  //aqui a tela consegue consultar, adicionar ou remover informacoes sem precisar criar outra conexao
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Controller (controlador) do campo de texto de pesquisa. Ele é quem
  // guarda o que o usuário está digitando e permite "escutar" mudanças.
  final TextEditingController _pesquisaController = TextEditingController();

  // Qual filtro de período está selecionado no momento. Começa em "hoje", mas pode ser ontem semana mes
  _FiltroPeriodo _filtroSelecionado = _FiltroPeriodo.hoje;

  // Texto atualmente digitado na busca (guardado separado do controller
  // pra facilitar comparações, ex: saber se está vazio).
  String _termoPesquisa = '';

  // Lista de refeições carregadas do banco, já filtradas, prontas pra
  // serem exibidas na tela.
  List<Refeicao> _refeicoes = [];

  // Controla se está mostrando o "spinner" de carregando ou já tem dados.
  bool _carregando = true;

  // Chamado automaticamente UMA VEZ, assim que essa tela é criada.
  @override
  void initState() {
    super.initState();

    // Já busca os dados assim que a tela abre (com o filtro padrão "hoje").
    _carregarDados();

    // Registra uma função pra ser chamada toda vez que o texto de
    // pesquisa mudar (usuário digitando).
    //é um controle da pesquisa, sempre que o usuario digita ou apaga o metodo _onpesquisaalterada é chamadp
    _pesquisaController.addListener(_onPesquisaAlterada);
  }

  // Chamado automaticamente quando essa tela é destruída (usuário saiu
  // dela). Serve pra "limpar a bagunça" e evitar vazamento de memória.
  @override
  void dispose() {//o dispose é chamado quando a tela é fechada, serve pra liberar recursos
  //q n serao mais usados
    // Remove a "escuta" de mudanças de texto antes de destruir o controller.
    _pesquisaController.removeListener(_onPesquisaAlterada);//remove o listener do campo de pesquisa

    // Libera os recursos internos do controller.
    _pesquisaController.dispose();

    super.dispose();
  }

  // Chamada toda vez que o texto do campo de pesquisa muda.
  void _onPesquisaAlterada() {
    // Atualiza o termo de pesquisa guardado (removendo espaços extras
    // no início/fim com trim()) e manda a tela se redesenhar.
    setState(() => _termoPesquisa = _pesquisaController.text.trim());//trim remove espaço no inicio e fim do textp

    // Busca de novo no banco já considerando o novo termo digitado.
    _carregarDados();
  }

  // ── Calcula intervalo [inicio, fim] (formato yyyy-MM-dd) para o filtro ──────
  // Devolve uma "tupla" (par de valores) com a data de início e fim do
  // período selecionado, já formatadas como String no padrão do banco.
  (String, String) _intervaloDoFiltro() {//quer dizer q o intervalo desse filtro é da datainicial ate a final

    // Pega a data/hora atual...
    final hoje = DateTime.now();

    // ...e zera a hora/minuto/segundo, deixando só o "dia" (meia-noite),
    // pra comparações de data ficarem exatas, sem interferência do horário.
    final hojeData = DateTime(hoje.year, hoje.month, hoje.day);

    // Decide o intervalo de acordo com qual filtro está selecionado.
    switch (_filtroSelecionado) {//o switch é varios if e else e ele verifica o valor de _filtro selecionado
    //que pode ser hoje, ontem semana e mes

      case _FiltroPeriodo.hoje:
        // Início e fim são o mesmo dia: hoje.
        final s = DateFormat('yyyy-MM-dd').format(hojeData);
        return (s, s);

      case _FiltroPeriodo.ontem:
        // Subtrai 1 dia de hoje pra achar a data de ontem.
        final ontem = hojeData.subtract(const Duration(days: 1));
        final s = DateFormat('yyyy-MM-dd').format(ontem);
        return (s, s);

      case _FiltroPeriodo.semana:
        // Semana atual: de segunda-feira até hoje.
        // "weekday" devolve 1 pra segunda, 2 pra terça... 7 pra domingo.
        // Subtraindo (weekday - 1) dias de hoje, chega na segunda-feira
        // dessa mesma semana.
        final inicioSemana =
            hojeData.subtract(Duration(days: hojeData.weekday - 1));
        return (
          DateFormat('yyyy-MM-dd').format(inicioSemana),
          DateFormat('yyyy-MM-dd').format(hojeData),
        );

      case _FiltroPeriodo.mes:
        // Início do mês atual é sempre o dia 1.
        final inicioMes = DateTime(hojeData.year, hojeData.month, 1);
        return (
          DateFormat('yyyy-MM-dd').format(inicioMes),
          DateFormat('yyyy-MM-dd').format(hojeData),
        );
    }
  }

  // ── Busca refeições no banco respeitando filtro de período + pesquisa ──────
  Future<void> _carregarDados() async {

    // Liga o "spinner" de carregando e manda redesenhar a tela mostrando ele.
    setState(() => _carregando = true);

    try {
      // Pega o intervalo de datas correspondente ao filtro selecionado.
      final (inicio, fim) = _intervaloDoFiltro();

      // Variável que vai guardar o resultado da busca, seja qual caminho
      // for seguido abaixo.
      List<Refeicao> resultado;

      // Se o usuário digitou alguma coisa na pesquisa...
      if (_termoPesquisa.isNotEmpty) {
        // ...busca por nome/descrição, mas ainda restrito ao intervalo
        // de datas do filtro selecionado.
        resultado = await _db.buscarRefeicoes(
          _termoPesquisa,
          dataInicio: inicio,
          dataFim: fim,
        );
      } else if (_filtroSelecionado == _FiltroPeriodo.hoje ||
          _filtroSelecionado == _FiltroPeriodo.ontem) {
        // Sem pesquisa e filtro é um único dia (hoje ou ontem): busca
        // direto por aquela data específica (mais simples/rápido).
        resultado = await _db.getRefeicoesPorData(inicio);
      } else {
        // Sem pesquisa e filtro é um intervalo (semana ou mês): busca
        // tudo dentro desse intervalo de datas.
        resultado = await _db.getRefeicoesPorIntervalo(inicio, fim);
      }

      // Guarda o resultado encontrado e desliga o "spinner", mandando a
      // tela se redesenhar já com os dados novos.
      setState(() {
        _refeicoes = resultado;
        _carregando = false;
      });
    } catch (e) {
      // Se der erro na busca, pelo menos desliga o spinner (evita ficar
      // girando pra sempre), mesmo sem mostrar o erro na tela.
      setState(() => _carregando = false);
    }
  }

  // Chamada quando o usuário toca num dos chips de filtro (Hoje/Ontem/etc).
  void _selecionarFiltro(_FiltroPeriodo filtro) {
    // Atualiza qual filtro está marcado e redesenha a tela.
    setState(() => _filtroSelecionado = filtro);

    // Busca de novo no banco já com o filtro novo.
    _carregarDados();
  }

  // ── Navega para edição e recarrega ao voltar ────────────────────────────────
  Future<void> _editarRefeicao(Refeicao refeicao) async {

    // Abre a página de Adicionar/Editar Refeição, passando a refeição
    // que deve ser editada. "Navigator.push" empilha essa nova tela por
    // cima da atual, e "await" pausa aqui até o usuário voltar dela.
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdicionarRefeicaoPage(refeicaoParaEditar: refeicao),
      ),
    );

    // Se a página de edição sinalizou que algo foi salvo (devolveu
    // "true" ao fechar), recarrega a lista pra mostrar a mudança.
    if (resultado == true) _carregarDados();
  }

  // ── Confirma e exclui refeição ──────────────────────────────────────────────
  Future<void> _excluirRefeicao(Refeicao refeicao) async {

    // Mostra um popup de confirmação antes de excluir de verdade, pra
    // evitar exclusão acidental.
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir refeição'),
        content: Text('Deseja excluir "${refeicao.nome}"?'),
        actions: [
          // Botão "Cancelar": fecha o popup devolvendo "false".
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          // Botão "Excluir": fecha o popup devolvendo "true", em vermelho
          // pra sinalizar que é uma ação destrutiva.
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    // Só executa a exclusão de verdade se o usuário confirmou (true) E
    // a refeição realmente tem um id válido (não é nulo).
    if (confirmar == true && refeicao.id != null) {
      await _db.deleteRefeicao(refeicao.id!);
      // Recarrega a lista pra remover o card da tela.
      _carregarDados();
    }
  }

  // ── Agrupa as refeições carregadas por data (yyyy-MM-dd) ────────────────────
  // "Getter" (propriedade calculada): toda vez que _refeicoesAgrupadas é
  // acessado, esse código roda e devolve o resultado na hora.
  Map<String, List<Refeicao>> get _refeicoesAgrupadas {
    // Mapa onde a chave é a data (ex: "2026-07-12") e o valor é a lista
    // de refeições daquele dia.
    final mapa = <String, List<Refeicao>>{};

    // Percorre cada refeição carregada...
    for (final r in _refeicoes) {
      // putIfAbsent: se ainda não existe uma lista pra essa data, cria
      // uma vazia; depois adiciona essa refeição nela.
      mapa.putIfAbsent(r.data, () => []).add(r);
    }
    return mapa;
  }

  // ── Formata o cabeçalho de cada grupo de data (ex: "Terça-feira, 10 Junho") ─
  String _formatarCabecalhoData(String dataStr) {
    // Converte o texto "yyyy-MM-dd" de volta pra um objeto DateTime.
    final data = DateFormat('yyyy-MM-dd').parse(dataStr);

    final hoje = DateTime.now();
    final hojeData = DateTime(hoje.year, hoje.month, hoje.day);
    final ontem = hojeData.subtract(const Duration(days: 1));

    // Casos especiais: mostra "Hoje" ou "Ontem" em vez da data completa,
    // pra ficar mais natural de ler.
    if (data == hojeData) return 'Hoje';
    if (data == ontem) return 'Ontem';

    // Pra qualquer outra data, formata por extenso em português, tipo
    // "terça-feira, 10 de Junho".
    final formatado = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(data);

    // Deixa a primeira letra maiúscula ("terça-feira" → "Terça-feira"),
    // já que o pacote intl devolve em minúsculo por padrão.
    return formatado[0].toUpperCase() + formatado.substring(1);
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  // Função que desenha a tela inteira. É chamada toda vez que algo muda
  // (setState) e a interface precisa ser atualizada.
  @override
  Widget build(BuildContext context) {

    // Pega as datas (chaves do mapa agrupado) e ordena da mais recente
    // pra mais antiga, pra mostrar as refeições de hoje primeiro.
    final gruposOrdenados = _refeicoesAgrupadas.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // mais recente primeiro

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        // Column empilha os elementos verticalmente: cabeçalho, busca,
        // filtros e depois a lista (que ocupa o espaço restante).
        child: Column(
          children: [
            _buildHeader(),
            _buildBarraPesquisa(),
            _buildFiltrosPeriodo(),
            const SizedBox(height: 4),

            // Expanded faz esse widget ocupar todo o espaço vertical que
            // sobrar na tela (senão a lista não teria altura definida).
            Expanded(
              child: RefreshIndicator(
                // Permite "puxar pra baixo" na lista pra recarregar
                // manualmente os dados (gesto comum em apps de lista).
                color: const Color(0xFF1B5E20),
                onRefresh: _carregarDados,

                // Decide o que mostrar: spinner de carregando, mensagem
                // de "vazio", ou a lista de fato com os dados.
                child: _carregando
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B5E20),
                        ),
                      )
                    : (_refeicoes.isEmpty
                        ? _buildEstadoVazio()
                        : ListView.builder(
                            // Permite puxar pra atualizar mesmo quando a
                            // lista é curta e não preenche a tela toda.
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            itemCount: gruposOrdenados.length,
                            itemBuilder: (context, index) {
                              // Pra cada data agrupada, monta o bloco com
                              // cabeçalho da data + cards das refeições.
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
        // Empurra o título pra esquerda e o botão pra direita, com
        // espaço vazio entre os dois.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Título fixo da página.
          const Text(
            'Histórico',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          // Botão de engrenagem (configurações). Por enquanto não faz
          // nada — está marcado como TODO (tarefa pendente).
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
        // Conecta esse campo ao controller declarado lá em cima, pra
        // conseguir ler/escutar o que o usuário digita.
        controller: _pesquisaController,
        decoration: InputDecoration(
          // Ícone de lupa fixo do lado esquerdo do campo.
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          hintText: 'Pesquisar alimento ou refeição...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none, // sem borda visível, só o fundo cinza
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  // ── Chips de filtro: Hoje / Ontem / Esta semana / Este mês ─────────────────
  Widget _buildFiltrosPeriodo() {
    // Lista de tuplas (filtro, texto exibido) — assim não precisa
    // repetir um "switch" pra saber o rótulo de cada chip.
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
      // Permite rolar os chips horizontalmente, caso não caibam todos
      // na largura da tela (útil em celulares menores).
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          // Transforma cada tupla (filtro, label) num widget ChoiceChip.
          children: opcoes.map((opcao) {
            final filtro = opcao.$1;   // primeiro item da tupla
            final label = opcao.$2;    // segundo item da tupla
            final selecionado = _filtroSelecionado == filtro;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selecionado,
                // Quando tocado, troca o filtro selecionado (ignora o
                // valor booleano que o ChoiceChip manda, por isso "_").
                onSelected: (_) => _selecionarFiltro(filtro),
                selectedColor: const Color(0xFF1B5E20),
                backgroundColor: Colors.grey[100],
                labelStyle: TextStyle(
                  // Texto branco e em negrito quando selecionado, preto
                  // e normal quando não selecionado.
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
                // Esconde o "✓" padrão que apareceria ao lado do texto
                // quando selecionado (visual mais limpo).
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
    // Usa ListView (em vez de só um Center) mesmo estando vazio, pra
    // manter o gesto de "puxar pra atualizar" funcionando também aqui.
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
                // Mensagem muda dependendo se o usuário estava
                // pesquisando algo ou só olhando o período vazio.
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
              // Cabeçalho com a data por extenso (ex: "Terça-feira, 10 Junho").
              Text(
                _formatarCabecalhoData(dataKey),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              // Contagem de refeições daquele dia, com singular/plural
              // corretos ("1 refeição" vs "2 refeições").
              Text(
                '${refeicoesDoDia.length} ${refeicoesDoDia.length == 1 ? 'refeição' : 'refeições'}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
        // Transforma cada refeição do dia num card individual, e
        // "espalha" (...) essa lista de widgets dentro da Column.
        ...refeicoesDoDia.map((r) => _buildMealCard(r)),
      ],
    );
  }

  // ── card (todos são card): card individual de refeição ──────────────────────
  Widget _buildMealCard(Refeicao refeicao) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0, // sem sombra, visual "flat"
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)), // borda bem sutil
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            // Alinha os itens pelo topo (útil quando a descrição quebra
            // linha e fica mais alta que o ícone).
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone colorido representando o tipo da refeição
              // (café da manhã, almoço, etc).
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

              // Expanded faz essa coluna (nome/descrição/categoria)
              // ocupar todo o espaço horizontal que sobrar, empurrando
              // as calorias/horário pra ponta direita do card.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome da refeição/alimento.
                    Text(
                      refeicao.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    // Descrição só aparece se existir e não estiver vazia.
                    if (refeicao.descricao != null &&
                        refeicao.descricao!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          refeicao.descricao!,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1, // no máximo 1 linha
                          overflow: TextOverflow.ellipsis, // corta com "..." se não couber
                        ),
                      ),
                    // Chip de categoria (proteína/carboidrato/vegetal),
                    // só aparece se a refeição tiver uma categoria definida.
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

              // Coluna da direita: calorias, horário e botões de ação,
              // todos alinhados à direita (fim da linha).
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Calorias, arredondadas pro número inteiro mais próximo.
                  Text(
                    '${refeicao.calorias.round()} kcal',
                    style: const TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  // Horário só aparece se existir.
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
                  // Botões pequenos de editar e excluir, lado a lado.
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
    // Escolhe a cor do chip de acordo com a categoria (proteína, etc).
    final cor = _corPorCategoria(categoria);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // Usa a cor da categoria, mas bem clara (12% de opacidade) só
        // como fundo, deixando o texto na cor cheia por cima.
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
    required VoidCallback onTap, // função a executar quando tocado
  }) {
    // InkWell dá o efeito visual de "ondulação" ao tocar (feedback
    // tátil visual), diferente de um GestureDetector puro.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8), // a ondulação respeita esse arredondado
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
    // Compara o tipo em minúsculo, pra não depender de o texto salvo
    // estar exatamente com a mesma capitalização.
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
        // Qualquer tipo desconhecido ou nulo cai aqui, com um ícone
        // genérico de "prato" em vez de quebrar o app.
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
        // Categoria não reconhecida usa cinza neutro.
        return Colors.grey;
    }
  }
}