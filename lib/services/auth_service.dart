import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'db_helper.dart';

String hashPassword(String password) =>
    sha256.convert(utf8.encode(password)).toString();

Future<bool> registrarUsuario(String usuario, String password) async {
  final db = await DBHelper.instance.database;
  await db.insert('usuarios', {
    'id': const Uuid().v4(),
    'usuario': usuario,
    'passwordHash': hashPassword(password),
  });
  return true;
}

Future<bool> login(String usuario, String password) async {
  final db = await DBHelper.instance.database;
  final resultado = await db.query('usuarios',
      where: 'usuario = ?', whereArgs: [usuario]);
  if (resultado.isEmpty) return false;
  return resultado.first['passwordHash'] == hashPassword(password);
}
