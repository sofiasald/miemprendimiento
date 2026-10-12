//Este archivo unifica todas las transacciones de la base de datos local en una sola cronología, filtrable en tiempo real y conectada al flujo de pedidos
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finanzas_provider.dart';
import '../../models/pedido.dart';
import '../../models/venta.dart';
import '../../models/gasto.dart';
import 'detalle_pedido_screen.dart';
import 'detalle_movimiento_screen.dart';

/// Clase auxiliar para ordenar transacciones heterogéneas (Venta, Gasto, Pedido)
/// dentro de una misma lista cronológica.
class _ItemHistorial {
  final DateTime fechaReferencia;
  final Widget widget;

  _ItemHistorial({required this.fechaReferencia, required this.widget});
}

/// Pantalla definitiva de Historial de Finanzas.
/// Consume datos reales desde FinanzasProvider y refleja en vivo cualquier
/// alta, baja o cambio de estado proveniente de SQLite.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  // Filtro activo de categoría: 'Todo', 'Ventas', 'Gastos' o 'Pedidos'
  String _filtroActivo = 'Todo';

  // Controlador para el campo de búsqueda de movimientos
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _terminoBusqueda = '';

  @override
  void dispose() {
    // Liberación del controlador de texto para evitar fugas de memoria
    _controladorBusqueda.dispose();
    super.dispose();
  }

  /// Función utilitaria que da formato de moneda con punto de miles (Ej: 65000 -> 65.000).
  static String formatearMonto(double monto) {
    final partes = monto.toInt().toString();
    return partes.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Convierte una fecha a formato legible de encabezado (Ej: "12 DE SEPTIEMBRE 2026").
  static String formatearFechaEncabezado(DateTime fecha) {
    const meses = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    return '${fecha.day} DE ${meses[fecha.month - 1]} ${fecha.year}';
  }

  /// Parsea cadenas de fecha ISO8601 o texto estándar a DateTime de forma segura contra nulos.
  DateTime _parsearFecha(String? fechaTexto) {
    if (fechaTexto == null || fechaTexto.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(fechaTexto);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consumer escucha los cambios del provider; cualquier operación en la base redibuja la lista.
    return Consumer<FinanzasProvider>(
      builder: (context, finanzas, child) {
        // Construimos y ordenamos los movimientos reales
        final List<Widget> listaFinal = _construirListaUnificada(finanzas);

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFB),
          body: Column(
            children: [
              // BLOQUE 1: Input de búsqueda redondeado
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  controller: _controladorBusqueda,
                  onChanged: (val) => setState(
                    () => _terminoBusqueda = val.trim().toLowerCase(),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF757575),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF3F3F3),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // BLOQUE 2: Chips horizontales de filtrado por categoría
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _chipFiltro('Todo'),
                    const SizedBox(width: 8),
                    _chipFiltro('Ventas'),
                    const SizedBox(width: 8),
                    _chipFiltro('Gastos'),
                    const SizedBox(width: 8),
                    _chipFiltro('Pedidos'),
                  ],
                ),
              ),

              // BLOQUE 3: Lista de movimientos o Estado Vacío
              Expanded(
                child: listaFinal.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay movimientos registrados.',
                          style: TextStyle(color: Colors.black45, fontSize: 14),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: listaFinal,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construye cada botón de categoría horizontal.
  Widget _chipFiltro(String etiqueta) {
    final bool seleccionado = _filtroActivo == etiqueta;
    return GestureDetector(
      onTap: () => setState(() => _filtroActivo = etiqueta),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: seleccionado
              ? const Color(0xFFF06292)
              : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            color: seleccionado ? Colors.white : const Color(0xFF616161),
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Unifica y clasifica Ventas, Gastos y Pedidos respetando los filtros y agrupando por fecha.
  List<Widget> _construirListaUnificada(FinanzasProvider finanzas) {
    final List<_ItemHistorial> items = [];

    // 1. Procesar Pedidos Pendientes
    if (_filtroActivo == 'Todo' || _filtroActivo == 'Pedidos') {
      for (final pedido in finanzas.pedidos) {
        if (_terminoBusqueda.isEmpty ||
            pedido.cliente.toLowerCase().contains(_terminoBusqueda) ||
            pedido.nombreItem.toLowerCase().contains(_terminoBusqueda)) {
          items.add(
            _ItemHistorial(
              fechaReferencia: pedido.fechaEntrega,
              widget: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TarjetaPedido(pedido: pedido),
              ),
            ),
          );
        }
      }
    }

    // 2. Procesar Ventas
    if (_filtroActivo == 'Todo' || _filtroActivo == 'Ventas') {
      for (final venta in finanzas.ventas) {
        final nombreVenta = venta.nombreItem ?? 'Venta Directa';
        if (_terminoBusqueda.isEmpty ||
            nombreVenta.toLowerCase().contains(_terminoBusqueda)) {
          items.add(
            _ItemHistorial(
              fechaReferencia: _parsearFecha(venta.fecha),
              widget: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TarjetaVenta(venta: venta),
              ),
            ),
          );
        }
      }
    }

    // 3. Procesar Gastos
    if (_filtroActivo == 'Todo' || _filtroActivo == 'Gastos') {
      for (final gasto in finanzas.gastos) {
        final nombreGasto = gasto.materialNombre ?? 'Gasto de Insumo';
        if (_terminoBusqueda.isEmpty ||
            nombreGasto.toLowerCase().contains(_terminoBusqueda)) {
          items.add(
            _ItemHistorial(
              fechaReferencia: _parsearFecha(gasto.fecha),
              widget: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TarjetaGasto(gasto: gasto),
              ),
            ),
          );
        }
      }
    }

    // Ordenamiento descendente: las fechas más recientes aparecen primero
    items.sort((a, b) => b.fechaReferencia.compareTo(a.fechaReferencia));

    // Inserción de títulos de fecha entre tarjetas
    final List<Widget> widgetsConEncabezados = [];
    String? ultimaFechaClave;

    for (final item in items) {
      final fechaTexto = formatearFechaEncabezado(item.fechaReferencia);
      if (ultimaFechaClave != fechaTexto) {
        widgetsConEncabezados.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              fechaTexto,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF757575),
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
        ultimaFechaClave = fechaTexto;
      }
      widgetsConEncabezados.add(item.widget);
    }

    return widgetsConEncabezados;
  }
}

// COMPONENTE: Tarjeta Pedido con navegación al Detalle
class _TarjetaPedido extends StatelessWidget {
  final Pedido pedido;
  const _TarjetaPedido({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetallePedidoScreen(pedido: pedido),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 18,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PEDIDO   •   ${pedido.cliente}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${_HistorialScreenState.formatearMonto(pedido.monto)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pedido.nombreItem,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Fecha pactada: ${pedido.fechaEntrega.day.toString().padLeft(2, '0')}/${pedido.fechaEntrega.month.toString().padLeft(2, '0')}/${pedido.fechaEntrega.year}',
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF48FB1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Marcar Entregado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black87,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// COMPONENTE: Tarjeta Venta
// COMPONENTE: Tarjeta Venta
class _TarjetaVenta extends StatelessWidget {
  final Venta venta;
  const _TarjetaVenta({required this.venta});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalleMovimientoScreen.venta(venta: venta),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.black87,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VENTA',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      venta.nombreItem ?? 'Venta Directa',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      'Venta Directa',
                      style: TextStyle(color: Colors.black45, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '+\$${_HistorialScreenState.formatearMonto(venta.monto)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black87,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// COMPONENTE: Tarjeta Gasto
// COMPONENTE: Tarjeta Gasto
class _TarjetaGasto extends StatelessWidget {
  final Gasto gasto;
  const _TarjetaGasto({required this.gasto});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalleMovimientoScreen.gasto(gasto: gasto),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bookmark_border,
                  color: Colors.black87,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GASTO',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      gasto.materialNombre ?? 'Compra Insumo',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      'Compra Insumo',
                      style: TextStyle(color: Colors.black45, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '-\$${_HistorialScreenState.formatearMonto(gasto.monto)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.black87,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
