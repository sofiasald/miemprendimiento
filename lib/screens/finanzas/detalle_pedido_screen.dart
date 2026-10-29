import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../models/pedido.dart';
import '../../utils/utils.dart';
import '../../providers/finanzas_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../widgets/selector_foto.dart';

/// Pantalla de Detalle de Pedido.
/// Diseño homogéneo apilado (estilo Ualá/MP) con chips de variantes,
/// tirador de arrastre táctil y botones fijos inferiores.
class DetallePedidoScreen extends StatefulWidget {
  final Pedido pedido;
  const DetallePedidoScreen({super.key, required this.pedido});

  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  late Pedido _pedidoActual;
  String? get _rutaImagen => _pedidoActual.fotoPath;

  @override
  void initState() {
    super.initState();
    _pedidoActual = widget.pedido;
  }

  // --- COMPONENTES APILADOS A ANCHO COMPLETO ---
  Widget _bloqueDato(String etiqueta, String valor, {Color? colorValor, bool negrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              color: colorValor ?? const Color(0xFF212121),
              fontWeight: negrita ? FontWeight.w700 : FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirChipsVariantes(String variantesTexto) {
    final lista = variantesTexto.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VARIANTES ELEGIDAS',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lista.map((variante) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF8BBD0)),
                ),
                child: Text(
                  variante,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC2185B),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
        title: const Text('¿Confirmar entrega?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'El pedido pasará a ENTREGADO, se registrará la venta por \$${AppUtils.formatearMonto(_pedidoActual.monto)} y se descontará el stock de insumos.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE85E98),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar entrega', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmacion != true) return;

    await provider.entregarPedido(pedido: _pedidoActual, inventarioProvider: inv);

    if (mounted) setState(() => _pedidoActual.estado = 'entregado');

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
        title: const Text('¿Cancelar este pedido?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'El encargo pasará a estado CANCELADO. No se registrará ingreso ni se descontará stock.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, volver')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar pedido', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _pedidoActual.estado = 'cancelado');
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
        title: const Text('¿Eliminar registro?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Se eliminará este pedido del sistema permanentemente.', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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

  void _verImagenCompleta(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }

  // --- MODAL DE EDICIÓN LIMPIO ---
  void _mostrarModalEdicion() {
    final clienteCtrl = TextEditingController(text: _pedidoActual.cliente);
    final montoCtrl = TextEditingController(text: _pedidoActual.monto.toInt().toString());
    final obsCtrl = TextEditingController(text: _pedidoActual.observaciones);
    DateTime fechaSeleccionada = _pedidoActual.fechaEntrega;
    String? fotoSeleccionada = _pedidoActual.fotoPath;

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
                                  AppUtils.formatearFecha(fechaSeleccionada),
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

              // Selector para sumar o cambiar la foto desde el ticket
              SelectorFoto(
                rutaInicial: fotoSeleccionada,
                onFotoCambiada: (ruta) => setModalState(() => fotoSeleccionada = ruta),
              ),
              const SizedBox(height: 20),

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
                      _pedidoActual.fotoPath = fotoSeleccionada;
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

  @override
  Widget build(BuildContext context) {
    final esPendiente = _pedidoActual.estado == 'pendiente';
    final esEntregado = _pedidoActual.estado == 'entregado';
    final esCancelado = _pedidoActual.estado == 'cancelado';

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
            stretch: true,
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
              stretchModes: const [
                StretchMode.zoomBackground,
              ],
              background: (_rutaImagen != null && File(_rutaImagen!).existsSync())
                  ? GestureDetector(
                      onTap: () => _verImagenCompleta(context, _rutaImagen!),
                      child: Image.file(File(_rutaImagen!), fit: BoxFit.cover),
                    )
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

          // 2. FICHA TÉCNICA PRINCIPAL (TICKET ELEVADO)
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tirador táctil central
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Badge de estado y Monto
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(16)),
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
                        '\$${AppUtils.formatearMonto(_pedidoActual.monto)}',
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

                  // Nombre del Cliente destacado
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

                  // Datos apilados a ancho completo
                  _bloqueDato('Artículo encargado', _pedidoActual.nombreItem),
                  _bloqueDato('Cantidad encargada', '${_pedidoActual.cantidad} unidad(es)'),

                  // Variantes en pastillas / chips
                  if (_pedidoActual.variante.isNotEmpty)
                    _construirChipsVariantes(_pedidoActual.variante),

                  // Fechas operativas apiladas
                  if (esEntregado && _pedidoActual.fechaEntregaReal != null)
                    _bloqueDato(
                      'Entregado el',
                      AppUtils.formatearFecha(_pedidoActual.fechaEntregaReal!),
                      colorValor: const Color(0xFF2E7D32),
                      negrita: true,
                    ),

                  _bloqueDato(
                    'Entrega pactada',
                    AppUtils.formatearFecha(_pedidoActual.fechaEntrega),
                    colorValor: esPendiente ? const Color(0xFFE85E98) : null,
                    negrita: esPendiente,
                  ),

                  _bloqueDato(
                    'Encargo registrado',
                    _pedidoActual.fechaRegistro != null
                        ? AppUtils.formatearFecha(_pedidoActual.fechaRegistro!)
                        : 'Fecha no registrada',
                  ),

                  if (_pedidoActual.observaciones.isNotEmpty)
                    _bloqueDato('Observaciones', _pedidoActual.observaciones),

                  if (esCancelado) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Color(0xFF757575)),
                          SizedBox(width: 10),
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