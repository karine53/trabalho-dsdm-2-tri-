import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/dabase_helper.dart';
import '../models/refeicao.dart';

/// [AdicionarRefeicaoPage] atualizada para permitir o registro flexível.
/// O usuário agora pode registrar apenas água, apenas alimento, ou ambos simultaneamente.
class AdicionarRefeicaoPage extends StatefulWidget {
  //armazena a refeiçao que sera editada
  //se for nulo significa que o usuario esta cadastrando uma nova refeiçao 
  final Refeicao? refeicaoParaEditar;

  const AdicionarRefeicaoPage({
    super.key,
    this.refeicaoParaEditar,
  });

  @override
  State<AdicionarRefeicaoPage> createState() => _AdicionarRefeicaoPageState();
}

class _AdicionarRefeicaoPageState extends State<AdicionarRefeicaoPage> {
  // ── CONTROLADORES ──────────────────────────────────────────────────────────
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _caloriasController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _proteinaController = TextEditingController();
  final TextEditingController _gorduraController = TextEditingController();
  final TextEditingController _aguaController = TextEditingController();

  // ── ESTADO ─────────────────────────────────────────────────────────────────
  String _categoriaSelecionada = 'Proteína';
  String _tipoSelecionado = 'Almoço';
  DateTime _dataSelecionada = DateTime.now();
  TimeOfDay _horarioSelecionado = TimeOfDay.now();

  bool _salvando = false;
  bool _editando = false;

  final List<Map<String, dynamic>> _categorias = [
    {'label': 'Proteína', 'icon': '🥩'},
    {'label': 'Vegetal', 'icon': '🥦'},
    {'label': 'Carboidrato', 'icon': '🌾'},
  ];

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

  void _carregarDadosParaEdicao() {
    if (widget.refeicaoParaEditar != null) {
      final refeicao = widget.refeicaoParaEditar!;
      _editando = true;

      _nomeController.text = refeicao.nome;
      _quantidadeController.text = refeicao.descricao ?? '';
      _caloriasController.text = refeicao.calorias.toString();
      _carbsController.text = refeicao.carbs.toString();
      _proteinaController.text = refeicao.proteina.toString();
      _gorduraController.text = refeicao.gordura.toString();
      _aguaController.text = refeicao.agua.toString();

      _tipoSelecionado = refeicao.tipo ?? 'Almoço';
      _categoriaSelecionada = refeicao.categoria ?? 'Proteína';

      try {
        _dataSelecionada = DateFormat('yyyy-MM-dd').parse(refeicao.data);
      } catch (e) {
        _dataSelecionada = DateTime.now();
      }

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
  void dispose() { //limpeza da memoria 
    _nomeController.dispose();
    _quantidadeController.dispose();
    _caloriasController.dispose();
    _carbsController.dispose();
    _proteinaController.dispose();
    _gorduraController.dispose();
    _aguaController.dispose();
    super.dispose();
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
    if (picked != null) {
      setState(() => _dataSelecionada = picked);
    }
  }

  Future<void> _selecionarHorario() async {
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

  /// LÓGICA DE SALVAMENTO FLEXÍVEL:
  /// Esta função agora permite salvar mesmo que o nome do alimento esteja vazio,
  /// desde que haja um valor de água informado.
  Future<void> _salvar() async {
    String nome = _nomeController.text.trim();
    double agua = double.tryParse(_aguaController.text.replaceAll(',', '.')) ?? 0;

    // VALIDAÇÃO: Se não houver nome E nem água, não permite salvar.
    if (nome.isEmpty && agua <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um alimento ou a quantidade de água'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Se o usuário está registrando APENAS água, definimos um nome padrão para o registro.
    if (nome.isEmpty && agua > 0) {
      nome = "Hidratação";
    }

    setState(() => _salvando = true);

    try {
      final refeicao = Refeicao(
        id: _editando ? widget.refeicaoParaEditar!.id : null,
        nome: nome,
        descricao: _quantidadeController.text.trim().isEmpty ? null : _quantidadeController.text.trim(),
        tipo: _tipoSelecionado,
        categoria: _categoriaSelecionada,
        calorias: double.tryParse(_caloriasController.text.replaceAll(',', '.')) ?? 0, //transforma para double e usa a virgula 
        carbs: double.tryParse(_carbsController.text.replaceAll(',', '.')) ?? 0,
        proteina: double.tryParse(_proteinaController.text.replaceAll(',', '.')) ?? 0,
        gordura: double.tryParse(_gorduraController.text.replaceAll(',', '.')) ?? 0,
        agua: agua,
        data: DateFormat('yyyy-MM-dd').format(_dataSelecionada),
        horario: '${_horarioSelecionado.hour.toString().padLeft(2, '0')}:${_horarioSelecionado.minute.toString().padLeft(2, '0')}',
      );

      if (_editando) {
        await DatabaseHelper.instance.updateRefeicao(refeicao);
      } else {
        await DatabaseHelper.instance.insertRefeicao(refeicao);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( // mensagens que aparecem rapidas 
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _editando ? 'Editar Registro' : 'Adicionar Registro',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SEÇÃO DE ÁGUA (DESTAQUE) ──────────────────────────────────────
            // A água foi movida para o topo para facilitar o registro rápido.
            _buildLabel('Hidratação (ml)'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _buildCampoNumerico(
                    controller: _aguaController,
                    hint: '0',
                    label: 'Quantidade de água',
                    icone: Icons.local_drink,
                    cor: Colors.blue,
                  ),
                  const SizedBox(height: 15),
                  // BOTÕES DE ATALHO: Permitem adicionar quantidades comuns com um clique.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAtalhoAgua(200),
                      _buildAtalhoAgua(350),
                      _buildAtalhoAgua(500),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Divider(), // Linha divisória para separar água de alimentos.
            const SizedBox(height: 20),

            // ── SEÇÃO DE ALIMENTO ────────────────────────────────────────────
            _buildLabel('Alimento (Opcional se registrar água)'),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.restaurant, color: Colors.grey),
                hintText: 'Ex: Frango grelhado',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),

            const SizedBox(height: 20),

            _buildLabel('Quantidade'),
            const SizedBox(height: 8),
            TextField(
              controller: _quantidadeController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.scale_outlined, color: Colors.grey),
                hintText: 'Ex: 200g ou 1 porção',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),

            const SizedBox(height: 20),

            _buildLabel('Categoria'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _categorias.map((cat) {
                final selecionado = _categoriaSelecionada == cat['label'];
                return ChoiceChip(
                  label: Text('${cat['icon']}  ${cat['label']}'),
                  selected: selecionado,
                  onSelected: (_) => setState(() => _categoriaSelecionada = cat['label']),
                  selectedColor: const Color(0xFF1B5E20),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: selecionado ? Colors.white : Colors.black87, fontSize: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: selecionado ? const Color(0xFF1B5E20) : Colors.grey.shade300),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            _buildLabel('Tipo de Refeição'),
            const SizedBox(height: 10),
            Row(
              children: _tipos.map((tipo) {
                final selecionado = _tipoSelecionado == tipo['label'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setState(() => _tipoSelecionado = tipo['label']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selecionado ? const Color(0xFF1B5E20) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selecionado ? const Color(0xFF1B5E20) : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(tipo['icon'] as IconData, color: selecionado ? Colors.white : Colors.grey[600], size: 22),
                            const SizedBox(height: 4),
                            Text(
                              tipo['label'] == 'Café da Manhã' ? 'Café da\nManhã' : tipo['label'],
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, color: selecionado ? Colors.white : Colors.grey[600]),
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

            _buildLabel('Informações Nutricionais'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildCampoNumerico(controller: _caloriasController, hint: '0', label: 'Calorias (kcal)', icone: Icons.local_fire_department_outlined, cor: Colors.orange)),
                const SizedBox(width: 10),
                Expanded(child: _buildCampoNumerico(controller: _carbsController, hint: '0', label: 'Carbs (g)', icone: Icons.grain_outlined, cor: Colors.blue)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildCampoNumerico(controller: _proteinaController, hint: '0', label: 'Proteína (g)', icone: Icons.fitness_center_outlined, cor: Colors.deepOrange)),
                const SizedBox(width: 10),
                Expanded(child: _buildCampoNumerico(controller: _gorduraController, hint: '0', label: 'Gordura (g)', icone: Icons.opacity_outlined, cor: Colors.red)),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Data'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selecionarData,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text(DateFormat('dd/MM/yyyy').format(_dataSelecionada), style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Horário'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selecionarHorario,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_outlined, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('${_horarioSelecionado.hour.toString().padLeft(2, '0')}:${_horarioSelecionado.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 14)),
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

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _salvando
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_editando ? Icons.edit : Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(_editando ? 'Atualizar Registro' : 'Salvar Registro', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildLabel(String texto) {
    return Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87));
  }

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
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: Icon(icone, color: cor, size: 18),
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
        ),
      ],
    );
  }

  /// WIDGET AUXILIAR: Atalhos para adicionar água rapidamente.
  /// Ao clicar, ele soma o valor ao que já está no campo de texto.
  Widget _buildAtalhoAgua(int ml) {
    return ActionChip(
      label: Text('$ml ml'),
      avatar: const Icon(Icons.add, size: 14, color: Colors.blue),
      onPressed: () {
        double atual = double.tryParse(_aguaController.text) ?? 0;
        setState(() {
          _aguaController.text = (atual + ml).toString();
        });
      },
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.blue),
    );
  }
}
