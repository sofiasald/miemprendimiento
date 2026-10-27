import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/password_requisitos.dart';
import '../auth/register_success_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Colores del diseño
  static const _rosaBorde = Color(0xFFE23D80); // borde cuando hay error
  static const _rosaFondo = Color(0xFFFFC6E5); // fondo de casilla válida
  static const _rosaBoton = Color(0xFFD6528F); // botón habilitado
  static const _grisBoton = Color(0xFF8E8E8E); // botón deshabilitado
  static const _grisBorde = Color(0xFFE5E7EB); // borde neutro

  // Formato: texto@dominio.ext  (ej: ejemplo@gmail.com)
  static final _regexEmail = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _cargando = false;

  // Se vuelve true apenas la usuaria escribe algo: desde ahí se muestran
  // los bordes de error en las casillas inválidas o vacías.
  bool _tocado = false;

  bool get _emailValido => _regexEmail.hasMatch(_emailController.text.trim());
  // Mínimo 8 caracteres + mayúscula + minúscula + número (ver ReglasPassword)
  bool get _passwordValida => ReglasPassword.esValida(_passwordController.text);
  bool get _formularioValido => _emailValido && _passwordValida;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onRegistrarPressed() async {
    if (!_formularioValido) return;

    final usuario = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _cargando = true);
    final exito = await context.read<AuthProvider>().registrar(usuario, password);
    if (!mounted) return;
    setState(() => _cargando = false);

    if (exito) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterSuccessScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar. Probá con otro usuario.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ---- Encabezado rosa con logo y título ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 64, bottom: 40, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF48FC2), Color(0xFFF7ACD4)],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset('assets/icon/app_icon.jpg', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Atelier',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa tu correo y contraseña para registrarte',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // ---- Tarjeta blanca con el formulario ----
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enableSuggestions: false,
                        onChanged: (_) => setState(() => _tocado = true),
                        decoration: _decoracion(
                          hint: 'usuario@gmail.com',
                          valido: _emailValido,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        onChanged: (_) => setState(() => _tocado = true),
                        decoration: _decoracion(
                          hint: 'Contraseña',
                          valido: _passwordValida,
                          suffixIcon: IconButton(
                            // Oculta = ojo tachado. Visible = ojo abierto.
                            icon: Icon(
                              _passwordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.black38,
                            ),
                            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                          ),
                        ),
                      ),

                      // ---- Requisitos de la contraseña (se marcan en vivo) ----
                      PasswordRequisitos(password: _passwordController.text),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _rosaBoton,
                            // Gris si el formulario no es válido; si está
                            // cargando, se mantiene rosado con el spinner.
                            disabledBackgroundColor: _cargando ? _rosaBoton : _grisBoton,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: (_formularioValido && !_cargando) ? _onRegistrarPressed : null,
                          child: _cargando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Registrate',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Estados de cada casilla:
  /// - Neutra (todavía no escribió nada): fondo blanco, borde gris suave.
  /// - Con error (inválida o vacía, después de escribir): borde rosa.
  /// - Válida: fondo rosado, sin borde.
  InputDecoration _decoracion({
    required String hint,
    required bool valido,
    Widget? suffixIcon,
  }) {
    final mostrarError = _tocado && !valido;

    final Color borde = mostrarError
        ? _rosaBorde
        : valido
            ? Colors.transparent
            : _grisBorde;

    final OutlineInputBorder bordeCasilla = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borde, width: mostrarError ? 1.5 : 1),
    );

    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: valido ? _rosaFondo : Colors.white,
      border: bordeCasilla,
      enabledBorder: bordeCasilla,
      focusedBorder: bordeCasilla,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}