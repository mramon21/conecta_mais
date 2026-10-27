import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String nome;
  final String email;
  final bool isOrganizer;
  final bool solicitacaoOrganizador;
  final String? photoUrl;
  final DateTime createdAt;
  final String? documento;
  final String? nomeInstituicao;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.isOrganizer,
    this.solicitacaoOrganizador = false,
    this.photoUrl,
    required this.createdAt,
    this.documento,
    this.nomeInstituicao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'isOrganizer': isOrganizer,
      'solicitacaoOrganizador': solicitacaoOrganizador,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'documento': documento,
      'nomeInstituicao': nomeInstituicao,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      isOrganizer: map['isOrganizer'] ?? false,
      solicitacaoOrganizador: map['solicitacaoOrganizador'] ?? false,
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      documento: map['documento'] as String?,
      nomeInstituicao: map['nomeInstituicao'] as String?,
    );
  }
}
