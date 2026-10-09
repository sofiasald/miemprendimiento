//Conecta la acción del botón rosado inferior con la persistencia: al presionar "Marcar como Entregado", se da de alta la venta en la base de datos, se actualiza el estado del pedido y se recalculan los balances
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pedido.dart';
import '../../models/venta.dart';
import '../../providers/finanzas_provider.dart';

/// Pantalla completa de Detalle de Pedido.
/// Gestiona reactivamente los 3 estados operativos (Pendiente, Entregado, Cancelado)
/// conforme a los lineamientos de Figma y persistencia local.
class DetallePedidoScreen extends StatefulWidget {
  final Pedido pedido;
  const DetallePedidoScreen({super.key, required this.pedido});

  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  late Pedido _pedidoActual;

  @override
  void initState() {
    super.initState();
    _pedidoActual = widget.pedido;
  }

  // ---------------------------------------------------------------------------
  // ACCIÓN 1: Marcar como Entregado (Genera Venta y preserva el Pedido histórico)
  // ---------------------------------------------------------------------------
  Future<void> _marcarComoEntregado() async {
    final provider = context.read<FinanzasProvider>();

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Confirmar entrega?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'El pedido de ${_pedidoActual.cliente} pasará a estado ENTREGADO, se registrará una venta por \$${_pedidoActual.monto.toInt()} y se descontará el stock de insumos.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirmar Entrega',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmacion != true) return;

    // 1. Registrar la Venta correspondiente
    final nuevaVenta = Venta(
      id: 'venta-${DateTime.now().millisecondsSinceEpoch}',
      nombreItem: _pedidoActual.nombreItem,
      monto: _pedidoActual.monto,
      fecha: DateTime.now().toIso8601String(),
    );
    await provider.agregarVenta(nuevaVenta);

    // 2. Actualizar el pedido sin borrarlo (cambia a entregado con fecha real)
    setState(() {
      _pedidoActual.estado = 'entregado';
      _pedidoActual.fechaEntregaReal = DateTime.now();
    });
    await provider.actualizarPedido(_pedidoActual);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '¡Pedido entregado con éxito! Venta registrada en el balance.',
        ),
        backgroundColor: Color(0xFFE91E63),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACCIÓN 2: Cancelar Pedido (Pasa a CANCELADO, no genera venta ni toca stock)
  // ---------------------------------------------------------------------------
  Future<void> _cancelarPedido() async {
    final provider = context.read<FinanzasProvider>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Cancelar este pedido?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'El encargo se archivará como CANCELADO. No se registrará ingreso de dinero ni se descontarán materiales.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sí, Cancelar Pedido',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _pedidoActual.estado = 'cancelado';
    });
    await provider.actualizarPedido(_pedidoActual);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El pedido ha sido cancelado.'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACCIÓN 3: Eliminar Pedido definitivamente de SQLite
  // ---------------------------------------------------------------------------
  Future<void> _eliminarPedido() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar registro?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Se eliminará este pedido del historial permanentemente. Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await context.read<FinanzasProvider>().eliminarPedido(_pedidoActual.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // ACCIÓN 4: Editar Pedido Pendiente (Solo permitido en estado PENDIENTE)
  // ---------------------------------------------------------------------------
  void _mostrarModalEdicion() {
    final clienteCtrl = TextEditingController(text: _pedidoActual.cliente);
    final montoCtrl = TextEditingController(
      text: _pedidoActual.monto.toInt().toString(),
    );
    final obsCtrl = TextEditingController(text: _pedidoActual.observaciones);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Editar Pedido Pendiente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: clienteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del Cliente',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto Total (\$)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: obsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observaciones / Seña',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                ),
                onPressed: () async {
                  setState(() {
                    _pedidoActual.cliente = clienteCtrl.text.trim();
                    _pedidoActual.monto =
                        double.tryParse(montoCtrl.text) ?? _pedidoActual.monto;
                    _pedidoActual.observaciones = obsCtrl.text.trim();
                  });
                  await context.read<FinanzasProvider>().actualizarPedido(
                    _pedidoActual,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text(
                  'Guardar Cambios',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esPendiente = _pedidoActual.estado == 'pendiente';
    final esEntregado = _pedidoActual.estado == 'entregado';
    final esCancelado = _pedidoActual.estado == 'cancelado';

    final fechaPactadaStr =
        '${_pedidoActual.fechaEntrega.day.toString().padLeft(2, '0')}/${_pedidoActual.fechaEntrega.month.toString().padLeft(2, '0')}/${_pedidoActual.fechaEntrega.year}';
    final fechaRegistroStr = _pedidoActual.fechaRegistro != null
        ? '${_pedidoActual.fechaRegistro!.day.toString().padLeft(2, '0')}/${_pedidoActual.fechaRegistro!.month.toString().padLeft(2, '0')}/${_pedidoActual.fechaRegistro!.year}'
        : '12/08/2026';
    final fechaEntregadoStr = _pedidoActual.fechaEntregaReal != null
        ? '${_pedidoActual.fechaEntregaReal!.day.toString().padLeft(2, '0')}/${_pedidoActual.fechaEntregaReal!.month.toString().padLeft(2, '0')}/${_pedidoActual.fechaEntregaReal!.year}'
        : fechaPactadaStr;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // -------------------------------------------------------------------
          // HEADER CON FOTOGRAFÍA Y BOTONES DE ACCIÓN (LÁPIZ / TACHO)
          // -------------------------------------------------------------------
          Stack(
            children: [
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: esCancelado
                        ? [const Color(0xFF90A4AE), const Color(0xFFCFD8DC)]
                        : [const Color(0xFF42A5F5), const Color(0xFF90CAF9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Text(
                    _pedidoActual.nombreItem.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              // Botón Atrás
              Positioned(
                top: 40,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Acciones en la cabecera (Lápiz y Tacho)
              Positioned(
                top: 40,
                right: 16,
                child: Row(
                  children: [
                    // El lápiz de edición SOLO se dibuja si el estado es PENDIENTE
                    if (esPendiente) ...[
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.black87,
                            size: 18,
                          ),
                          onPressed: _mostrarModalEdicion,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // El tacho de basura siempre está disponible para depuración
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.black87,
                          size: 18,
                        ),
                        onPressed: _eliminarPedido,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // -------------------------------------------------------------------
          // CUERPO DE LA TARJETA TÉCNICA
          // -------------------------------------------------------------------
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de Estado y Monto
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: esPendiente
                                ? const Color(0xFFE91E63)
                                : esEntregado
                                ? const Color(0xFFF48FB1)
                                : const Color(0xFFF8BBD0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _pedidoActual.estado.toUpperCase(),
                            style: TextStyle(
                              color: esCancelado
                                  ? const Color(0xFF880E4F)
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          '\$${_pedidoActual.monto.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: esCancelado
                                ? Colors.black38
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _pedidoActual.cliente,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),

                    // FICHA DEL ARTÍCULO
                    const Text(
                      'FICHA DEL ARTÍCULO',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Artículo: ${_pedidoActual.nombreItem}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '• Cantidad: ${_pedidoActual.cantidad} unidad(es)',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),

                    // VARIANTE Y DETALLES
                    const Text(
                      'VARIANTE Y DETALLES',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Variante: ${_pedidoActual.variante}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),

                    // FECHAS OPERATIVAS SEGÚN ESTADO
                    if (esEntregado) ...[
                      const Text(
                        'FECHAS OPERATIVAS',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Entregado el $fechaEntregadoStr',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Encargo registrado: $fechaRegistroStr',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'ENTREGA PACTADA',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fechaPactadaStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Encargo registrado: $fechaRegistroStr',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // OBSERVACIONES / ESTADO DE MATERIALES
                    if (esCancelado) ...[
                      const Text(
                        'ESTADO DE MATERIALES',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'No se descontó stock del inventario.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (_pedidoActual.observaciones.isNotEmpty) ...[
                      const Text(
                        'OBSERVACIONES',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _pedidoActual.observaciones,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],

                    const Spacer(),

                    // BOTÓN INFERIOR: Solo visible si el pedido está PENDIENTE
                    if (esPendiente) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _marcarComoEntregado,
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            'Marcar como Entregado',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _cancelarPedido,
                          child: const Text(
                            'Cancelar Pedido',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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
