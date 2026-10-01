//Este componente calcula las métricas reales del negocio desde SQLite agrupadas por mes y año. Si no existen registros en el mes seleccionado, la pantalla entra de forma nativa en el estado vacío
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finanzas_provider.dart';

/// Pantalla de Reportes Financieros para el usuario final.
/// Calcula balances en tiempo real desde SQLite y permite navegar entre meses
/// con la rueda interactiva de selección.
class ReporteScreen extends StatefulWidget {
  const ReporteScreen({super.key});

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  // Nombres de los meses para visualización y rueda
  static const List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  // Rango dinámico de años: desde 2 años atrás hasta el año corriente
  late final List<int> _aniosDisponibles;

  // Variables mutables (sin 'final') para que el setState de la rueda pueda cambiarlas
  late int _mesSeleccionado;
  late int _anioSeleccionado;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _mesSeleccionado = ahora.month;
    _anioSeleccionado = ahora.year;

    // Genera automáticamente los años [año actual - 2, año actual - 1, año actual]
    _aniosDisponibles = List.generate(4, (index) => ahora.year - 3 + index);
  }

  /// Formatea importes numéricos con punto de miles (Ej: 188800 -> 188.800).
  static String formatearMonto(double monto) {
    final partes = monto.toInt().toString();
    return partes.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Parsea la fecha almacenada en SQLite a DateTime de forma segura contra nulos.
  DateTime _obtenerFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(fecha);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// --------------------------------------------------------------------------
  /// MODAL: Rueda de selección interactiva de Mes y Año (Figma Atelier)
  /// --------------------------------------------------------------------------
  void _mostrarRuedaMesAno() {
    int mesTemporal = _mesSeleccionado;
    int anioTemporal = _anioSeleccionado;

    final controllerMes = FixedExtentScrollController(initialItem: _mesSeleccionado - 1);
    final controllerAnio = FixedExtentScrollController(
      initialItem: _aniosDisponibles.indexOf(_anioSeleccionado).clamp(0, _aniosDisponibles.length - 1),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tirador superior gris
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Encabezado y botón cerrar 'X'
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Elegí mes y año',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22, color: Colors.black54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ruedas de selección cilíndrica
            SizedBox(
              height: 150,
              child: Row(
                children: [
                  // Columna 1: Meses
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: controllerMes,
                      itemExtent: 40,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) => mesTemporal = index + 1,
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          if (index < 0 || index >= _meses.length) return null;
                          return Center(
                            child: Text(
                              _meses[index],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          );
                        },
                        childCount: _meses.length,
                      ),
                    ),
                  ),

                  // Columna 2: Años
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: controllerAnio,
                      itemExtent: 40,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) => anioTemporal = _aniosDisponibles[index],
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          if (index < 0 || index >= _aniosDisponibles.length) return null;
                          return Center(
                            child: Text(
                              _aniosDisponibles[index].toString(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          );
                        },
                        childCount: _aniosDisponibles.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Botón Confirmar
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE85E98),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    _mesSeleccionado = mesTemporal;
                    _anioSeleccionado = anioTemporal;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Confirmar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
    return Consumer<FinanzasProvider>(
      builder: (context, finanzas, child) {
        // Filtrado dinámico por el mes y año que eligió la usuaria en la rueda
        final ventasMes = finanzas.ventas.where((v) {
          final f = _obtenerFecha(v.fecha);
          return f.month == _mesSeleccionado && f.year == _anioSeleccionado;
        });

        final gastosMes = finanzas.gastos.where((g) {
          final f = _obtenerFecha(g.fecha);
          return f.month == _mesSeleccionado && f.year == _anioSeleccionado;
        });

        final double totalVentasMes = ventasMes.fold(0.0, (acc, v) => acc + v.monto);
        final double totalGastosMes = gastosMes.fold(0.0, (acc, g) => acc + g.monto);
        final double gananciaNetaMes = totalVentasMes - totalGastosMes;
        final bool esMesVacio = (totalVentasMes == 0 && totalGastosMes == 0);

        // Acumulado de todo el año seleccionado
        final ventasAnio = finanzas.ventas.where((v) => _obtenerFecha(v.fecha).year == _anioSeleccionado);
        final gastosAnio = finanzas.gastos.where((g) => _obtenerFecha(g.fecha).year == _anioSeleccionado);
        final double totalVentasAnio = ventasAnio.fold(0.0, (acc, v) => acc + v.monto);
        final double totalGastosAnio = gastosAnio.fold(0.0, (acc, g) => acc + g.monto);
        final double gananciaNetaAnual = totalVentasAnio - totalGastosAnio;
        final bool esAnioVacio = (totalVentasAnio == 0 && totalGastosAnio == 0);

        return Scaffold(
          backgroundColor: const Color(0xFFFDFDFD),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------------
                // SELECTOR CONECTADO: Al tocarlo abre la rueda interactiva
                // -------------------------------------------------------------
                GestureDetector(
                  onTap: _mostrarRuedaMesAno,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF48FB1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.black87, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_meses[_mesSeleccionado - 1]} $_anioSeleccionado',
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // BALANCE MENSUAL
                const Text(
                  'BALANCE MENSUAL',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF757575), letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD1DC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GANANCIA NETA DEL MES',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        esMesVacio ? '\$0' : '\$${formatearMonto(gananciaNetaMes)}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      const Text('Rentabilidad: Ventas - Gastos', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('VENTA TOTALES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 6),
                            Text(
                              esMesVacio ? '+\$ 0' : '+\$ ${formatearMonto(totalVentasMes)}',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('GASTOS TOTALES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 6),
                            Text(
                              esMesVacio ? '-\$ 0' : '-\$ ${formatearMonto(totalGastosMes)}',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ACUMULADO ANUAL
                const Text(
                  'ACUMULADO ANUAL',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF757575), letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD1DC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esAnioVacio
                            ? 'Ganancia Neta Anual: \$ 0'
                            : 'Ganancia Neta Anual: \$ ${formatearMonto(gananciaNetaAnual)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trending_up, color: Color(0xFFE91E63), size: 28),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ventas Totales', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  Text(
                                    esAnioVacio ? '+\$0' : '+\$${formatearMonto(totalVentasAnio)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.trending_down, color: Color(0xFFE91E63), size: 28),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Gastos Totales', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  Text(
                                    esAnioVacio ? '-\$0' : '-\$${formatearMonto(totalGastosAnio)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}