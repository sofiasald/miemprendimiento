import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/movimiento_models.dart' as mov;
import '../../providers/finanzas_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../widgets/tipo_movimiento_selector.dart';
import '../../widgets/venta_form.dart';
import '../../widgets/gasto_form.dart';
import '../../widgets/pedido_form.dart';
import '../../models/venta.dart';
import '../../models/gasto.dart';
import '../../models/pedido.dart';
import 'historial_screen.dart';
import 'reporte_screen.dart';

class FinanzasScreen extends StatefulWidget {
  final mov.TipoMovimiento tipoInicial;

  const FinanzasScreen({
    super.key,
    this.tipoInicial = mov.TipoMovimiento.pedido,
  });

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  int _indiceActivo = 0;
  int _versionHistorial = 0;
  late mov.TipoMovimiento _tipo;

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final inv = context.read<InventarioProvider>();
      inv.cargarMateriales();
      inv.cargarProductos();
      inv.cargarCombos();
      final fin = context.read<FinanzasProvider>();
      fin.cargarTodo();
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
          HistorialScreen(key: ValueKey(_versionHistorial)),
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
          variantesRequeridasPorCombo: const {},
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
  // REGISTRAR VENTA  →  descuenta stock de insumos + guarda en historial
  // ===========================================================================
  Future<void> _registrarVenta(
    dynamic venta,
    dynamic variantesElegidas,
  ) async {
    final finanzas = context.read<FinanzasProvider>();
    final inv = context.read<InventarioProvider>();

    try {
      if (venta is Venta) {
        Map<String, String>? mapa;
        if (variantesElegidas is Map<String, String>) {
          mapa = variantesElegidas;
        } else if (variantesElegidas is Map) {
          mapa = variantesElegidas.map((k, v) => MapEntry(k.toString(), v.toString()));
        }

        // Descontar stock de materiales en unidades enteras con la variante específica
        await inv.descontarStockPorVentaOPedido(
          productoId: venta.productoId,
          comboId: venta.comboId,
          nombreItem: venta.nombreItem,
          variantesElegidas: mapa,
          unidades: 1,
        );
        await finanzas.agregarVenta(venta);
      } else {
        await (finanzas as dynamic).agregarVenta(venta);
      }

      if (!mounted) return;
      _mostrarSnack('Venta registrada en el historial');
      setState(() {
        _indiceActivo = 1;
        _versionHistorial++;
      });
    } catch (e, stack) {
      debugPrint('Error al registrar venta: $e\n$stack');
      if (!mounted) return;
      _mostrarAlerta('No se pudo registrar la venta.');
    }
  }

  // ===========================================================================
  // REGISTRAR GASTO  →  suma stock + guarda en historial
  // ===========================================================================
  Future<void> _registrarGasto(dynamic gasto) async {
    try {
      final finanzas = context.read<FinanzasProvider>();
      final inv = context.read<InventarioProvider>();

      if (gasto is Gasto) {
        await finanzas.registrarGasto(gasto);
      } else {
        await (finanzas as dynamic).registrarGasto(gasto);
      }
      await inv.cargarMateriales();

      if (!mounted) return;
      _mostrarSnack('Gasto registrado en el historial');
      setState(() {
        _indiceActivo = 1;
        _versionHistorial++;
      });
    } catch (e, stack) {
      debugPrint('Error al registrar gasto: $e\n$stack');
      if (!mounted) return;
      _mostrarAlerta('No se pudo registrar el gasto en el historial.');
    }
  }

  // ===========================================================================
  // REGISTRAR PEDIDO  →  NO toca stock, guarda en historial
  // ===========================================================================

  Future<void> _registrarPedido(dynamic pedido) async {
    try {
      final finanzas = context.read<FinanzasProvider>();
      if (pedido is Pedido) {
        await finanzas.registrarPedido(pedido);
      } else {
        await (finanzas as dynamic).registrarPedido(pedido);
      }

      if (!mounted) return;
      _mostrarSnack('Pedido registrado en el historial');
      setState(() {
        _indiceActivo = 1;
        _versionHistorial++;
      });
    } catch (e, stack) {
      debugPrint('Error al registrar pedido: $e\n$stack');
      if (!mounted) return;
      _mostrarAlerta('No se pudo registrar el pedido en el historial.');
    }
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
