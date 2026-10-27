import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:conecta_mais/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  Uint8List? _fotoSelecionada;
  String? _fotoContentType;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: context.read<AuthProvider>().user?.nome ?? '',
    );
    _emailController = TextEditingController(
      text: context.read<AuthProvider>().user?.email ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selecionarFoto() async {
    final imagem = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (imagem == null) return;
    final bytes = await imagem.readAsBytes();
    if (!mounted) return;
    setState(() {
      _fotoSelecionada = bytes;
      _fotoContentType = imagem.mimeType;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final erro = await context.read<AuthProvider>().atualizarPerfil(
      nome: _nomeController.text,
      foto: _fotoSelecionada,
      contentType: _fotoContentType,
    );
    if (!mounted) return;
    setState(() => _salvando = false);
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.red),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso.')),
    );
    Navigator.pop(context);
  }

  Future<void> _solicitarAlteracaoEmail() async {
    final email = _emailController.text.trim();
    setState(() => _salvando = true);
    final erro = await context.read<AuthProvider>().solicitarAlteracaoEmail(
      email,
    );
    if (!mounted) return;
    setState(() => _salvando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          erro ??
              'Enviamos um link de confirmação para $email. O e-mail só muda após confirmar o link.',
        ),
        backgroundColor: erro == null ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = context.watch<AuthProvider>().user?.photoUrl;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 58,
                    backgroundImage: _fotoSelecionada != null
                        ? MemoryImage(_fotoSelecionada!)
                        : photoUrl?.isNotEmpty == true
                        ? CachedNetworkImageProvider(photoUrl!)
                        : null,
                    child:
                        _fotoSelecionada == null && photoUrl?.isNotEmpty != true
                        ? const Icon(Icons.person, size: 58)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      onPressed: _salvando ? null : _selecionarFoto,
                      tooltip: 'Escolher foto',
                      icon: const Icon(Icons.camera_alt),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nomeController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Informe um nome válido.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final email = (value ?? '').trim();
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                    ? null
                    : 'Informe um e-mail válido.';
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _salvando ? null : _solicitarAlteracaoEmail,
              icon: const Icon(Icons.mark_email_read_outlined),
              label: const Text('Enviar confirmação para alterar e-mail'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar alterações'),
            ),
          ],
        ),
      ),
    );
  }
}
