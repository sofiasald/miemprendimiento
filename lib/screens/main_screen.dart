import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FinanzasProvider extends ChangeNotifier {
  final List<Venta> ventas = [];
  final List<Gasto> gastos = [];
  final List<Pedido> pedidos = [];

  Future<void> cargarVentas() async {}
  Future<void> cargarGastos() async {}
  Future<void> cargarPedidos() async {}
}

class Venta {
  final String nombreItem;
  final DateTime fecha;
  final double monto;

  Venta({this.nombreItem = '', required this.fecha, required this.monto});
}

class Gasto {
  final String materialNombre;
  final DateTime fecha;
  final double monto;

  Gasto({this.materialNombre = '', required this.fecha, required this.monto});
}

class Pedido {
  final String nombreItem;
  final DateTime fechaEntrega;
  final double monto;

  Pedido({
    this.nombreItem = '',
    required this.fechaEntrega,
    required this.monto,
  });
}

class NuevoMovimientoScreen extends StatelessWidget {
  const NuevoMovimientoScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nuevo movimiento')),
    body: const SizedBox.shrink(),
  );
}

class NuevoPedidoScreen extends StatelessWidget {
  const NuevoPedidoScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nuevo pedido')),
    body: const SizedBox.shrink(),
  );
}

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
    if (ok == true && mounted) {
      context.read<FinanzasProvider>().cargarVentas();
      context.read<FinanzasProvider>().cargarGastos();
    }
  }

  Future<void> _abrirNuevoPedido() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NuevoPedidoScreen()),
    );
    if (ok == true && mounted) {
      context.read<FinanzasProvider>().cargarPedidos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final finanzas = context.watch<FinanzasProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Finanzas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: _AccionCard(
                    icon: Icons.point_of_sale,
                    titulo: 'Nuevo\nMovimiento',
                    onTap: _abrirNuevoMovimiento,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AccionCard(
                    icon: Icons.calendar_month,
                    titulo: 'Nuevo\nPedido',
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
              ...finanzas.pedidos.map(
                (p) => _TileMovimiento(
                  titulo: p.nombreItem.isEmpty ? 'Pedido' : p.nombreItem,
                  subtitulo:
                      'Pedido · entrega ${p.fechaEntrega.day}/${p.fechaEntrega.month}/${p.fechaEntrega.year}',
                  monto: p.monto,
                  colorMonto: Colors.blueGrey,
                ),
              ),
              ...finanzas.ventas.map(
                (v) => _TileMovimiento(
                  titulo: v.nombreItem.isEmpty ? 'Venta' : v.nombreItem,
                  subtitulo:
                      'Venta · ${v.fecha.day}/${v.fecha.month}/${v.fecha.year}',
                  monto: v.monto,
                  colorMonto: Colors.green,
                ),
              ),
              ...finanzas.gastos.map(
                (g) => _TileMovimiento(
                  titulo: g.materialNombre.isEmpty ? 'Gasto' : g.materialNombre,
                  subtitulo:
                      'Gasto · ${g.fecha.day}/${g.fecha.month}/${g.fecha.year}',
                  monto: -g.monto,
                  colorMonto: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccionCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final VoidCallback onTap;

  const _AccionCard({
    required this.icon,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE23D80);
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
