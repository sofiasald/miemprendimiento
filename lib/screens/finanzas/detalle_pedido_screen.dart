import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pedido.dart';
import '../../providers/finanzas_provider.dart';
import '../../providers/inventario_provider.dart';

/// Pantalla de Detalle de Pedido con cabecera deslizable (Sliver),
/// ficha tipo ticket y botones de acción anclados en la parte inferior.
class DetallePedidoScreen extends StatefulWidget {
  final Pedido pedido;
  const DetallePedidoScreen({super.key, required this.pedido});

  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  late Pedido _pedidoActual;

  // Ruta de imagen opcional (conectada a SQLite o nula por defecto)
  final String? _rutaImagen = null;

  @override
  void initState() {
    super.initState();
    _pedidoActual = widget.pedido;
  }

  // --- FORMATEADORES AUXILIARES ---
  static String _formatearMonto(double monto) {
    final partes = monto.toInt().toString();
    return partes.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  static String _formatearFecha(DateTime dt) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${meses[dt.month - 1]} ${dt.year}';
  }

  // --- COMPONENTE DE SECCIÓN CLAVE-VALOR ---
  Widget _filaDato(String etiqueta, String valor, {bool destacar = false, Color? colorValor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                color: colorValor ?? const Color(0xFF212121),
                fontWeight: destacar ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _encabezadoSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        titulo,
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // --- ACCIONES DE ESTADO ---
  Future<void> _marcarComoEntregado() async {
    final provider = context.read<FinanzasProvider>();
    final inv = context.read<InventarioProvider>();

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Confirmar entrega?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'El pedido pasará a ENTREGADO, se registrará la venta por \$${_formatearMonto(_pedidoActual.monto)} y se descontará el stock de insumos.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE85E98),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirmar entrega',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmacion != true) return;

    await provider.entregarPedido(pedido: _pedidoActual, inventarioProvider: inv);

    if (mounted) {
      setState(() {
        _pedidoActual.estado = 'entregado';
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Pedido entregado con éxito! Se registró la venta.'),
        backgroundColor: Color(0xFFE85E98),
      ),
    );
  }

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
          'El encargo pasará a estado CANCELADO. No se registrará ingreso ni se descontará stock.',
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
              'Sí, cancelar pedido',
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
        content: Text('El pedido ha sido archivado como cancelado.'),
        backgroundColor: Colors.black87,
      ),
    );
  }

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
          'Se eliminará este pedido del sistema permanentemente.',
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

    if (!mounted) return;
    await context.read<FinanzasProvider>().eliminarPedido(_pedidoActual.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  // --- MODAL DE EDICIÓN ELEGANTE (SIN VARIANTES) ---
  void _mostrarModalEdicion() {
    final clienteCtrl = TextEditingController(text: _pedidoActual.cliente);
    final montoCtrl = TextEditingController(text: _pedidoActual.monto.toInt().toString());
    final obsCtrl = TextEditingController(text: _pedidoActual.observaciones);
    DateTime fechaSeleccionada = _pedidoActual.fechaEntrega;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Editar Pedido Pendiente',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF212121)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF757575)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cliente
              TextField(
                controller: clienteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cliente',
                  labelStyle: TextStyle(color: Color(0xFF757575), fontSize: 13),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE85E98), width: 2)),
                ),
              ),
              const SizedBox(height: 14),

              // Monto y Fecha en fila compartida
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: montoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monto Total (\$)',
                        labelStyle: TextStyle(color: Color(0xFF757575), fontSize: 13),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE85E98), width: 2)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final nuevaFecha = await showDatePicker(
                          context: context,
                          initialDate: fechaSeleccionada,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(primary: Color(0xFFE85E98)),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (nuevaFecha != null) {
                          setModalState(() => fechaSeleccionada = nuevaFecha);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Entrega pactada', style: TextStyle(color: Color(0xFF757575), fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  _formatearFecha(fechaSeleccionada),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF212121)),
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFFE85E98)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Observaciones
              TextField(
                controller: obsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observaciones / Notas',
                  labelStyle: TextStyle(color: Color(0xFF757575), fontSize: 13),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE85E98), width: 2)),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE85E98),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    setState(() {
                      _pedidoActual.cliente = clienteCtrl.text.trim();
                      _pedidoActual.monto = double.tryParse(montoCtrl.text) ?? _pedidoActual.monto;
                      _pedidoActual.observaciones = obsCtrl.text.trim();
                      _pedidoActual.fechaEntrega = fechaSeleccionada;
                    });
                    await context.read<FinanzasProvider>().actualizarPedido(_pedidoActual);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Guardar cambios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CONSTRUCCIÓN PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    final esPendiente = _pedidoActual.estado == 'pendiente';
    final esEntregado = _pedidoActual.estado == 'entregado';
    final esCancelado = _pedidoActual.estado == 'cancelado';

    // Colores de badges de estado
    final Color badgeBg = esPendiente
        ? const Color(0xFFE85E98)
        : esEntregado
            ? const Color(0xFFF48FB1)
            : const Color(0xFFEEEEEE);
    final Color badgeText = esCancelado ? const Color(0xFF757575) : Colors.white;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. CABECERA DESLIZABLE (SLIVER APP BAR)
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFFE85E98),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              if (esPendiente)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.black87, size: 18),
                      onPressed: _mostrarModalEdicion,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.black87, size: 18),
                    onPressed: _eliminarPedido,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _rutaImagen != null
                  ? Image.network(_rutaImagen, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFF0F5), Color(0xFFF8BBD0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 48,
                            color: Color(0xFFE85E98),
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // 2. FICHA TÉCNICA PRINCIPAL (TICKET)
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -28, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge de estado y Monto formateado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _pedidoActual.estado.toUpperCase(),
                          style: TextStyle(
                            color: badgeText,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        '\$${_formatearMonto(_pedidoActual.monto)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          color: esCancelado ? const Color(0xFF9E9E9E) : const Color(0xFF212121),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Nombre del Cliente
                  Text(
                    _pedidoActual.cliente.isNotEmpty
                        ? _pedidoActual.cliente[0].toUpperCase() + _pedidoActual.cliente.substring(1)
                        : 'Cliente',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),

                  // SECCIÓN: FICHA DEL ARTÍCULO
                  _encabezadoSeccion('FICHA DEL ARTÍCULO'),
                  _filaDato('Artículo', _pedidoActual.nombreItem),
                  _filaDato('Cantidad', '${_pedidoActual.cantidad} unidad(es)'),

                  // SECCIÓN: VARIANTE Y DETALLES
                  if (_pedidoActual.variante.isNotEmpty) ...[
                    _encabezadoSeccion('VARIANTE Y DETALLES'),
                    _filaDato('Variante elegida', _pedidoActual.variante),
                  ],

                  // SECCIÓN: FECHAS OPERATIVAS
                  _encabezadoSeccion('FECHAS OPERATIVAS'),
                  if (esEntregado && _pedidoActual.fechaEntregaReal != null)
                    _filaDato(
                      'Entregado el',
                      _formatearFecha(_pedidoActual.fechaEntregaReal!),
                      destacar: true,
                      colorValor: const Color(0xFF2E7D32),
                    ),
                  _filaDato(
                    'Entrega pactada',
                    _formatearFecha(_pedidoActual.fechaEntrega),
                    destacar: esPendiente,
                    colorValor: esPendiente ? const Color(0xFFE85E98) : null,
                  ),
                  _filaDato(
                    'Encargo registrado',
                    _pedidoActual.fechaRegistro != null
                        ? _formatearFecha(_pedidoActual.fechaRegistro!)
                        : 'Fecha no registrada',
                  ),

                  // SECCIÓN: OBSERVACIONES
                  if (_pedidoActual.observaciones.isNotEmpty) ...[
                    _encabezadoSeccion('OBSERVACIONES'),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _pedidoActual.observaciones,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF424242), height: 1.4),
                      ),
                    ),
                  ],

                  // AVISO DE CANCELACIÓN
                  if (esCancelado) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, size: 18, color: Color(0xFF757575)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este encargo fue cancelado. No afectó el stock ni la caja.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF757575), fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // 3. BOTONES DE ACCIÓN ANCLADOS EN LA BASE (SOLO PENDIENTE)
      bottomNavigationBar: esPendiente
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón principal
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE85E98),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _marcarComoEntregado,
                        icon: const Icon(Icons.check, color: Colors.white, size: 18),
                        label: const Text(
                          'Marcar como Entregado',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Botón secundario
                    TextButton(
                      onPressed: _cancelarPedido,
                      child: const Text(
                        'Cancelar Pedido',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}