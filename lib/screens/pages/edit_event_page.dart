import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:conecta_mais/models/event_category.dart';
import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:conecta_mais/screens/pages/map_location_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
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
  Uint8List? _imagemSelecionada;
  String? _imagemContentType;
  double? _latitude;
  double? _longitude;
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
    if (evento.temCoordenadas) {
      _latitude = evento.latitude;
      _longitude = evento.longitude;
    }
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

  Future<void> _selecionarImagem() async {
    try {
      final imagem = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (imagem == null) return;
      final bytes = await imagem.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imagemSelecionada = bytes;
        _imagemContentType = imagem.mimeType;
      });
    } catch (error) {
      if (mounted) _message('Não foi possível selecionar o banner: $error');
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      _message('Marque a localização do evento no mapa.');
      return;
    }
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
    try {
      final provider = context.read<EventoProvider>();
      final imagemUrl = _imagemSelecionada == null
          ? widget.evento.imagemEvento
          : await provider.uploadImagem(
              _imagemSelecionada!,
              contentType: _imagemContentType,
            );
      final erro = await provider.atualizarEvento(
        Evento(
          id: widget.evento.id,
          ownerId: widget.evento.ownerId,
          isPrivate: widget.evento.isPrivate,
          nomeEvento: _nome.text.trim(),
          descricaoEvento: _descricao.text.trim(),
          localEvento: _local.text.trim(),
          enderecoEvento: _endereco.text.trim(),
          dataHoraEvento: dataHora,
          valorIngresso: double.parse(_preco.text.replaceAll(',', '.')),
          tipoEvento: _categoria,
          imagemEvento: imagemUrl,
          latitude: _latitude,
          longitude: _longitude,
          vagasTotal: vagas,
          vagasOcupadasCount: widget.evento.vagasOcupadas,
        ),
      );
      if (!mounted) return;
      if (erro != null) {
        _message(erro);
        return;
      }
      Navigator.pop(context);
    } catch (error) {
      if (mounted) _message('Não foi possível salvar as alterações: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  Future<void> _selecionarLocalizacao() async {
    final location = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapLocationPickerPage(latitude: _latitude, longitude: _longitude),
      ),
    );
    if (location != null && mounted) {
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editar evento')),
    body: Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Banner do evento',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _loading ? null : _selecionarImagem,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_imagemSelecionada != null)
                      Image.memory(_imagemSelecionada!, fit: BoxFit.cover)
                    else if (widget.evento.imagemEvento?.isNotEmpty == true)
                      CachedNetworkImage(
                        imageUrl: widget.evento.imagemEvento!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, _, _) => const Center(
                          child: Icon(Icons.broken_image_outlined, size: 40),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                        ),
                      ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: FilledButton.tonalIcon(
                        onPressed: _loading ? null : _selecionarImagem,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(
                          _imagemSelecionada != null ||
                                  widget.evento.imagemEvento?.isNotEmpty == true
                              ? 'Trocar banner'
                              : 'Selecionar banner',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome do evento'),
              validator: (v) => v == null || v.trim().length < 3
                  ? 'Informe um nome válido.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricao,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator: (v) => v == null || v.trim().length < 10
                  ? 'Informe uma descrição válida.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _local,
              decoration: const InputDecoration(labelText: 'Local'),
              validator: (v) => v == null || v.trim().length < 3
                  ? 'Informe um local válido.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endereco,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Endereço'),
              validator: (v) => v == null || v.trim().length < 5
                  ? 'Informe o endereço completo do evento.'
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _selecionarLocalizacao,
              icon: const Icon(Icons.map_outlined),
              label: Text(
                _latitude == null || _longitude == null
                    ? 'Marcar localização no mapa'
                    : 'Localização marcada: '
                          '${_latitude!.toStringAsFixed(5)}, '
                          '${_longitude!.toStringAsFixed(5)}',
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 16),
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
