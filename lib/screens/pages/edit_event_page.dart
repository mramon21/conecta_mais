import 'package:conecta_mais/models/event_category.dart';
import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditEventPage extends StatefulWidget {
  const EditEventPage({super.key, required this.evento});
  final Evento evento;

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  late final TextEditingController _local;
  late final TextEditingController _endereco;
  late final TextEditingController _preco;
  late final TextEditingController _vagas;
  late DateTime _data;
  late TimeOfDay _hora;
  late String _categoria;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final evento = widget.evento;
    _nome = TextEditingController(text: evento.nomeEvento);
    _descricao = TextEditingController(text: evento.descricaoEvento);
    _local = TextEditingController(text: evento.localEvento);
    _endereco = TextEditingController(text: evento.enderecoEvento);
    _preco = TextEditingController(
      text: evento.valorIngresso.toStringAsFixed(2).replaceAll('.', ','),
    );
    _vagas = TextEditingController(text: (evento.vagasTotal ?? 1).toString());
    _data = evento.dataHoraEvento;
    _hora = TimeOfDay.fromDateTime(evento.dataHoraEvento);
    _categoria = evento.tipoEvento;
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _local.dispose();
    _endereco.dispose();
    _preco.dispose();
    _vagas.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final vagas = int.parse(_vagas.text);
    if (vagas < widget.evento.vagasOcupadas) {
      _message(
        'O número de vagas não pode ser menor que as inscrições atuais.',
      );
      return;
    }
    final dataHora = DateTime(
      _data.year,
      _data.month,
      _data.day,
      _hora.hour,
      _hora.minute,
    );
    if (!dataHora.isAfter(DateTime.now())) {
      _message('A data e o horário devem ser futuros.');
      return;
    }
    setState(() => _loading = true);
    final erro = await context.read<EventoProvider>().atualizarEvento(
      Evento(
        id: widget.evento.id,
        ownerId: widget.evento.ownerId,
        nomeEvento: _nome.text.trim(),
        descricaoEvento: _descricao.text.trim(),
        localEvento: _local.text.trim(),
        enderecoEvento: _endereco.text.trim(),
        dataHoraEvento: dataHora,
        valorIngresso: double.parse(_preco.text.replaceAll(',', '.')),
        tipoEvento: _categoria,
        imagemEvento: widget.evento.imagemEvento,
        vagasTotal: vagas,
        vagasOcupadasCount: widget.evento.vagasOcupadas,
      ),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (erro != null) {
      _message(erro);
      return;
    }
    Navigator.pop(context);
  }

  void _message(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.red));

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final dataInicial =
        _data.isBefore(DateTime(hoje.year, hoje.month, hoje.day))
        ? DateTime(hoje.year, hoje.month, hoje.day)
        : _data;
    final data = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: DateTime(hoje.year, hoje.month, hoje.day),
      lastDate: DateTime(2100),
    );
    if (data != null && mounted) setState(() => _data = data);
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(context: context, initialTime: _hora);
    if (hora != null && mounted) setState(() => _hora = hora);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editar evento')),
    body: Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome do evento'),
              validator: (v) => v == null || v.trim().length < 3
                  ? 'Informe um nome válido.'
                  : null,
            ),
            TextFormField(
              controller: _descricao,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator: (v) => v == null || v.trim().length < 10
                  ? 'Informe uma descrição válida.'
                  : null,
            ),
            TextFormField(
              controller: _local,
              decoration: const InputDecoration(labelText: 'Local'),
              validator: (v) => v == null || v.trim().length < 3
                  ? 'Informe um local válido.'
                  : null,
            ),
            TextFormField(
              controller: _endereco,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Endereço'),
              validator: (v) => v == null || v.trim().length < 5
                  ? 'Informe o endereço completo do evento.'
                  : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              items: EventCategory.values
                  .map(
                    (e) =>
                        DropdownMenuItem(value: e.label, child: Text(e.label)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v!),
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _selecionarData,
                    child: Text(
                      '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}',
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _selecionarHora,
                    child: Text(_hora.format(context)),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _preco,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Preço'),
              validator: (v) {
                final preco = double.tryParse((v ?? '').replaceAll(',', '.'));
                return preco == null || preco < 0
                    ? 'Informe um preço válido.'
                    : null;
              },
            ),
            TextFormField(
              controller: _vagas,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Número de vagas'),
              validator: (v) =>
                  int.tryParse(v ?? '') == null || int.parse(v!) <= 0
                  ? 'Informe um número válido.'
                  : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _salvar,
                child: Text(_loading ? 'Salvando...' : 'Salvar alterações'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
