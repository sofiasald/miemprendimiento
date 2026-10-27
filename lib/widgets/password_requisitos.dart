import 'package:flutter/material.dart';

/// Reglas de contraseña de Atelier. Un solo lugar para registro e inicio:
/// si algún día cambian las reglas, se cambian acá y listo.
///
/// - Mínimo 8 caracteres
/// - Al menos una mayúscula, una minúscula y un número
/// - Los símbolos (!@#$...) se permiten, pero no son obligatorios
class ReglasPassword {
  // \p{Lu} / \p{Ll} = cualquier letra mayúscula / minúscula (incluye Ñ, Á, etc.)
  static final _mayuscula = RegExp(r'\p{Lu}', unicode: true);
  static final _minuscula = RegExp(r'\p{Ll}', unicode: true);
  static final _numero = RegExp(r'\d');

  static const int largoMinimo = 8;

  static bool tieneLargo(String p) => p.length >= largoMinimo;
  static bool tieneMayuscula(String p) => _mayuscula.hasMatch(p);
  static bool tieneMinuscula(String p) => _minuscula.hasMatch(p);
  static bool tieneNumero(String p) => _numero.hasMatch(p);

  static bool esValida(String p) =>
      tieneLargo(p) && tieneMayuscula(p) && tieneMinuscula(p) && tieneNumero(p);
}

/// Lista de requisitos que se va marcando en rosa a medida que la usuaria
/// los cumple, y queda en gris lo que todavía falta.
class PasswordRequisitos extends StatelessWidget {
  final String password;

  const PasswordRequisitos({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu contraseña debe tener:',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _Requisito(
            texto: 'Mínimo 8 caracteres',
            cumple: ReglasPassword.tieneLargo(password),
          ),
          _Requisito(
            texto: 'Una letra mayúscula',
            cumple: ReglasPassword.tieneMayuscula(password),
          ),
          _Requisito(
            texto: 'Una letra minúscula',
            cumple: ReglasPassword.tieneMinuscula(password),
          ),
          _Requisito(
            texto: 'Un número',
            cumple: ReglasPassword.tieneNumero(password),
          ),
          const SizedBox(height: 4),
          const Text(
            'Los símbolos (!@#\$...) son opcionales',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Requisito extends StatelessWidget {
  static const _rosa = Color(0xFFE23D80);
  static const _gris = Color(0xFF9CA3AF);

  final String texto;
  final bool cumple;

  const _Requisito({required this.texto, required this.cumple});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            cumple ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: cumple ? _rosa : _gris,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              color: cumple ? Colors.black87 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}