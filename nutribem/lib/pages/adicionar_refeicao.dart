import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dabase_helper.dart';
import '../models/refeicao.dart';

class AdicionarRefeicaoPage extends StatefulWidget {
  final Refeicao? refeicaoParaEditar;

  const AdicionarRefeicaoPage({
    super.key,
    this.refeicaoParaEditar,
  });

  @override
  State<AdicionarRefeicaoPage> createState() => _AdicionarRefeicaoPageState();
}


class _AdicionarRefeicaoPageState extends State<AdicionarRefeicaoPage> {
  // ── Controllers dos TextFields ───────────────────────────────────────────────
  // TextField: Nome do alimento (barra de pesquisa com ícone de lupa)
  final TextEditingController _nomeController = TextEditingController();
  // TextField: Quantidade (ex: 200g ou 1 porção)
  final TextEditingController _quantidadeController = TextEditingController();
  // TextField: Calorias
  final TextEditingController _caloriasController = TextEditingController();
  // TextField: Carboidratos
  final TextEditingController _carbsController = TextEditingController();
  // TextField: Proteína
  final TextEditingController _proteinaController = TextEditingController();
  // TextField: Gordura
  final TextEditingController _gorduraController = TextEditingController();

  // ── Estado dos seletores ─────────────────────────────────────────────────────
  // ChoiceChip: Categoria selecionada (Proteína, Vegetal, Carboidrato)
  String _categoriaSelecionada = 'Proteína';
  // ChoiceChip: Tipo de refeição selecionado (Café da Manhã, Almoço, Jantar, Lanche)
  String _tipoSelecionado = 'Almoço';
  // DatePicker: Data selecionada
  DateTime _dataSelecionada = DateTime.now();
  // TimePicker: Horário selecionado
  TimeOfDay _horarioSelecionado = TimeOfDay.now();

  bool _salvando = false;
  bool _editando = false;

  // Opções dos ChoiceChips de categoria
  final List<Map<String, dynamic>> _categorias = [
    {'label': 'Proteína', 'icon': '🥩'},
    {'label': 'Vegetal', 'icon': '🥦'},
    {'label': 'Carboidrato', 'icon': '🌾'},
  ];

  // Opções dos ChoiceChips de tipo de refeição
  final List<Map<String, dynamic>> _tipos = [
    {'label': 'Café da Manhã', 'icon': Icons.wb_sunny_outlined},
    {'label': 'Almoço', 'icon': Icons.wb_cloudy_outlined},
    {'label': 'Jantar', 'icon': Icons.nightlight_outlined},
    {'label': 'Lanche', 'icon': Icons.cookie_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _carregarDadosParaEdicao();
  }

  // ── Carrega dados da refeição se estiver editando ────────────────────────────
  void _carregarDadosParaEdicao() {
    if (widget.refeicaoParaEditar != null) {
      final refeicao = widget.refeicaoParaEditar!;
      _editando = true;

      // Preenche os controllers com os dados existentes
      _nomeController.text = refeicao.nome;
      _quantidadeController.text = refeicao.descricao ?? '';
      _caloriasController.text = refeicao.calorias.toString();
      _carbsController.text = refeicao.carbs.toString();
      _proteinaController.text = refeicao.proteina.toString();
      _gorduraController.text = refeicao.gordura.toString();

      // Define os seletores
      _tipoSelecionado = refeicao.tipo ?? 'Almoço';
      _categoriaSelecionada = refeicao.categoria ?? 'Proteína';

      // Parse da data
      try {
        _dataSelecionada = DateFormat('yyyy-MM-dd').parse(refeicao.data);
      } catch (e) {
        _dataSelecionada = DateTime.now();
      }

      // Parse do horário
      if (refeicao.horario != null && refeicao.horario!.isNotEmpty) {
        try {
          final parts = refeicao.horario!.split(':');
          _horarioSelecionado = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        } catch (e) {
          _horarioSelecionado = TimeOfDay.now();
        }
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _caloriasController.dispose();
    _carbsController.dispose();
    _proteinaController.dispose();
    _gorduraController.dispose();
    super.dispose();
  }

  // ── Abre o DatePicker ────────────────────────────────────────────────────────
  Future<void> _selecionarData() async {
    // DatePicker: conforme anotação "datepicker?" no mockup
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
    if (picked != null) {
      setState(() => _dataSelecionada = picked);
    }
  }

  // ── Abre o TimePicker ────────────────────────────────────────────────────────
  Future<void> _selecionarHorario() async {
    // TimePicker: conforme anotação "TimePicker" no mockup
    final picked = await showTimePicker(
      context: context,
      initialTime: _horarioSelecionado,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _horarioSelecionado = picked);
    }
  }

  // ── Salva ou atualiza no banco e retorna para a Home ─────────────────────────
  Future<void> _salvar() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome do alimento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final refeicao = Refeicao(
        id: _editando ? widget.refeicaoParaEditar!.id : null,
        nome: _nomeController.text.trim(),
        descricao: _quantidadeController.text.trim().isEmpty
            ? null
            : _quantidadeController.text.trim(),
        tipo: _tipoSelecionado,
        categoria: _categoriaSelecionada,
        calorias: double.tryParse(
                _caloriasController.text.replaceAll(',', '.')) ??
            0,
        carbs: double.tryParse(
                _carbsController.text.replaceAll(',', '.')) ??
            0,
        proteina: double.tryParse(
                _proteinaController.text.replaceAll(',', '.')) ??
            0,
        gordura: double.tryParse(
                _gorduraController.text.replaceAll(',', '.')) ??
            0,
        agua: 0,
        data: DateFormat('yyyy-MM-dd').format(_dataSelecionada),
        horario:
            '${_horarioSelecionado.hour.toString().padLeft(2, '0')}:${_horarioSelecionado.minute.toString().padLeft(2, '0')}',
      );

      // Se está editando, faz UPDATE; caso contrário, faz INSERT
      if (_editando) {
        await DatabaseHelper.instance.updateRefeicao(refeicao);
      } else {
        await DatabaseHelper.instance.insertRefeicao(refeicao);
      }

      if (mounted) {
        // Retorna true para a HomePage recarregar os dados
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // ── AppBar com IconButton de voltar ──────────────────────────────────────
      // IconButton: botão de voltar (seta) conforme anotação "iconbutton" no mockup
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          // Icon: ícone de seta para voltar
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        // Text: título "Adicionar Refeição" ou "Editar Refeição" conforme anotação "text" no mockup
        title: Text(
          _editando ? 'Editar Refeição' : 'Adicionar Refeição',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nome do Alimento ──────────────────────────────────────────────
            _buildLabel('Nome do Alimento'),
            const SizedBox(height: 8),
            // TextField: campo de pesquisa/nome com ícone de lupa
            // Conforme anotação "icon (icone a barra de pesquisa)" e "textfield (barra de pesquisa)"
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                // Icon: ícone de lupa dentro do campo
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'Ex: Frango grelhado',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
              ),
            ),

            const SizedBox(height: 20),

            // ── Quantidade ────────────────────────────────────────────────────
            _buildLabel('Quantidade'),
            const SizedBox(height: 8),
            // TextField: quantidade com ícone de balança
            TextField(
              controller: _quantidadeController,
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.scale_outlined, color: Colors.grey),
                hintText: 'Ex: 200g ou 1 porção',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
              ),
            ),

            const SizedBox(height: 20),

            // ── Categoria (ChoiceChip) ────────────────────────────────────────
            _buildLabel('Categoria'),
            const SizedBox(height: 10),
            // ChoiceChip: seleção de categoria conforme anotação "talvez choicechip" no mockup
            Wrap(
              spacing: 8,
              children: _categorias.map((cat) {
                final selecionado = _categoriaSelecionada == cat['label'];
                return ChoiceChip(
                  // Icon/emoji da categoria dentro do chip
                  label: Text('${cat['icon']}  ${cat['label']}'),
                  selected: selecionado,
                  onSelected: (_) =>
                      setState(() => _categoriaSelecionada = cat['label']),
                  selectedColor: const Color(0xFF1B5E20),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selecionado ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: selecionado
                        ? FontWeight.bold
                        : FontWeight.normal,
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
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ── Tipo de Refeição (ChoiceChip com ícone) ──────────────────────
            _buildLabel('Tipo de Refeição'),
            const SizedBox(height: 10),
            // ChoiceChip: tipo de refeição conforme anotação "choicechip? (escolher uma opção)" no mockup
            Row(
              children: _tipos.map((tipo) {
                final selecionado = _tipoSelecionado == tipo['label'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _tipoSelecionado = tipo['label']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selecionado
                              ? const Color(0xFF1B5E20)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selecionado
                                ? const Color(0xFF1B5E20)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Icon: ícone do tipo de refeição
                            Icon(
                              tipo['icon'] as IconData,
                              color: selecionado
                                  ? Colors.white
                                  : Colors.grey[600],
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            // Text: nome do tipo de refeição
                            Text(
                              tipo['label'] == 'Café da Manhã'
                                  ? 'Café da\nManhã'
                                  : tipo['label'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: selecionado
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: selecionado
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ── Macros (Calorias, Carbs, Proteína, Gordura) ──────────────────
            _buildLabel('Informações Nutricionais'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildCampoNumerico(
                    controller: _caloriasController,
                    hint: '0',
                    label: 'Calorias (kcal)',
                    icone: Icons.local_fire_department_outlined,
                    cor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCampoNumerico(
                    controller: _carbsController,
                    hint: '0',
                    label: 'Carbs (g)',
                    icone: Icons.grain_outlined,
                    cor: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildCampoNumerico(
                    controller: _proteinaController,
                    hint: '0',
                    label: 'Proteína (g)',
                    icone: Icons.fitness_center_outlined,
                    cor: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCampoNumerico(
                    controller: _gorduraController,
                    hint: '0',
                    label: 'Gordura (g)',
                    icone: Icons.opacity_outlined,
                    cor: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Data e Horário ────────────────────────────────────────────────
            Row(
              children: [
                // ── Data (DatePicker) ─────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Data'),
                      const SizedBox(height: 8),
                      // GestureDetector que abre o DatePicker
                      // conforme anotação "datepicker?" no mockup
                      GestureDetector(
                        onTap: _selecionarData,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              // Icon: ícone de calendário
                              const Icon(Icons.calendar_today_outlined,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              // Text: data formatada
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(_dataSelecionada),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // ── Horário (TimePicker) ──────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Horário'),
                      const SizedBox(height: 8),
                      // GestureDetector que abre o TimePicker
                      // conforme anotação "TimePicker" e "icon" no mockup
                      GestureDetector(
                        onTap: _selecionarHorario,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              // Icon: ícone de relógio conforme anotação "icon" no mockup
                              const Icon(Icons.access_time_outlined,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              // Text: horário formatado
                              Text(
                                '${_horarioSelecionado.hour.toString().padLeft(2, '0')}:${_horarioSelecionado.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── ElevatedButton: Salvar Refeição ───────────────────────────────
            // Botão principal conforme mockup
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_editando ? Icons.edit : Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _editando ? 'Atualizar Refeição' : 'Salvar Refeição',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Widget auxiliar: label de seção ─────────────────────────────────────────
  // Text: rótulo de cada seção conforme anotação "text" no mockup
  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  // ── Widget auxiliar: campo numérico de macro ─────────────────────────────────
  Widget _buildCampoNumerico({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icone,
    required Color cor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: Icon(icone, color: cor, size: 18),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
        ),
      ],
    );
  }
}
