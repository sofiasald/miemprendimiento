import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../main_screen.dart';

class HuellaScreen extends StatefulWidget {
  const HuellaScreen({super.key});

  @override
  State<HuellaScreen> createState() => _HuellaScreenState();
}

class _HuellaScreenState extends State<HuellaScreen> {
  bool _verificando = false;

  @override
  void initState() {
    super.initState();
    // Pide la huella automáticamente al abrir la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _intentarDesbloquear());
  }

  Future<void> _intentarDesbloquear() async {
    if (_verificando) return;
    setState(() => _verificando = true);

    final exito = await context.read<AuthProvider>().desbloquearConHuella();

    if (!mounted) return;
    setState(() => _verificando = false);

    if (exito) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo verificar la huella. Tocá el ícono para reintentar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF48FC2),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 4),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFFBEFF4),
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
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            const Spacer(flex: 4),
            GestureDetector(
              onTap: _intentarDesbloquear,
              child: _verificando
                  ? const SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Icon(Icons.fingerprint, color: Colors.white, size: 72),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}