//Este archivo unifica todas las transacciones de la base de datos local en una sola cronología, filtrable en tiempo real y conectada al flujo de pedidos
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/finanzas_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/pedido.dart';
import '../../models/venta.dart';
import '../../models/gasto.dart';
import 'detalle_pedido_screen.dart';
import 'detalle_movimiento_screen.dart';

/// Clase auxiliar para ordenar transacciones heterogéneas dentro de la misma lista
class _ItemHistorial {
  final DateTime fechaReferencia;
  final Widget widget;

  _ItemHistorial({required this.fechaReferencia, required this.widget});
}

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  // ESTADO DE FILTROS Y CONTROLADORES
  String _filtroActivo = 'Todo';
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _terminoBusqueda = '';

  // Lista en memoria de búsquedas recientes (máximo 5 elementos)
  final List<String> _busquedasRecientes = [];

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  // MÉTODOS AUXILIARES DE BÚSQUEDAS RECIENTES
  /// Guarda un término de búsqueda al confirmar en el teclado (sin duplicados y máx 5)
  void _guardarBusquedaReciente(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;

    setState(() {
      _busquedasRecientes.removeWhere((item) => item.toLowerCase() == limpio.toLowerCase());
      _busquedasRecientes.insert(0, limpio); // Se agrega arriba de todo
      if (_busquedasRecientes.length > 5) {
        _busquedasRecientes.removeLast(); // Mantiene tope de 5
      }
    });
  }

  /// Limpia el campo de texto y restaura la vista completa
  void _limpiarBusqueda() {
    _controladorBusqueda.clear();
    setState(() {
      _terminoBusqueda = '';
    });
  }

  // FORMATEADORES VISUALES
  static String formatearMonto(double monto) {
    final partes = monto.toInt().toString();
    return partes.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  static String formatearFechaEncabezado(DateTime fecha) {
    const meses = [
      'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
      'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE',
    ];
    return '${fecha.day} DE ${meses[fecha.month - 1]} ${fecha.year}';
  }

  DateTime _parsearFecha(String? fechaTexto) {
    if (fechaTexto == null || fechaTexto.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(fechaTexto);
    } catch (_) {
      return DateTime.now();
    }
  }

  // CONSTRUCCIÓN DE LA PANTALLA PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Consumer<FinanzasProvider>(
      builder: (context, finanzas, child) {
        final List<Widget> listaFinal = _construirListaUnificada(finanzas);

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFB),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BLOQUE 1: BUSCADOR CON BOTÓN LIMPIAR ('X') Y GUARDADO AL ENVIAR
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  controller: _controladorBusqueda,
                  onChanged: (val) {
                    setState(() {
                      _terminoBusqueda = val.trim().toLowerCase();
                    });
                  },
                  onSubmitted: (val) {
                    _guardarBusquedaReciente(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por producto o cliente...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF757575),
                      size: 20,
                    ),
                    // Icono de X para limpiar texto en un toque
                    suffixIcon: _terminoBusqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF757575), size: 18),
                            onPressed: _limpiarBusqueda,
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF3F3F3),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // BLOQUE 2: BÚSQUEDAS RECIENTES (SOLO SI EXISTEN Y NO SE ESTÁ ESCRIBIENDO)
              if (_terminoBusqueda.isEmpty && _busquedasRecientes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Text(
                        'Recientes:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _busquedasRecientes.map((termino) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InputChip(
                                  label: Text(
                                    termino,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF212121),
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFFFFEBEE),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  // Al tocar el texto, busca
                                  onPressed: () {
                                    _controladorBusqueda.text = termino;
                                    setState(() {
                                      _terminoBusqueda = termino.toLowerCase();
                                    });
                                  },
                                  // Al tocar la crucecita, borra solo este chip
                                  deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF757575)),
                                  onDeleted: () {
                                    setState(() {
                                      _busquedasRecientes.remove(termino);
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Color(0xFF9E9E9E)),
                        tooltip: 'Limpiar recientes',
                        onPressed: () => setState(() => _busquedasRecientes.clear()),
                      ),
                    ],
                  ),
                ),

              // BLOQUE 3: CHIPS DE CATEGORÍA (TODO, VENTAS, GASTOS, PEDIDOS)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

              // BLOQUE 4: LISTA DINÁMICA DE MOVIMIENTOS O ESTADO VACÍO
              Expanded(
                child: listaFinal.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _terminoBusqueda.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.receipt_long_outlined,
                                size: 48,
                                color: Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _terminoBusqueda.isNotEmpty
                                    ? 'No se encontraron resultados para "$_terminoBusqueda"'
                                    : 'No hay movimientos registrados.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                              if (_terminoBusqueda.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: _limpiarBusqueda,
                                  child: const Text(
                                    'Limpiar búsqueda',
                                    style: TextStyle(
                                      color: Color(0xFFF06292),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: listaFinal,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // WIDGETS AUXILIARES Y FILTRADO
  Widget _chipFiltro(String etiqueta) {
    final bool seleccionado = _filtroActivo == etiqueta;
    return GestureDetector(
      onTap: () => setState(() => _filtroActivo = etiqueta),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFFF06292) : const Color(0xFFEEEEEE),
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

  List<Widget> _construirListaUnificada(FinanzasProvider finanzas) {
    final List<_ItemHistorial> items = [];

    // 1. Procesar Pedidos
    if (_filtroActivo == 'Todo' || _filtroActivo == 'Pedidos') {
      for (final pedido in finanzas.pedidos) {
        // En la pestaña "Todo" ocultamos los entregados porque ya aparecen en la sección de Ventas.
        // Pero si la usuaria toca la pestaña "Pedidos", debe poder ver su historial completo.
        if (_filtroActivo == 'Todo' && pedido.estado.toLowerCase() == 'entregado') continue;

        if (_terminoBusqueda.isEmpty ||
            pedido.cliente.toLowerCase().contains(_terminoBusqueda) ||
            pedido.nombreItem.toLowerCase().contains(_terminoBusqueda)) {
          items.add(
            _ItemHistorial(
              fechaReferencia: pedido.fechaEntregaReal ?? DateTime.now(),
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
        final esPedido = venta.tipo == 'pedido';
        final nombreVenta = venta.nombreItem ?? (esPedido ? 'Pedido' : 'Venta directa');
        final cliente = venta.cliente ?? '';

        if (_terminoBusqueda.isEmpty ||
            nombreVenta.toLowerCase().contains(_terminoBusqueda) ||
            cliente.toLowerCase().contains(_terminoBusqueda) ||
            (esPedido && 'pedido'.contains(_terminoBusqueda)) ||
            (!esPedido && 'venta directa'.contains(_terminoBusqueda))) {
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

    // Ordenamiento descendente (lo más nuevo arriba)
    items.sort((a, b) => b.fechaReferencia.compareTo(a.fechaReferencia));

    // Agrupación visual por encabezados de fecha
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

// COMPONENTES DE TARJETAS (PEDIDO, VENTA, GASTO)
class _TarjetaPedido extends StatelessWidget {
  final Pedido pedido;
  const _TarjetaPedido({required this.pedido});

  Future<void> _confirmarEntrega(BuildContext context) async {
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
          'El pedido de ${pedido.cliente} pasará a la lista de ventas, se registrará el ingreso por \$${_HistorialScreenState.formatearMonto(pedido.monto)} y se descontará el stock de insumos.',
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
              'Confirmar entrega',
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

    await provider.entregarPedido(
      pedido: pedido,
      inventarioProvider: inv,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pedido entregado con éxito! Se movió a la lista de ventas.'),
          backgroundColor: Color(0xFFE91E63),
        ),
      );
    }
  }

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
            // 1. FILA SUPERIOR: Ícono, Título (con límite de espacio) y Precio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bloque izquierdo flexible (Ícono + Título + Cliente)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_outlined, size: 18, color: Colors.black87),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pedido   •   ${pedido.cliente.isNotEmpty ? pedido.cliente[0].toUpperCase() + pedido.cliente.substring(1) : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Bloque derecho fijo (Precio y Flecha)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${_HistorialScreenState.formatearMonto(pedido.monto)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Colors.black87, size: 20),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),

            // 2. DETALLE INTERMEDIO: Producto y Fecha Pactada
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pedido.nombreItem,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fecha pactada: ${pedido.fechaEntrega.day.toString().padLeft(2, '0')}/${pedido.fechaEntrega.month.toString().padLeft(2, '0')}/${pedido.fechaEntrega.year}',
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. Estado: Botón de entrega si está pendiente, o badge gris/verde
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: pedido.estado.toLowerCase() == 'cancelado'
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Cancelado',
                        style: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : pedido.estado.toLowerCase() == 'entregado'
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Entregado',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () => _confirmarEntrega(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                                  'Marcar como entregado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaVenta extends StatelessWidget {
  final Venta venta;
  const _TarjetaVenta({required this.venta});

  @override
  Widget build(BuildContext context) {
    final bool esPedido = venta.tipo == 'pedido';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        // Si la venta provino de un pedido, buscamos el pedido original y abrimos su ticket completo
        if (esPedido && venta.pedidoId != null) {
          final finanzas = context.read<FinanzasProvider>();
          final coincidencias = finanzas.pedidos.where((p) => p.id == venta.pedidoId);
          if (coincidencias.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetallePedidoScreen(pedido: coincidencias.first),
              ),
            );
            return;
          }
        }

        // Si es una venta directa tradicional, abre su comprobante normal
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
                Icon(
                  esPedido ? Icons.assignment_turned_in_outlined : Icons.receipt_long_outlined,
                  color: Colors.black87,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Venta',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      venta.nombreItem ?? (esPedido ? 'Pedido' : 'Venta directa'),
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    Text(
                      esPedido ? 'Pedido' : 'Venta directa',
                      style: const TextStyle(color: Colors.black45, fontSize: 11),
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
                const Icon(Icons.chevron_right, color: Colors.black87, size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
                const Icon(Icons.bookmark_border, color: Colors.black87, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gasto',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      gasto.materialNombre ?? 'Compra Insumo',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
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
                const Icon(Icons.chevron_right, color: Colors.black87, size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}