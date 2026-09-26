import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'inventario/inventario_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Por defecto abre el Inventario (índice 1)

  final List<Widget> _pantallas = [
    const _EnConstruccionScreen(titulo: 'Inicio'),
    const InventarioScreen(),
    const _EnConstruccionScreen(titulo: 'Finanzas / Ventas'),
    const _EnConstruccionScreen(titulo: 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pantallas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black87,
        unselectedItemColor: const Color(0xFFF9C4D8),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30, color: _currentIndex == 0 ? Colors.black87 : const Color(0xFFF9C4D8)),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2, size: 30, color: _currentIndex == 1 ? Colors.black87 : const Color(0xFFF9C4D8)),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.sackDollar, size: 28, color: _currentIndex == 2 ? Colors.black87 : const Color(0xFFF9C4D8)),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 30, color: _currentIndex == 3 ? Colors.black87 : const Color(0xFFF9C4D8)),
            label: '',
          ),
        ],
      ),
    );
  }
}

class _EnConstruccionScreen extends StatelessWidget {
  final String titulo;
  const _EnConstruccionScreen({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build_circle_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                '$titulo\n(En construcción)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
