import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'home/home_screen.dart';
import 'inventario/inventario_screen.dart';
import 'finanzas/finanzas_screen.dart';
import 'backup/backup_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Por defecto abre el Inventario (índice 1)

  final List<Widget> _pantallas = const [
    HomeScreen(),
    InventarioScreen(),
    FinanzasScreen(),
    BackupScreen(),
  ];

  Future<bool> _confirmarSalida() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Salir de la aplicación'),
        content: const Text('¿Querés cerrar Atelier?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. Capturamos el provider ANTES del await: acá el context
        //    todavía es válido con seguridad.
        final authProvider = context.read<AuthProvider>();

        // 2. El await puede tardar (el usuario tiene que tocar el diálogo).
        final salir = await _confirmarSalida();

        // 3. Chequeamos "mounted" antes de seguir, por si el widget se
        //    desmontó mientras esperábamos la respuesta del diálogo.
        if (!mounted) return;

        if (salir) {
          // No borra el token: solo bloquea, para que la próxima apertura
          // pida huella en vez de volver a mostrar el registro.
          authProvider.bloquearSesion();
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pantallas),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(index: 0, icon: Icons.home_rounded, label: 'Inicio'),
                  _buildNavItem(index: 1, icon: Icons.inventory_2_rounded, label: 'Inventario'),
                  _buildNavItem(index: 2, icon: Icons.payments_rounded, label: 'Finanzas'),
                  _buildNavItem(index: 3, icon: Icons.settings_rounded, label: 'Ajustes'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required String label}) {
    final bool isSelected = _currentIndex == index;

    final Color pillBackground = isSelected ? const Color(0xFFFFC6E5) : const Color(0xFFEDF3F8);
    final Color iconColor = isSelected ? const Color(0xFFE23D80) : const Color(0xFF6B7280);
    final Color textColor = isSelected ? const Color(0xFFE23D80) : const Color(0xFF6B7280);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(20),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 36,
              decoration: BoxDecoration(color: pillBackground, borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}