import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:miemprendimiento/widgets/gasto_form.dart' as gasto_widget;
import 'package:miemprendimiento/widgets/pedido_form.dart' as pedido_widget;

import '../../models/movimiento_models.dart';
import '../../providers/finanzas_provider.dart';
import '../../widgets/tipo_movimiento_selector.dart';
import '../../widgets/venta_form.dart';
import 'historial_screen.dart';
import 'reporte_screen.dart';

/// Pantalla central de Finanzas con la navegación superior oficial de Figma:
/// [ Registrar | Historial | Reporte ]
///
/// Acepta [indiceInicial] y [tipoInicial] para poder abrirse directo en
/// una pestaña/tipo específico (ej. desde los botones de Home:
/// "Nueva Venta" -> Registrar + Venta, "Nuevo Pedido" -> Registrar + Pedido).
class FinanzasScreen extends StatefulWidget {
  final int indiceInicial;
  final TipoMovimiento tipoInicial;

  const FinanzasScreen({
    super.key,
    this.indiceInicial = 1, // por defecto, Historial (comportamiento previo)
    this.tipoInicial = TipoMovimiento.venta,
  });

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  // 0: Registrar, 1: Historial, 2: Reporte
  late int _indiceActivo = widget.indiceInicial;
  late TipoMovimiento _tipo = widget.tipoInicial;

  // Datos de prueba (reemplazar por Providers en producción)
  final List<Producto> _productos = [
    Producto(id: 'p1', nombre: 'Tiara Strass', precio: 4500),
    Producto(id: 'p2', nombre: 'Vaso Personalizado Glitter', precio: 3200),
    Producto(id: 'p3', nombre: 'Tutú de Tul', precio: 5800),
  ];
  final List<Combo> _combos = [
    Combo(id: 'c1', nombre: 'Combo Cumpleaños Premium', precio: 12500),
    Combo(id: 'c2', nombre: 'Pack Egresados', precio: 8000),
  ];
  final List<MaterialItem> _materiales = [
    MaterialItem(
      id: 'm1',
      nombre: 'Cinta de Raso 25mm',
      unidad: 'Metros',
      cantidad: 50,
      stockMinimo: 5,
    ),
    MaterialItem(
      id: 'm2',
      nombre: 'Gemas Strass',
      unidad: 'u',
      cantidad: 200,
      stockMinimo: 20,
    ),
    MaterialItem(
      id: 'm3',
      nombre: 'Tul',
      unidad: 'Metros',
      cantidad: 30,
      stockMinimo: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Lectura inicial de tablas SQLite al abrir Finanzas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FinanzasProvider>();
      provider.cargarVentas();
      provider.cargarGastos();
      provider.cargarPedidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'FINANZAS',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _pestanaSuperior('Registrar', 0),
                _pestanaSuperior('Historial', 1),
                _pestanaSuperior('Reporte', 2),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _indiceActivo,
        children: [
          SafeArea(
            child: Column(
              children: [
                TipoMovimientoSelector(
                  seleccionado: _tipo,
                  onChanged: (tipo) => setState(() => _tipo = tipo),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildFormulario(),
                  ),
                ),
              ],
            ),
          ),
          HistorialScreen(),
          ReporteScreen(),
        ],
      ),
    );
  }

  Widget _pestanaSuperior(String titulo, int indice) {
    final bool seleccionado = _indiceActivo == indice;

    return GestureDetector(
      onTap: () {
        setState(() {
          _indiceActivo = indice;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: seleccionado
                  ? const Color(0xFFE91E63)
                  : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          titulo,
          style: TextStyle(
            color: seleccionado ? Colors.black87 : Colors.black45,
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    switch (_tipo) {
      case TipoMovimiento.venta:
        return VentaForm(
          productos: _productos,
          combos: _combos,
          materiales: _materiales,
          variantesPorMaterial: _variantesPorMaterial(),
          onRegistrar: (venta, consumos) {
            // Sprint 4 - Paso 5: registrar venta con transacción (descuenta stock)
            _registrarVenta(venta, consumos);
          },
        );

      case TipoMovimiento.gasto:
        return gasto_widget.GastoForm(
          materiales: _materiales,
          variantesPorMaterial: _variantesPorMaterial(),

          onRegistrar: (gasto) {
            // Sprint 4 - Paso 6: registrar gasto con transacción (suma stock)
            _registrarGasto(gasto);
          },
        );

      case TipoMovimiento.pedido:
        return pedido_widget.PedidoForm(
          productos: _productos,
          combos: _combos,
          onRegistrar: (pedido) {
            // Sprint 4 - Paso 7: registrar pedido (NO descuenta stock todavía)
            _registrarPedido(pedido);
          },
        );
    }
  }

  Future<void> _registrarVenta(
    dynamic venta,
    List<MaterialConsumo> consumos,
  ) async {
    // Validar stock ANTES de abrir transacción (Sprint 4 - Paso 4)
    if (!hayStockSuficiente(consumos, _materiales)) {
      _mostrarAlerta('No hay stock, revisar materiales');
      return;
    }

    // Sprint 4 - Paso 5: db.transaction(...) con descuento de stock
    // await db.transaction((txn) async {
    //   await txn.insert('ventas', venta.toMap());
    //   for (final c in consumos) {
    //     await txn.rawUpdate(
    //       'UPDATE materiales SET cantidad = cantidad - ? WHERE id = ?',
    //       [c.cantidad, c.materialId],
    //     );
    //   }
    // });

    if (!mounted) return;
    _mostrarSnack('Venta registrada correctamente');
    Navigator.pop(context);
  }

  Future<void> _registrarGasto(dynamic gasto) async {
    // Sprint 4 - Paso 6: mismo patrón, sumando stock
    // await db.transaction((txn) async {
    //   await txn.insert('gastos', gasto.toMap());
    //   await txn.rawUpdate(
    //     'UPDATE materiales SET cantidad = cantidad + ? WHERE id = ?',
    //     [gasto.cantidad, gasto.materialId],
    //   );
    // });

    if (!mounted) return;
    _mostrarSnack('Gasto registrado correctamente');
    Navigator.pop(context);
  }

  Future<void> _registrarPedido(dynamic pedido) async {
    // Sprint 4 - Paso 7: pedido NO toca stock
    // await db.insert('pedidos', pedido.toMap());

    if (!mounted) return;
    _mostrarSnack('Pedido registrado (stock se descuenta al entregar)');
    Navigator.pop(context);
  }

  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aviso'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Simulación: en producción esto sale de InventarioProvider
  final Map<String, List<Variante>> _variantesPorMaterialMap = {
    'm1': [
      Variante(id: 'v1', materialId: 'm1', nombre: 'Rojo', cantidad: 12),
      Variante(id: 'v2', materialId: 'm1', nombre: 'Azul', cantidad: 30),
      Variante(id: 'v3', materialId: 'm1', nombre: 'Dorado', cantidad: 5),
    ],
    'm2': [
      Variante(id: 'v4', materialId: 'm2', nombre: 'Roja', cantidad: 200),
      Variante(
        id: 'v5',
        materialId: 'm2',
        nombre: 'Rosa Pastel',
        cantidad: 150,
      ),
    ],
    // 'm3' (Tul) no tiene variantes, por eso no aparece
  };

  Map<String, List<Variante>> _variantesPorMaterial() =>
      _variantesPorMaterialMap;

  void _mostrarSnack(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }
}