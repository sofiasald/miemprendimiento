import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/venta.dart';
import '../../models/gasto.dart';
import '../../providers/finanzas_provider.dart';

/// Pantalla unificada de Detalle para Ventas y Gastos.
/// Adopta la arquitectura SliverAppBar con tarjeta superior curvada,
/// degradados suaves de respaldo y lectura integral de todos los campos de registro.
class DetalleMovimientoScreen extends StatelessWidget {
  final Venta? venta;
  final Gasto? gasto;

  // Ruta opcional de fotografía del producto, combo o comprobante de gasto
  final String? _rutaImagen = null;

  const DetalleMovimientoScreen.venta({super.key, required this.venta}) : gasto = null;
  const DetalleMovimientoScreen.gasto({super.key, required this.gasto}) : venta = null;

  // --- FORMATEADORES VISUALES ---
  static String _formatearMonto(double monto) {
    final partes = monto.toInt().toString();
    return partes.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  static String _formatearFechaLegible(String? fechaIso) {
    if (fechaIso == null || fechaIso.isEmpty) return 'Fecha no disponible';
    try {
      final dt = DateTime.parse(fechaIso);
      final dia = dt.day.toString().padLeft(2, '0');
      final mes = dt.month.toString().padLeft(2, '0');
      final hora = dt.hour.toString().padLeft(2, '0');
      final minutos = dt.minute.toString().padLeft(2, '0');
      return '$dia/$mes/${dt.year} • $hora:$minutos hs';
    } catch (_) {
      return fechaIso;
    }
  }

  // --- EXTRACCIÓN SEGURA DE METADATOS DE REGISTRO ---
  /// Lee propiedades complementarias (variante, cantidad, unidad) de forma segura
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

  // --- COMPONENTES VISUALES AUXILIARES ---
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

  @override
  Widget build(BuildContext context) {
    final bool esVenta = venta != null;
    final bool esPedido = esVenta && venta!.tipo == 'pedido';

    final String titulo = esVenta
        ? (venta!.nombreItem ?? (esPedido ? 'Pedido' : 'Venta directa'))
        : (gasto!.materialNombre ?? 'Compra insumo');
    final double monto = esVenta ? venta!.monto : gasto!.monto;
    final String fecha = esVenta ? venta!.fecha : gasto!.fecha;

    // Lectura de campos de registro adicionales
    final dynamic entidad = esVenta ? venta : gasto;
    final String? varianteDetectada = _leerPropiedad(entidad, ['variante', 'varianteNombre', 'variantes', 'detalleVariante']);
    final String? cantidadDetectada = _leerPropiedad(entidad, ['cantidad', 'unidades', 'cantidadComprada']);
    final String? unidadDetectada = _leerPropiedad(entidad, ['unidad', 'unidadMedida', 'referenciaUnidad']);
    final String? notasDetectadas = _leerPropiedad(entidad, ['observaciones', 'notas', 'descripcion']);

    // Paleta cromática según dominio (Venta en verdes suaves, Gasto en rosado-rojizo suave)
    final Color colorAcento = esVenta ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final Color colorBadgeFondo = esVenta ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final List<Color> coloresGradiente = esVenta
        ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
        : [const Color(0xFFFFF3E0), const Color(0xFFFFCDD2)];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. CABECERA DESLIZABLE (SLIVER APP BAR)
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
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
              background: _rutaImagen != null
                  ? Image.network(_rutaImagen, fit: BoxFit.cover)
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
              transform: Matrix4.translationValues(0, -28, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge y Cifra Monetaria
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorBadgeFondo,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          esVenta
                              ? (esPedido ? 'PEDIDO ENTREGADO' : 'VENTA DIRECTA')
                              : 'GASTO DE INSUMO',
                          style: TextStyle(
                            color: colorAcento,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        '${esVenta ? "+" : "-"}\$${_formatearMonto(monto)}',
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

                  // Título principal (Artículo vendido o Material adquirido)
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

                  // SECCIÓN: DETALLES DE LA OPERACIÓN
                  _encabezadoSeccion('DETALLES DE LA OPERACIÓN'),
                  _filaDato('Fecha y hora', _formatearFechaLegible(fecha)),
                  _filaDato(
                    'Tipo de movimiento',
                    esVenta
                        ? (esPedido ? 'Entrega de pedido registrado' : 'Venta de mostrador / directa')
                        : 'Compra y reposición de materiales',
                  ),
                  if (esVenta && venta!.cliente != null && venta!.cliente!.trim().isNotEmpty)
                    _filaDato('Cliente', venta!.cliente!.trim(), destacar: true),

                  // SECCIÓN ESPECÍFICA SEGÚN DOMINIO (VENTA O GASTO)
                  if (esVenta) ...[
                    _encabezadoSeccion('FICHA DEL ARTÍCULO VENDIDO'),
                    _filaDato('Producto / Combo', titulo),
                    if (varianteDetectada != null)
                      _filaDato('Variante elegida', varianteDetectada),
                    if (cantidadDetectada != null)
                      _filaDato('Cantidad vendida', '$cantidadDetectada unidad(es)'),
                  ] else ...[
                    _encabezadoSeccion('FICHA DEL INSUMO COMPRADO'),
                    _filaDato('Insumo', titulo),
                    if (varianteDetectada != null)
                      _filaDato('Variante de material', varianteDetectada),
                    if (cantidadDetectada != null)
                      _filaDato(
                        'Cantidad adquirida',
                        '$cantidadDetectada ${unidadDetectada ?? "unidades"}',
                        destacar: true,
                      ),
                  ],

                  // NOTAS ADICIONALES (SI EXISTIEREN)
                  if (notasDetectadas != null) ...[
                    _encabezadoSeccion('OBSERVACIONES'),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        notasDetectadas,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF424242), height: 1.4),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // AVISO CONTABLE INFERIOR
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
                                ? 'Movimiento asentado en el balance y reporte anual.'
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