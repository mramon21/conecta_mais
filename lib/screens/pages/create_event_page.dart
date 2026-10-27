import 'dart:typed_data';

import 'package:conecta_mais/models/event_category.dart';
import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _localController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _precoController = TextEditingController();
  final _vagasController = TextEditingController();
  DateTime? _dataSelecionada;
  TimeOfDay? _horaSelecionada;
  String? _categoriaSelecionada;
  Uint8List? _imagemSelecionada;
  String? _imagemContentType;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _localController.dispose();
    _enderecoController.dispose();
    _precoController.dispose();
    _vagasController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    final imagem = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imagem != null && mounted) {
      final bytes = await imagem.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imagemSelecionada = bytes;
        _imagemContentType = imagem.mimeType;
      });
    }
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (data != null && mounted) setState(() => _dataSelecionada = data);
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (hora != null && mounted) setState(() => _horaSelecionada = hora);
  }

  Future<void> _criarEvento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataSelecionada == null ||
        _horaSelecionada == null ||
        _imagemSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione data, horário e banner do evento.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final dataHora = DateTime(
      _dataSelecionada!.year,
      _dataSelecionada!.month,
      _dataSelecionada!.day,
      _horaSelecionada!.hour,
      _horaSelecionada!.minute,
    );
    if (!dataHora.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A data e o horário devem ser futuros.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final provider = context.read<EventoProvider>();
      final imageUrl = await provider.uploadImagem(
        _imagemSelecionada!,
        contentType: _imagemContentType,
      );
      await provider.adicionarEvento(
        Evento(
          nomeEvento: _nomeController.text.trim(),
          descricaoEvento: _descricaoController.text.trim(),
          dataHoraEvento: dataHora,
          localEvento: _localController.text.trim(),
          enderecoEvento: _enderecoController.text.trim(),
          valorIngresso: double.parse(
            _precoController.text.replaceAll(',', '.'),
          ),
          tipoEvento: _categoriaSelecionada!,
          imagemEvento: imageUrl,
          vagasTotal: int.parse(_vagasController.text),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento criado com sucesso.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar evento: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF060226),
    appBar: AppBar(
      backgroundColor: const Color(0xFF060226),
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text('Criar evento', style: TextStyle(color: Colors.white)),
    ),
    body: Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Banner do evento',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _isSubmitting ? null : _selecionarImagem,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imagemSelecionada == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            color: Colors.white,
                            size: 48,
                          ),
                          Text(
                            'Selecionar banner',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _imagemSelecionada!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nomeController,
              decoration: _decoration('Nome do evento', Icons.event),
              validator: (value) => value == null || value.trim().length < 3
                  ? 'Informe um nome com ao menos 3 caracteres.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              maxLines: 4,
              decoration: _decoration('Descrição', Icons.description),
              validator: (value) => value == null || value.trim().length < 10
                  ? 'Informe uma descrição com ao menos 10 caracteres.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _categoriaSelecionada,
              decoration: _decoration('Categoria', Icons.category),
              items: EventCategory.values
                  .map(
                    (categoria) => DropdownMenuItem(
                      value: categoria.label,
                      child: Text(categoria.label),
                    ),
                  )
                  .toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _categoriaSelecionada = value),
              validator: (value) =>
                  value == null ? 'Selecione uma categoria.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _localController,
              decoration: _decoration('Local', Icons.location_on),
              validator: (value) => value == null || value.trim().length < 3
                  ? 'Informe um local válido.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _enderecoController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Endereço', Icons.pin_drop_outlined),
              validator: (value) => value == null || value.trim().length < 5
                  ? 'Informe o endereço completo do evento.'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _selecionarData,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      _dataSelecionada == null
                          ? 'Selecionar data'
                          : '${_dataSelecionada!.day.toString().padLeft(2, '0')}/${_dataSelecionada!.month.toString().padLeft(2, '0')}/${_dataSelecionada!.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _selecionarHora,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _horaSelecionada == null
                          ? 'Selecionar hora'
                          : _horaSelecionada!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _decoration('Preço do ingresso', Icons.attach_money),
              validator: (value) {
                final preco = double.tryParse(
                  (value ?? '').replaceAll(',', '.'),
                );
                return preco == null || preco < 0
                    ? 'Informe um preço válido.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vagasController,
              keyboardType: TextInputType.number,
              decoration: _decoration('Número de vagas', Icons.people_outline),
              validator: (value) {
                final vagas = int.tryParse(value ?? '');
                return vagas == null || vagas <= 0
                    ? 'Informe ao menos uma vaga.'
                    : null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _criarEvento,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  _isSubmitting ? 'Criando evento...' : 'Criar evento',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
