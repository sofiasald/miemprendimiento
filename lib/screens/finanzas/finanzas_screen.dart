import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finanzas_provider.dart';
import 'formulario.dart';
import 'historial_screen.dart';
import 'reporte_screen.dart';

/// Pantalla central de Finanzas con la navegación superior oficial de Figma:
/// [ Registrar | Historial | Reporte ]
class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  // 0: Registrar, 1: Historial, 2: Reporte
  int _indiceActivo = 1; 

  @override
  void initState() {
    super.initState();
    // Lectura inicial de tablas SQLite al abrir Finanzas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FinanzasProvider>();
      provider.cargarVentas();
     provider.cargarGastos();
      provider.cargarPedidos();
    });
    //WidgetsBinding.instance.addPostFrameCallback((_) {
      // Inyectamos a Elena Gómez para poblar la lista y poder probar el detalle
    //  context.read<FinanzasProvider>().cargarDatosDemostracion();
    //});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'FINANZAS',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _pestanaSuperior('Registrar', 0),
                _pestanaSuperior('Historial', 1),
                _pestanaSuperior('Reporte', 2),
              ],
            ),
          ),
        ),
      ),
      // IndexedStack preserva el estado de cada vista al alternar entre pestañas
      body: IndexedStack(
        index: _indiceActivo,
        children: const [
          PantallaPedidoBase(),
          HistorialScreen(),
          ReporteScreen(),
        ],
      ),
    );
  }

  /// Construye cada botón de la pestaña superior con indicador inferior rosado activo.
  Widget _pestanaSuperior(String titulo, int indice) {
    final bool seleccionado = _indiceActivo == indice;
    return InkWell(
      onTap: () {
        setState(() {
          _indiceActivo = indice;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: seleccionado ? const Color(0xFFE91E63) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          titulo,
          style: TextStyle(
            color: seleccionado ? Colors.black87 : Colors.black45,
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}