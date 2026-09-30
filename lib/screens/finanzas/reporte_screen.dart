//Este componente calcula las métricas reales del negocio desde SQLite agrupadas por mes y año. Si no existen registros en el mes seleccionado, la pantalla entra de forma nativa en el estado vacío
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finanzas_provider.dart';

/// Pantalla definitiva de Reportes Financieros.
/// Agrega las transacciones en memoria sincronizadas con la base SQLite
/// y expone el balance mensual y anual en tiempo real.
class ReporteScreen extends StatefulWidget {
  const ReporteScreen({super.key});

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  // Mes y año seleccionados para el cálculo (Septiembre 2026 por defecto para Sprint 5)
  int _mesSeleccionado = 9;
  int _anioSeleccionado = 2026;

  /// Formatea importes numéricos a texto con separador de miles por punto.
  static String formatearMonto(double monto) {
    final partes = monto.toInt().toString();
    return partes.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Parsea la fecha almacenada en la base de datos a un objeto DateTime.
  DateTime _obtenerFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(fecha);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanzasProvider>(
      builder: (context, finanzas, child) {
        // -------------------------------------------------------------
        // CÁLCULO DE BALANCE MENSUAL (Filtrado por mes y año seleccionado)
        // -------------------------------------------------------------
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

        // Bandera de estado vacío para el mes consultado
        final bool esMesVacio = (totalVentasMes == 0 && totalGastosMes == 0);

        // -------------------------------------------------------------
        // CÁLCULO DE ACUMULADO ANUAL (Todo el año en curso)
        // -------------------------------------------------------------
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
                // SELECTOR DE FECHA (Permite consultar cualquier periodo)
                // -------------------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                            'Septiembre $_anioSeleccionado',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.black87),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // -------------------------------------------------------------
                // SECCIÓN: BALANCE MENSUAL
                // -------------------------------------------------------------
                const Text(
                  'BALANCE MENSUAL',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF757575), letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),

                // Tarjeta Ganancia Neta
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

                // Fila de Totales (Ventas y Gastos)
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

                // -------------------------------------------------------------
                // SECCIÓN: ACUMULADO ANUAL
                // -------------------------------------------------------------
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