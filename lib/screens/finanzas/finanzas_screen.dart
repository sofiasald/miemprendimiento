import 'package:flutter/material.dart';
import 'package:miemprendimiento/widgets/gasto_form.dart' as gasto_widget;
import 'package:miemprendimiento/widgets/pedido_form.dart' as pedido_widget;

import '../../models/movimiento_models.dart';
import '../../widgets/tipo_movimiento_selector.dart';
import '../../widgets/venta_form.dart';
import '../../widgets/gasto_form.dart' hide PedidoForm;
import '../../widgets/pedido_form.dart' hide GastoForm;

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  TipoMovimiento _tipo = TipoMovimiento.venta;

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Título FINANZAS
            Container(
              height: 67,
              width: double.infinity,
              color: Colors.white,
              alignment: Alignment.center,
              child: const Text(
                'FINANZAS',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  letterSpacing: 0.05,
                  color: Color(0xFF212121),
                ),
              ),
            ),

            // Selector Venta / Gasto / Pedido (Sprint 4 - Paso 1)
            TipoMovimientoSelector(
              seleccionado: _tipo,
              onChanged: (t) => setState(() => _tipo = t),
            ),

            // Formulario correspondiente
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildFormulario(),
              ),
            ),
          ],
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
