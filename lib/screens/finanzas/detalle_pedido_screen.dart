//Conecta la acción del botón rosado inferior con la persistencia: al presionar "Marcar como Entregado", se da de alta la venta en la base de datos, se actualiza el estado del pedido y se recalculan los balances
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pedido.dart';
import '../../models/venta.dart';
import '../../providers/finanzas_provider.dart';

/// Pantalla detallada de un pedido pendiente.
/// Permite visualizar la especificación artesanal y ejecutar la conversión de negocio.
class DetallePedidoScreen extends StatelessWidget {
  final Pedido pedido;
  const DetallePedidoScreen({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final fechaPactada =
        '${pedido.fechaEntrega.day.toString().padLeft(2, '0')}/${pedido.fechaEntrega.month.toString().padLeft(2, '0')}/${pedido.fechaEntrega.year}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
      
          // CABECERA CON IMAGEN Y ACCIONES
          Stack(
            children: [
              Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'SOY TÉCNICA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              // Botón atrás
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
            ],
          ),

          // FICHA TÉCNICA DEL PEDIDO
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PENDIENTE',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        Text(
                          '\$${pedido.monto.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pedido.cliente,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    const Text('FICHA DEL ARTÍCULO', style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('• Artículo: ${pedido.nombreItem}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const Text('• Cantidad encargada: 1 unidad', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    const Text('ENTREGA PACTADA', style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(fechaPactada, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),

                    // ACCIÓN: CONVERTIR A VENTA Y DESCONTAR STOCK
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final provider = context.read<FinanzasProvider>();

                          // 1. Registramos la venta equivalente
                          final nuevaVenta = Venta(
                            nombreItem: pedido.nombreItem,
                            monto: pedido.monto,
                            fecha: DateTime.now().toIso8601String(),
                          );
                          await provider.agregarVenta(nuevaVenta);

                          // 2. Quitamos el pedido entregado (como pedido.id nunca es nulo, se pasa directo)
                          await provider.eliminarPedido(pedido.id);

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Pedido entregado! Venta registrada correctamente.'),
                              backgroundColor: Color(0xFFE91E63),
                            ),
                          );

                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Marcar como Entregado',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}