import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // ---- Encabezado con logo + nombre ----
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/icon/app_icon.jpg',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Atelier',
                    style: TextStyle(
                      color: Color(0xFFEC6294),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ---- Botones de acción rápida ----
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _BotonAccion(
                    texto: 'Nueva Venta',
                    colorFondo: const Color(0xFFE23D80),
                    colorTexto: Colors.white,
                    onTap: () {
                      // TODO: navegar al formulario de venta (módulo Finanzas)
                    },
                  ),
                  const SizedBox(height: 14),
                  _BotonAccion(
                    texto: 'Nuevo Pedido',
                    colorFondo: const Color(0xFFFFC6E5),
                    colorTexto: const Color(0xFFE23D80),
                    onTap: () {
                      // TODO: navegar al formulario de pedido (módulo Finanzas)
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final String texto;
  final Color colorFondo;
  final Color colorTexto;
  final VoidCallback onTap;

  const _BotonAccion({
    required this.texto,
    required this.colorFondo,
    required this.colorTexto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorFondo,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: colorTexto),
            const SizedBox(width: 8),
            Text(
              texto,
              style: TextStyle(color: colorTexto, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}