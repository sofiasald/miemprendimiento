import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../services/auth_service.dart' as auth_service;

/// Maneja todo el ciclo de sesión: registro, login con contraseña,
/// desbloqueo con huella y bloqueo al salir de la app.
///
/// IMPORTANTE: "bloquear" la sesión (bloquearSesion) NO borra el token.
/// Solo oculta el contenido hasta que vuelva a pasar la huella. El token
/// se borra únicamente con cerrarSesionCompleta(), si en el futuro agregan
/// un botón de "cerrar sesión" real.
class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const _tokenKey = 'session_token';

  bool _sesionDesbloqueada = false;
  bool get sesionDesbloqueada => _sesionDesbloqueada;

  AuthProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App pasa a segundo plano o se cierra -> se bloquea (no se borra el token)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      bloquearSesion();
    }
  }

  /// true si ya existe un usuario registrado en este dispositivo
  /// (sirve para que el splash decida: ¿registro o huella?)
  Future<bool> hayUsuarioRegistrado() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null;
  }

  Future<bool> registrar(String usuario, String password) async {
    final ok = await auth_service.registrarUsuario(usuario, password);
    if (ok) {
      await _generarYGuardarToken();
      _sesionDesbloqueada = true;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> loginConPassword(String usuario, String password) async {
    final ok = await auth_service.login(usuario, password);
    if (ok) {
      await _generarYGuardarToken();
      _sesionDesbloqueada = true;
      notifyListeners();
    }
    return ok;
  }

  Future<void> _generarYGuardarToken() async {
    final token = const Uuid().v4();
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Usar en la pantalla de huella ya existente.
  Future<bool> desbloquearConHuella() async {
    try {
      final autenticado = await _localAuth.authenticate(
        localizedReason: 'Confirmá tu identidad para entrar a Atelier',
        biometricOnly: true,
      );
      if (!autenticado) return false;

      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null) return false;

      _sesionDesbloqueada = true;
      notifyListeners();
      return true;
    } catch (_) {
      return false; // sensor no disponible, huella no configurada, etc.
    }
  }

  Future<bool> dispositivoSoportaHuella() async {
    final soportado = await _localAuth.canCheckBiometrics;
    final disponibles = await _localAuth.getAvailableBiometrics();
    return soportado && disponibles.isNotEmpty;
  }

  /// Se llama al tocar "atrás" en la pantalla principal o cuando la app
  /// pasa a segundo plano. NO borra el token.
  void bloquearSesion() {
    _sesionDesbloqueada = false;
    notifyListeners();
  }

  /// Solo para un futuro botón de "cerrar sesión" real (borra el token;
  /// la próxima apertura pediría usuario y contraseña de nuevo).
  Future<void> cerrarSesionCompleta() async {
    await _secureStorage.delete(key: _tokenKey);
    _sesionDesbloqueada = false;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}