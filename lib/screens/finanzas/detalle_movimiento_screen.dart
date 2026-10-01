import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/venta.dart';
import '../../models/gasto.dart';
import '../../providers/finanzas_provider.dart';

/// Pantalla genérica para visualizar o eliminar Ventas y Gastos.
class DetalleMovimientoScreen extends StatelessWidget {
  final Venta? venta;
  final Gasto? gasto;

  const DetalleMovimientoScreen.venta({super.key, required this.venta}) : gasto = null;
  const DetalleMovimientoScreen.gasto({super.key, required this.gasto}) : venta = null;

  @override
  Widget build(BuildContext context) {
    final bool esVenta = venta != null;
    final String titulo = esVenta
    ? (venta!.nombreItem ?? 'Venta Directa')
    : (gasto!.materialNombre ?? 'Compra Insumo');
    final double monto = esVenta ? venta!.monto : gasto!.monto;
    final String fecha = esVenta ? venta!.fecha : gasto!.fecha;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header con degradado
          Stack(
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: esVenta
                        ? [const Color(0xFF66BB6A), const Color(0xFFA5D6A7)]
                        : [const Color(0xFFEF5350), const Color(0xFFEF9A9A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Text(
                    esVenta ? 'VENTA REGISTRADA' : 'GASTO DE INSUMO',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline, color: Colors.black87, size: 18),
                    onPressed: () async {
                      final confirmacion = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('¿Eliminar ${esVenta ? "venta" : "gasto"}?'),
                          content: const Text(
                            'Esta transacción se removerá permanentemente de los balances financieros.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );

                      if (confirmacion == true) {
                        if (!context.mounted) return;
                        final provider = context.read<FinanzasProvider>();
                        if (esVenta) {
                          await provider.eliminarVenta(venta!.id);
                        } else {
                          await provider.eliminarGasto(gasto!.id);
                        }
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          // Cuerpo de la tarjeta
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: esVenta ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          esVenta ? 'VENTA' : 'GASTO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        '${esVenta ? "+" : "-"}\$${monto.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  const Text(
                    'DETALLES REGISTRADOS',
                    style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('• Concepto: $titulo', style: const TextStyle(fontSize: 13)),
                  Text('• Fecha: $fecha', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}