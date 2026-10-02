import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/inventario_provider.dart';
import '../providers/auth_provider.dart';
import 'auth/register_screen.dart';
import 'auth/huella_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _inicializarYContinuar();
  }

  Future<void> _inicializarYContinuar() async {
    final startTime = DateTime.now();

    try {
      final inventarioProvider = context.read<InventarioProvider>();
      await Future.wait([
        inventarioProvider.cargarMateriales(),
        inventarioProvider.cargarProductos(),
        inventarioProvider.cargarCombos(),
      ]);
    } catch (_) {
      // Si ocurre algún fallo de lectura, la app continúa normalmente
    }

    final elapsed = DateTime.now().difference(startTime);
    const minSplashDuration = Duration(milliseconds: 1200);
    if (elapsed < minSplashDuration) {
      await Future.delayed(minSplashDuration - elapsed);
    }

    if (!mounted) return;

    // Decide el destino: si ya hay un usuario registrado en este
    // dispositivo, va directo a pedir huella. Si es la primera vez,
    // muestra el registro.
    final authProvider = context.read<AuthProvider>();
    final yaTieneUsuario = await authProvider.hayUsuarioRegistrado();

    if (!mounted) return;

    final Widget siguientePantalla =
        yaTieneUsuario ? const HuellaScreen() : const RegisterScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => siguientePantalla,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/icon/app_icon.jpg'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFA8CB8),
      body: Center(
        child: Container(
          width: 192,
          height: 192,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/icon/app_icon.jpg',
              width: 192,
              height: 192,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}