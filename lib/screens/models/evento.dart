import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Evento {
  const Evento({
    required this.nomeEvento,
    required this.descricaoEvento,
    required this.dataHoraEvento,
    required this.localEvento,
    required this.valorIngresso,
    required this.tipoEvento,
    this.enderecoEvento = '',
    this.id,
    this.ownerId,
    this.imagemEvento,
    this.vagasTotal,
    this.vagasOcupadasCount = 0,
  });

  final String? id;
  final String? ownerId;
  final String nomeEvento;
  final String descricaoEvento;
  final DateTime dataHoraEvento;
  final String localEvento;
  final double valorIngresso;
  final String tipoEvento;
  final String enderecoEvento;
  final String? imagemEvento;
  final int? vagasTotal;
  final int vagasOcupadasCount;

  int get vagasOcupadas => vagasOcupadasCount;
  String get dataHoraFormatada {
    final weekday = DateFormat(
      'EEEE',
      'pt_BR',
    ).format(dataHoraEvento).replaceFirst(RegExp(r'-feira$'), '');
    final weekdayCapitalized =
        '${weekday[0].toUpperCase()}${weekday.substring(1)}';
    final day = DateFormat('d', 'pt_BR').format(dataHoraEvento);
    final month = DateFormat(
      'MMM',
      'pt_BR',
    ).format(dataHoraEvento).replaceAll('.', '');
    final monthCapitalized = '${month[0].toUpperCase()}${month.substring(1)}';
    final time = DateFormat('HH:mm', 'pt_BR').format(dataHoraEvento);
    return '$weekdayCapitalized, $day de $monthCapitalized às $time';
  }

  int? get vagasRestantes =>
      vagasTotal == null ? null : vagasTotal! - vagasOcupadas;
  bool get temVagas => vagasTotal == null || vagasOcupadas < vagasTotal!;

  Map<String, dynamic> toJson() => {
    'nomeEvento': nomeEvento,
    'descricaoEvento': descricaoEvento,
    'dataHoraEvento': Timestamp.fromDate(dataHoraEvento),
    'localEvento': localEvento,
    'valorIngresso': valorIngresso,
    'tipoEvento': tipoEvento,
    'enderecoEvento': enderecoEvento,
    'imagemEvento': imagemEvento,
    'vagasTotal': vagasTotal,
    'vagasOcupadas': vagasOcupadas,
    'ownerId': ownerId,
  };

  factory Evento.fromJson(Map<String, dynamic> json, {String? id}) {
    final rawDate = json['dataHoraEvento'];
    final dataHoraEvento = rawDate is Timestamp
        ? rawDate.toDate()
        : rawDate is DateTime
        ? rawDate
        : DateTime.tryParse(rawDate as String? ?? '') ?? DateTime.now();
    final legacyParticipants = json['participantesIds'] as List? ?? const [];
    final vagasOcupadas =
        (json['vagasOcupadas'] as num?)?.toInt() ?? legacyParticipants.length;

    return Evento(
      id: id,
      ownerId: json['ownerId'] as String?,
      nomeEvento: json['nomeEvento'] as String? ?? '',
      descricaoEvento: json['descricaoEvento'] as String? ?? '',
      dataHoraEvento: dataHoraEvento,
      localEvento: json['localEvento'] as String? ?? '',
      valorIngresso: (json['valorIngresso'] as num?)?.toDouble() ?? 0,
      tipoEvento: json['tipoEvento'] as String? ?? '',
      enderecoEvento: json['enderecoEvento'] as String? ?? '',
      imagemEvento: json['imagemEvento'] as String?,
      vagasTotal: (json['vagasTotal'] as num?)?.toInt(),
      vagasOcupadasCount: vagasOcupadas,
    );
  }
}
