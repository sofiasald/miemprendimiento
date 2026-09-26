import 'package:uuid/uuid.dart';

class Usuario {
  final String id;
  String usuario;
  String passwordHash;

  Usuario({
    String? id,
    required this.usuario,
    required this.passwordHash,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario': usuario,
        'passwordHash': passwordHash,
      };

  factory Usuario.fromMap(Map<String, dynamic> m) => Usuario(
        id: m['id'],
        usuario: m['usuario'],
        passwordHash: m['passwordHash'],
      );
}
