import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finanzas_provider.dart';
import 'nuevo_movimiento_screen.dart';
import 'nuevo_pedido_screen.dart';

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  int _tabIndex = 0; // 0 = Ventas, 1 = Gastos, 2 = Pedidos

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FinanzasProvider>();
      provider.cargarVentas();
      provider.cargarGastos();
      provider.cargarPedidos();
    });
  }

  void _abrirOpciones() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.point_of_sale,
                color: Color(0xFFEC6294),
              ),
              title: const Text(
                'Nueva venta / gasto',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NuevoMovimientoScreen(),
                  ),
                );
                if (res == true) {
                  _mostrarConfirmacion('Movimiento guardado correctamente');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_note, color: Color(0xFFEC6294)),
              title: const Text(
                'Nuevo pedido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NuevoPedidoScreen()),
                );
                if (res == true)
                  _mostrarConfirmacion('Pedido guardado correctamente');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarConfirmacion(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              mensaje,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const Icon(Icons.check_rounded, color: Color(0xFFEC6294), size: 30),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        duration: const Duration(seconds: 2),
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanzasProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'FINANZAS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEBEBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildTab('Ventas', 0),
                  _buildTab('Gastos', 1),
                  _buildTab('Pedidos', 2),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _tabIndex == 0
                  ? _buildVentasList(provider)
                  : _tabIndex == 1
                  ? _buildGastosList(provider)
                  : _buildPedidosList(provider),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEC6294),
        shape: const CircleBorder(),
        onPressed: _abrirOpciones,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEC6294) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVentasList(FinanzasProvider provider) {
    if (provider.ventas.isEmpty) {
      return const Center(
        child: Text(
          'Todavía no registraste ninguna venta.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: provider.ventas.length,
      itemBuilder: (ctx, i) {
        final v = provider.ventas[i];
        return _buildMovimientoCard(
          titulo: _textoMovimiento(v, const [
            'producto',
            'descripcion',
            'nombre',
          ]),
          subtitulo: v.fecha,
          monto: v.monto,
          esIngreso: true,
        );
      },
    );
  }

  Widget _buildGastosList(FinanzasProvider provider) {
    if (provider.gastos.isEmpty) {
      return const Center(
        child: Text(
          'Todavía no registraste ningún gasto.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: provider.gastos.length,
      itemBuilder: (ctx, i) {
        final g = provider.gastos[i];
        return _buildMovimientoCard(
          titulo: _textoMovimiento(g, const [
            'material',
            'descripcion',
            'nombre',
          ]),
          subtitulo: g.fecha,
          monto: g.monto,
          esIngreso: false,
        );
      },
    );
  }

  Widget _buildPedidosList(FinanzasProvider provider) {
    if (provider.pedidos.isEmpty) {
      return const Center(
        child: Text(
          'No hay pedidos pendientes.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: provider.pedidos.length,
      itemBuilder: (ctx, i) {
        final p = provider.pedidos[i];
        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.black12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _textoMovimiento(p, const [
                          'producto',
                          'descripcion',
                          'nombre',
                        ]),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cliente: ${p.cliente}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Entrega: ${p.fechaEntrega}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$ ${_numeroMovimiento(p, const ['monto', 'precio', 'total'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _textoMovimiento(dynamic movimiento, List<String> propiedades) {
    for (final propiedad in propiedades) {
      try {
        final valor = propiedad == 'producto'
            ? movimiento.producto
            : propiedad == 'descripcion'
            ? movimiento.descripcion
            : propiedad == 'material'
            ? movimiento.material
            : movimiento.nombre;
        if (valor != null && valor.toString().isNotEmpty)
          return valor.toString();
      } catch (_) {}
    }
    return 'Movimiento';
  }

  String _numeroMovimiento(dynamic movimiento, List<String> propiedades) {
    for (final propiedad in propiedades) {
      try {
        final valor = propiedad == 'monto'
            ? movimiento.monto
            : propiedad == 'precio'
            ? movimiento.precio
            : movimiento.total;
        if (valor != null) {
          final numero = valor is num
              ? valor.toDouble()
              : double.tryParse('$valor');
          if (numero != null) return numero.toStringAsFixed(0);
        }
      } catch (_) {}
    }
    return '0';
  }

  Widget _buildMovimientoCard({
    required String titulo,
    required String subtitulo,
    required double monto,
    required bool esIngreso,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '${esIngreso ? '+' : '-'}\$ ${monto.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: esIngreso
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
