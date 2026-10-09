import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/movimiento_models.dart' as mov;
import '../../providers/finanzas_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../widgets/selector_articulo_acordeon.dart'; // 👈 para AtelierColors
import '../../widgets/tipo_movimiento_selector.dart';
import '../../widgets/venta_form.dart';
import '../../widgets/gasto_form.dart';
import '../../widgets/pedido_form.dart';
import 'historial_screen.dart';
import 'reporte_screen.dart';

extension InventarioProviderStock on InventarioProvider {
  Future<void> descontarStock(String materialId, num cantidad) async {
    final index = materiales.indexWhere((m) => m.id == materialId);
    if (index == -1) return;

    final material = materiales[index];
    material.cantidad = material.cantidad - cantidad.toDouble();
    (this as dynamic).notifyListeners();
  }

  Future<void> aumentarStock(String materialId, num cantidad) async {
    final index = materiales.indexWhere((m) => m.id == materialId);
    if (index == -1) return;

    final material = materiales[index];
    material.cantidad = material.cantidad + cantidad.toDouble();
    (this as dynamic).notifyListeners();
  }
}

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
      final fin = context.read<FinanzasProvider>();
      fin.cargarVentas();
      fin.cargarGastos();
      fin.cargarPedidos();
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
    final bool seleccionado = _indiceActivo == indice;
    return GestureDetector(
      onTap: () => setState(() => _indiceActivo = indice),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              // 👇 Unificado con AtelierColors.rosa (#E85E98)
              color: seleccionado ? AtelierColors.rosa : Colors.transparent,
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
    // Leemos del InventarioProvider REAL, no de listas hardcodeadas.
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

    // Variantes reales por material
    final Map<String, List<mov.Variante>> variantesPorMaterial = {
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

    // 👇 Variantes requeridas por combo (si tu provider las expone)
    // Si todavía no las tenés, dejalo así y el VentaForm usará {} por defecto.
    final Map<String, List<VarianteRequerida>> variantesReqPorCombo = {
      // Ejemplo:
      // 'combo_tiara': [
      //   VarianteRequerida(
      //     materialId: 'gemas',
      //     materialNombre: 'Gemas (para Tiara)',
      //     opciones: variantesPorMaterial['gemas'] ?? [],
      //   ),
      // ],
    };

    switch (_tipo) {
      case mov.TipoMovimiento.venta:
        return VentaForm(
          productos: productos,
          combos: combos,
          materiales: materiales,
          variantesPorMaterial: variantesPorMaterial,
          variantesRequeridasPorCombo: variantesReqPorCombo, // 👈
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

  bool hayStockSuficiente(
    List<mov.MaterialConsumo> consumos,
    List<mov.MaterialItem> materiales,
  ) {
    final stockPorId = <String, num>{
      for (final material in materiales) material.id: material.cantidad,
    };

    final consumosPorMaterial = <String, num>{};
    for (final consumo in consumos) {
      consumosPorMaterial.update(
        consumo.materialId,
        (valorActual) => valorActual + consumo.cantidad,
        ifAbsent: () => consumo.cantidad,
      );
    }

    for (final entrada in consumosPorMaterial.entries) {
      final disponible = stockPorId[entrada.key] ?? 0;
      if (entrada.value > disponible) {
        return false;
      }
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // PERSISTENCIA REAL: escribe en FinanzasProvider e InventarioProvider
  // ---------------------------------------------------------------------------

  Future<void> _registrarVenta(
    dynamic venta,
    List<mov.MaterialConsumo> consumos,
  ) async {
    // 1. Validar stock ANTES de tocar nada
    if (!hayStockSuficiente(consumos, _materialesComoMov())) {
      _mostrarAlerta('No hay stock suficiente, revisá los materiales.');
      return;
    }

    // 2. Descontar stock de cada material consumido
    final inv = context.read<InventarioProvider>();
    for (final c in consumos) {
      await inv.descontarStock(c.materialId, c.cantidad);
    }

    // 3. Registrar la venta
    final fin = context.read<FinanzasProvider>();
    // El provider y este screen usan dos modelos distintos de MaterialConsumo
    // (movimiento_models.dart vs material_consumo.dart). Lo convertimos de forma
    // dinámica para evitar el conflicto de tipos sin tocar la lógica de negocio.
    await fin.registrarVenta(venta, consumos as dynamic);

    if (!mounted) return;
    _mostrarSnack('Venta registrada correctamente');
  }

  Future<void> _registrarGasto(dynamic gasto) async {
    // 1. Sumar stock al material comprado (si aplica)
    if (gasto.materialId != null && gasto.cantidad > 0) {
      final inv = context.read<InventarioProvider>();
      await inv.aumentarStock(gasto.materialId!, gasto.cantidad);
    }

    // 2. Registrar el gasto
    final fin = context.read<FinanzasProvider>();
    await fin.registrarGasto(gasto);

    if (!mounted) return;
    _mostrarSnack('Gasto registrado correctamente');
  }

  Future<void> _registrarPedido(dynamic pedido) async {
    // El pedido NO toca stock hasta que se entregue
    final fin = context.read<FinanzasProvider>();
    await fin.registrarPedido(pedido);

    if (!mounted) return;
    _mostrarSnack('Pedido registrado (el stock se descuenta al entregar)');
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }
}
