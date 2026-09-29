import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'nuevo_movimiento_screen.dart';
import 'nuevo_pedido_screen.dart';
import 'finanzas_provider.dart';

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<FinanzasProvider>();
      p.cargarVentas();
      p.cargarGastos();
      p.cargarPedidos();
    });
  }

  Future<void> _abrirNuevoMovimiento() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NuevoMovimientoScreen()),
    );
    if (ok == true) {
      if (!mounted) return;
      context.read<FinanzasProvider>().cargarVentas();
      context.read<FinanzasProvider>().cargarGastos();
    }
  }

  Future<void> _abrirNuevoPedido() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NuevoPedidoScreen()),
    );
    if (ok == true) {
      if (!mounted) return;
      context.read<FinanzasProvider>().cargarPedidos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final finanzas = context.watch<FinanzasProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Finanzas'),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: _AccionCard(
                  icon: Icons.point_of_sale,
                  titulo: 'Nuevo\nMovimiento',
                  color: const Color(0xFFEC6294),
                  onTap: _abrirNuevoMovimiento,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AccionCard(
                  icon: Icons.calendar_month,
                  titulo: 'Nuevo\nPedido',
                  color: const Color(0xFFEC6294),
                  onTap: _abrirNuevoPedido,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'ÚLTIMOS MOVIMIENTOS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          if (finanzas.ventas.isEmpty &&
              finanzas.gastos.isEmpty &&
              finanzas.pedidos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Todavía no hay movimientos.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else ...[
            ...finanzas.ventas
                .take(10)
                .map(
                  (v) => _TileMovimiento(
                    titulo: 'Venta',
                    subtitulo: 'Venta · ${v.fecha}',
                    monto: v.monto,
                    colorMonto: Colors.green,
                  ),
                ),
            ...finanzas.gastos
                .take(10)
                .map(
                  (g) => _TileMovimiento(
                    titulo: 'Gasto',
                    subtitulo: 'Gasto · ${g.fecha}',
                    monto: -g.monto,
                    colorMonto: Colors.red,
                  ),
                ),
            ...finanzas.pedidos
                .take(10)
                .map(
                  (p) => _TileMovimiento(
                    titulo: 'Pedido',
                    subtitulo: 'Pedido · entrega ${p.fechaEntrega}',
                    monto: 0,
                    colorMonto: Colors.blueGrey,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _AccionCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final Color color;
  final VoidCallback onTap;

  const _AccionCard({
    required this.icon,
    required this.titulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileMovimiento extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final double monto;
  final Color colorMonto;

  const _TileMovimiento({
    required this.titulo,
    required this.subtitulo,
    required this.monto,
    required this.colorMonto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitulo,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$ ${monto.abs().toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: colorMonto),
          ),
        ],
      ),
    );
  }
}
