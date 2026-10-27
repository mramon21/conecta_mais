import 'package:conecta_mais/models/event_category.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test('Evento serializa e desserializa os campos', () {
    final evento = Evento(
      nomeEvento: 'Show',
      descricaoEvento: 'Um grande show musical.',
      dataHoraEvento: DateTime(2027, 1, 2, 20),
      localEvento: 'Teatro',
      valorIngresso: 20,
      tipoEvento: EventCategory.musica.label,
      imagemEvento: 'https://example.com/evento.jpg',
      enderecoEvento: 'Rua das Flores, 100 - Centro, São Paulo',
    );

    final resultado = Evento.fromJson(evento.toJson());

    expect(resultado.nomeEvento, evento.nomeEvento);
    expect(resultado.dataHoraEvento, evento.dataHoraEvento);
    expect(resultado.imagemEvento, evento.imagemEvento);
    expect(resultado.enderecoEvento, evento.enderecoEvento);
    expect(resultado.vagasOcupadas, evento.vagasOcupadas);
    expect(evento.toJson(), isNot(contains('participantesIds')));
  });

  test(
    'Evento lê documentos legados com inscritos armazenados no documento',
    () {
      final evento = Evento.fromJson({
        'nomeEvento': 'Evento legado',
        'dataHoraEvento': '2027-01-02T20:00:00.000',
        'participantesIds': ['user-1', 'user-2'],
      });

      expect(evento.vagasOcupadas, 2);
      expect(evento.toJson()['vagasOcupadas'], 2);
      expect(evento.toJson(), isNot(contains('participantesIds')));
    },
  );

  test('Categorias centralizadas possuem rótulos únicos', () {
    final labels = EventCategory.allLabels;
    expect(labels.toSet().length, labels.length);
    expect(labels, contains(EventCategory.musica.label));
  });

  test('Data do evento é formatada em português por extenso', () {
    final evento = Evento(
      nomeEvento: 'Evento',
      descricaoEvento: 'Descrição do evento.',
      dataHoraEvento: DateTime(2026, 10, 23, 21),
      localEvento: 'Teatro',
      valorIngresso: 0,
      tipoEvento: EventCategory.arte.label,
    );

    expect(evento.dataHoraFormatada, 'Sexta, 23 de Out às 21:00');
  });

  test('Evento sem vagas disponíveis é marcado como esgotado', () {
    final evento = Evento(
      nomeEvento: 'Evento lotado',
      descricaoEvento: 'Descrição do evento.',
      dataHoraEvento: DateTime(2026, 10, 23, 21),
      localEvento: 'Teatro',
      valorIngresso: 0,
      tipoEvento: EventCategory.arte.label,
      vagasTotal: 10,
      vagasOcupadasCount: 10,
    );

    expect(evento.temVagas, isFalse);
    expect(evento.vagasRestantes, 0);
  });
}
