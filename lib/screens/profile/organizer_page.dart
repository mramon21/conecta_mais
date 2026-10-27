import 'package:conecta_mais/auth/auth_provider.dart';
import 'package:conecta_mais/screens/pages/create_event_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrganizerPage extends StatefulWidget {
  const OrganizerPage({super.key});

  @override
  State<OrganizerPage> createState() => _OrganizerPageState();
}

class _OrganizerPageState extends State<OrganizerPage> {
  final _formKey = GlobalKey<FormState>();
  final _documentoController = TextEditingController();
  final _instituicaoController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _documentoController.dispose();
    _instituicaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final erro = await context.read<AuthProvider>().cadastrarComoOrganizador(
      documento: _documentoController.text.trim(),
      nomeInstituicao: _instituicaoController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.red),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastro de criador concluído!')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CreateEventPage()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tornar-se organizador')),
    body: Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informe dados básicos para criar e organizar seus eventos.',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _instituicaoController,
              decoration: const InputDecoration(
                labelText: 'Nome da instituição ou responsável',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().length < 3
                  ? 'Informe um nome válido.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CPF ou CNPJ',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().length < 11
                  ? 'Informe CPF ou CNPJ.'
                  : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _salvar,
                child: Text(
                  _loading ? 'Salvando...' : 'Continuar como organizador',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
