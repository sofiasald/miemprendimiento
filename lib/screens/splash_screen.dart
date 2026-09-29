import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventario_provider.dart';
import 'main_screen.dart';

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

    // Precargar datos del inventario y base de datos
    try {
      final provider = context.read<InventarioProvider>();
      await Future.wait([
        provider.cargarMateriales(),
        provider.cargarProductos(),
        provider.cargarCombos(),
      ]);
    } catch (_) {
      // Si ocurre algún fallo de lectura, la app continúa normalmente
    }

    // Asegurar un mínimo de visualización fluida (ej. 1 segundo) para evitar parpadeos si carga instantáneo
    final elapsed = DateTime.now().difference(startTime);
    const minSplashDuration = Duration(milliseconds: 1200);
    if (elapsed < minSplashDuration) {
      await Future.delayed(minSplashDuration - elapsed);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precargar la imagen en memoria para evitar cualquier parpadeo o render borroso
    precacheImage(const AssetImage('assets/icon/app_icon.jpg'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFA8CB8), // Un rosado similar al de la imagen
      body: Center(
        child: Container(
          width: 192, // Coincide exactamente con el tamaño nativo de Android
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
