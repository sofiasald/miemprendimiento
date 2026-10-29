import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../utils/utils.dart';
import '../../models/venta.dart';
import '../../models/gasto.dart';
import '../../providers/finanzas_provider.dart';

/// Pantalla unificada de Detalle para Ventas y Gastos.
/// Adopta la arquitectura SliverAppBar con tarjeta superior curvada,
/// tirador de arrastre y formato de datos apilado con chips de variantes.
class DetalleMovimientoScreen extends StatelessWidget {
  final Venta? venta;
  final Gasto? gasto;

  // Ruta de fotografía del producto, combo o comprobante de gasto
  String? get _rutaImagen => venta?.fotoPath ?? gasto?.fotoPath;

  const DetalleMovimientoScreen.venta({super.key, required this.venta}) : gasto = null;
  const DetalleMovimientoScreen.gasto({super.key, required this.gasto}) : venta = null;


  // --- EXTRACCIÓN SEGURA DE METADATOS DE REGISTRO ---
  String? _leerPropiedad(dynamic objeto, List<String> claves) {
    if (objeto == null) return null;
    try {
      final map = objeto.toMap();
      if (map is Map) {
        for (final clave in claves) {
          if (map.containsKey(clave) && map[clave] != null && map[clave].toString().trim().isNotEmpty) {
            return map[clave].toString().trim();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // --- COMPONENTES VISUALES APILADOS (ESTILO UALÁ / MP) ---
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
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  variante,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF37474F),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- ELIMINACIÓN SEGURA EN BASE DE DATOS ---
  Future<void> _eliminarTransaccion(BuildContext context, bool esVenta) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Eliminar ${esVenta ? "venta" : "gasto"}?',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Esta transacción se removerá permanentemente de los balances y reportes contables.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final bool esVenta = venta != null;
    final bool esPedido = esVenta && venta!.tipo == 'pedido';

    final String titulo = esVenta
        ? (venta!.nombreItem ?? (esPedido ? 'Pedido' : 'Venta directa'))
        : (gasto!.materialNombre ?? 'Compra insumo');
    final double monto = esVenta ? venta!.monto : gasto!.monto;
    final String fecha = esVenta ? venta!.fecha : gasto!.fecha;

    // Lectura de campos complementarios
    final dynamic entidad = esVenta ? venta : gasto;
    final String? varianteDetectada = _leerPropiedad(entidad, ['variante', 'varianteNombre', 'variantes', 'detalleVariante']);
    final String? cantidadDetectada = _leerPropiedad(entidad, ['cantidad', 'unidades', 'cantidadComprada']);
    final String? unidadDetectada = _leerPropiedad(entidad, ['unidad', 'unidadMedida', 'referenciaUnidad']);
    final String? notasDetectadas = _leerPropiedad(entidad, ['observaciones', 'notas', 'descripcion']);

    final Color colorAcento = esVenta ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final Color colorBadgeFondo = esVenta ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final List<Color> coloresGradiente = esVenta
        ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
        : [const Color(0xFFFFF3E0), const Color(0xFFFFCDD2)];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()
        ),
        slivers: [
          // 1. CABECERA DESLIZABLE (SLIVER APP BAR)
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: colorAcento,
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.black87, size: 18),
                    onPressed: () => _eliminarTransaccion(context, esVenta),
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: coloresGradiente,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            esVenta ? Icons.receipt_long_rounded : Icons.inventory_2_outlined,
                            size: 46,
                            color: colorAcento,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // 2. CUERPO DE LA TARJETA COMPROBANTE
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

                  // Badge y Cifra Monetaria
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: colorBadgeFondo, borderRadius: BorderRadius.circular(16)),
                        child: Text(
                          esVenta ? (esPedido ? 'PEDIDO ENTREGADO' : 'VENTA DIRECTA') : 'GASTO DE INSUMO',
                          style: TextStyle(
                            color: colorAcento,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        '${esVenta ? "+" : "-"}\$${AppUtils.formatearMonto(monto)}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: colorAcento,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Nombre principal único (sin repetir abajo)
                  Text(
                    titulo.isNotEmpty ? titulo[0].toUpperCase() + titulo.substring(1) : titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),

                  // Datos apilados a ancho completo
                  _bloqueDato('Fecha y hora', AppUtils.formatearFechaHora(fecha)),
                  _bloqueDato(
                    'Tipo de operación',
                    esVenta
                        ? (esPedido ? 'Entrega de pedido registrado' : 'Venta directa en mostrador')
                        : 'Compra y reposición de materiales',
                  ),

                  if (esVenta && venta!.cliente != null && venta!.cliente!.trim().isNotEmpty)
                    _bloqueDato('Cliente', venta!.cliente!.trim(), negrita: true),

                  // Pastillas de variantes si existen
                  if (varianteDetectada != null && varianteDetectada.isNotEmpty)
                    _construirChipsVariantes(varianteDetectada),

                  if (cantidadDetectada != null) ...[
                    Builder(
                      builder: (context) {
                        final cantNum = double.tryParse(cantidadDetectada);
                        final cantTexto = cantNum != null && cantNum == cantNum.toInt()
                            ? cantNum.toInt().toString()
                            : cantidadDetectada;
                        final unidadTexto = unidadDetectada ?? (esVenta ? 'unidad(es)' : 'unidades');
                        return _bloqueDato(
                          esVenta ? 'Cantidad vendida' : 'Cantidad adquirida',
                          '$cantTexto $unidadTexto',
                          negrita: true,
                        );
                      },
                    ),
                  ],

                  if (notasDetectadas != null)
                    _bloqueDato('Observaciones', notasDetectadas),

                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  const SizedBox(height: 10),

                  // Asiento contable inferior
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          esVenta ? Icons.check_circle_outline : Icons.receipt_outlined,
                          size: 18,
                          color: colorAcento,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            esVenta
                                ? 'Movimiento asentado en el balance y reporte general.'
                                : 'Gasto computado en costos operativos del taller.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}