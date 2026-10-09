import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/movimiento_models.dart' as mov;
import '../../providers/finanzas_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../services/db_helper.dart';
import '../../widgets/tipo_movimiento_selector.dart';
import '../../widgets/venta_form.dart';
import '../../widgets/gasto_form.dart';
import '../../widgets/pedido_form.dart';
import 'historial_screen.dart';
import 'reporte_screen.dart';

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  int _indiceActivo = 1;
  mov.TipoMovimiento _tipo = mov.TipoMovimiento.venta;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inv = context.read<InventarioProvider>();
      inv.cargarMateriales();
      inv.cargarProductos();
      inv.cargarCombos();
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
          const HistorialScreen(),
          const ReporteScreen(),
        ],
      ),
    );
  }

  Widget _pestanaSuperior(String titulo, int indice) {
    final seleccionado = _indiceActivo == indice;
    return GestureDetector(
      onTap: () => setState(() => _indiceActivo = indice),
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
    final inv = context.watch<InventarioProvider>();

    final productos = inv.productos
        .map((p) => mov.Producto(id: p.id, nombre: p.nombre, precio: p.precio))
        .toList();

    final combos = inv.combos
        .map((c) => mov.Combo(id: c.id, nombre: c.nombre, precio: c.precio))
        .toList();

    final materiales = inv.materiales
        .map(
          (m) => mov.MaterialItem(
            id: m.id,
            nombre: m.nombre,
            unidad: m.unidad,
            cantidad: m.cantidad,
            stockMinimo: m.stockMinimo,
          ),
        )
        .toList();

    final variantesPorMaterial = {
      for (final entry in inv.variantes.entries)
        entry.key: entry.value
            .map(
              (v) => mov.Variante(
                id: v.id,
                materialId: v.materialId,
                nombre: v.nombre,
                cantidad: v.cantidad,
              ),
            )
            .toList(),
    };

    switch (_tipo) {
      case mov.TipoMovimiento.venta:
        return VentaForm(
          productos: productos,
          combos: combos,
          materiales: materiales,
          variantesPorMaterial: variantesPorMaterial,
          variantesRequeridasPorCombo: const {}, // podés generarlo desde inv
          onRegistrar: _registrarVenta,
        );

      case mov.TipoMovimiento.gasto:
        return GastoForm(
          materiales: materiales,
          variantesPorMaterial: variantesPorMaterial,
          onRegistrar: _registrarGasto,
        );

      case mov.TipoMovimiento.pedido:
        return PedidoForm(
          productos: productos,
          combos: combos,
          onRegistrar: _registrarPedido,
        );
    }
  }

  // ===========================================================================
  // REGISTRAR VENTA  →  descuenta stock + guarda en historial
  // ===========================================================================
  Future<void> _registrarVenta(
    dynamic venta,
    List<mov.MaterialConsumo> consumos,
  ) async {
    if (!hayStockSuficiente(consumos, _materialesComoMov())) {
      _mostrarAlerta('No hay stock suficiente, revisá los materiales.');
      return;
    }

    // 1. Descontar stock
    final inv = context.read<InventarioProvider>();
    for (final c in consumos) {
      await _ajustarStock(c.materialId, -c.cantidad);
    }
    await inv.cargarMateriales();

    // 2. Guardar la venta en SQLite
    await context.read<FinanzasProvider>().agregarVenta(venta);

    if (!mounted) return;
    _mostrarSnack('Venta registrada en el historial');
    // Salta al tab de Historial para que veas el resultado
    setState(() => _indiceActivo = 1);
  }

  // ===========================================================================
  // REGISTRAR GASTO  →  suma stock + guarda en historial
  // ===========================================================================
  Future<void> _registrarGasto(dynamic gasto) async {
    // 1. Sumar stock al material comprado
    if (gasto.materialId != null && gasto.cantidad > 0) {
      final inv = context.read<InventarioProvider>();
      await _ajustarStock(gasto.materialId!, gasto.cantidad);
      await inv.cargarMateriales();
    }

    // 2. Guardar el gasto en SQLite
    final finanzas = context.read<FinanzasProvider>();
    final provider = finanzas as dynamic;

    try {
      await provider.agregarGasto(gasto);
    } on NoSuchMethodError {
      try {
        await provider.guardarGasto(gasto);
      } on NoSuchMethodError {
        try {
          await provider.registrarGasto(gasto);
        } catch (_) {
          throw StateError(
            'FinanzasProvider no tiene un método para guardar gastos.',
          );
        }
      }
    }

    if (!mounted) return;
    _mostrarSnack('Gasto registrado en el historial');
    setState(() => _indiceActivo = 1);
  }

  // ===========================================================================
  // REGISTRAR PEDIDO  →  NO toca stock, guarda en historial
  // ===========================================================================
  Future<void> _registrarPedido(dynamic pedido) async {
    final finanzas = context.read<FinanzasProvider>();
    final provider = finanzas as dynamic;

    try {
      await provider.agregarPedido(pedido);
    } on NoSuchMethodError {
      try {
        await provider.guardarPedido(pedido);
      } on NoSuchMethodError {
        try {
          await provider.registrarPedido(pedido);
        } catch (_) {
          throw StateError(
            'FinanzasProvider no tiene un método para guardar pedidos.',
          );
        }
      }
    }

    if (!mounted) return;
    _mostrarSnack('Pedido registrado');
    setState(() => _indiceActivo = 1);
  }

  bool hayStockSuficiente(
    List<mov.MaterialConsumo> consumos,
    List<mov.MaterialItem> materiales,
  ) {
    final stockPorMaterial = {
      for (final material in materiales) material.id: material.cantidad,
    };

    for (final consumo in consumos) {
      final stockActual = stockPorMaterial[consumo.materialId] ?? 0;
      if (stockActual < consumo.cantidad) {
        return false;
      }
    }

    return true;
  }

  List<mov.MaterialItem> _materialesComoMov() {
    final inv = context.read<InventarioProvider>();
    return inv.materiales
        .map(
          (m) => mov.MaterialItem(
            id: m.id,
            nombre: m.nombre,
            unidad: m.unidad,
            cantidad: m.cantidad,
            stockMinimo: m.stockMinimo,
          ),
        )
        .toList();
  }

  Future<void> _ajustarStock(String materialId, double delta) async {
    final db = await DBHelper.instance.database;
    final res = await db.query(
      'materiales',
      where: 'id = ?',
      whereArgs: [materialId],
    );

    if (res.isEmpty) return;

    final cantidadActual = (res.first['cantidad'] as num?)?.toDouble() ?? 0;
    final nuevaCantidad = cantidadActual + delta;

    await db.update(
      'materiales',
      {'cantidad': nuevaCantidad},
      where: 'id = ?',
      whereArgs: [materialId],
    );
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

  void _mostrarSnack(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFE91E63),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
