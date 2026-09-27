import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../providers/finanzas_provider.dart';
import '../../models/venta.dart';
import '../../models/gasto.dart';
import '../../models/material_consumo.dart';
import '../../models/producto.dart';
import '../../models/combo.dart';
import '../../models/material.dart';
import '../inventario/nuevo_producto_screen.dart' show SeleccionarMaterialModal;
import 'seleccionar_producto_combo_modal.dart';

class NuevoMovimientoScreen extends StatefulWidget {
  const NuevoMovimientoScreen({super.key});

  @override
  State<NuevoMovimientoScreen> createState() => _NuevoMovimientoScreenState();
}

/// Auxiliar interno: cuánto hay que descontar de un material en total,
/// sumando todas las veces que aparece (ej: el mismo material dentro de
/// dos productos distintos de un mismo combo).
class _ConsumoRequerido {
  final String materialId;
  final String materialNombre;
  double cantidad;

  _ConsumoRequerido({
    required this.materialId,
    required this.materialNombre,
    required this.cantidad,
  });
}

class _NuevoMovimientoScreenState extends State<NuevoMovimientoScreen> {
  TipoMovimiento _tipo = TipoMovimiento.venta;

  // --- Venta ---
  dynamic _itemSeleccionado; // Producto o Combo
  String? _itemTipo; // 'producto' | 'combo'
  final _montoVentaCtrl = TextEditingController();
  final Map<String, String> _variantesSeleccionadas = {}; // materialId -> varianteId

  // --- Gasto ---
  MaterialItem? _materialSeleccionado;
  String? _varianteGastoId;
  final _cantidadGastoCtrl = TextEditingController();
  final _montoGastoCtrl = TextEditingController();

  bool _guardando = false;

  @override
  void dispose() {
    _montoVentaCtrl.dispose();
    _cantidadGastoCtrl.dispose();
    _montoGastoCtrl.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Paso 1 y 2: elegir Producto/Combo y autocompletar precio
  // -----------------------------------------------------------------------

  Future<void> _elegirItemVenta() async {
    final resultado = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SeleccionarProductoComboModal(),
    );
    if (resultado == null) return;

    setState(() {
      _itemSeleccionado = resultado;
      _itemTipo = resultado is Producto ? 'producto' : 'combo';
      _variantesSeleccionadas.clear();
      final precio = resultado is Producto ? resultado.precio : (resultado as Combo).precio;
      _montoVentaCtrl.text = precio.toStringAsFixed(0);
    });
  }

  /// Paso 3 (parte 1): calcula cuánto se necesita de cada material,
  /// sumando repetidos y "desarmando" los productos dentro de un combo.
  /// Ignora insumos referenciales (cantidad == null, no descuentan stock).
  List<_ConsumoRequerido> _calcularConsumosBase(InventarioProvider inventario) {
    final Map<String, _ConsumoRequerido> acumulado = {};

    void agregar(String materialId, String nombre, double? cantidad) {
      if (cantidad == null) return;
      final existente = acumulado[materialId];
      if (existente != null) {
        existente.cantidad += cantidad;
      } else {
        acumulado[materialId] = _ConsumoRequerido(materialId: materialId, materialNombre: nombre, cantidad: cantidad);
      }
    }

    if (_itemTipo == 'producto') {
      final insumos = inventario.insumosProductos[_itemSeleccionado.id] ?? [];
      for (final i in insumos) {
        agregar(i.materialId, i.materialNombre, i.cantidad);
      }
    } else if (_itemTipo == 'combo') {
      final items = inventario.itemsPorCombo[_itemSeleccionado.id] ?? [];
      for (final item in items) {
        if (item.tipo == 'material') {
          agregar(item.elementoId, item.nombre, item.cantidad);
        } else {
          // item.tipo == 'producto': lo desarmamos en sus propios insumos,
          // multiplicando por la cantidad de ese producto dentro del combo.
          final multiplicador = item.cantidad ?? 1;
          final insumos = inventario.insumosProductos[item.elementoId] ?? [];
          for (final i in insumos) {
            if (i.cantidad == null) continue;
            agregar(i.materialId, i.materialNombre, i.cantidad! * multiplicador);
          }
        }
      }
    }

    return acumulado.values.toList();
  }

  // -----------------------------------------------------------------------
  // Gasto: elegir material (reutiliza el modal que ya existe en Inventario)
  // -----------------------------------------------------------------------

  Future<void> _elegirMaterialGasto() async {
    final resultado = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SeleccionarMaterialModal(materialesActuales: []),
    );
    if (resultado == null || resultado is! MaterialItem) return;

    setState(() {
      _materialSeleccionado = resultado;
      _varianteGastoId = null;
    });
  }

  // -----------------------------------------------------------------------
  // Guardar
  // -----------------------------------------------------------------------

  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Atención', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: Color(0xFFEC6294), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    final inventario = context.read<InventarioProvider>();
    final finanzas = context.read<FinanzasProvider>();

    if (_tipo == TipoMovimiento.venta) {
      await _guardarVenta(inventario, finanzas);
    } else {
      await _guardarGasto(inventario, finanzas);
    }
  }

  Future<void> _guardarVenta(InventarioProvider inventario, FinanzasProvider finanzas) async {
    if (_itemSeleccionado == null) {
      _mostrarAlerta('Elegí qué producto o combo vendiste.');
      return;
    }
    final monto = double.tryParse(_montoVentaCtrl.text.trim());
    if (monto == null || monto <= 0) {
      _mostrarAlerta('Ingresá un monto de venta válido.');
      return;
    }

    final consumosBase = _calcularConsumosBase(inventario);

    // Resolvemos a qué variante concreta se le descuenta cada material
    final List<MaterialConsumo> consumos = [];
    for (final c in consumosBase) {
      final variantes = inventario.variantes[c.materialId] ?? [];
      if (variantes.isNotEmpty) {
        final varianteId = _variantesSeleccionadas[c.materialId];
        if (varianteId == null) {
          _mostrarAlerta('Elegí qué variante de "${c.materialNombre}" se usó.');
          return;
        }
        final variante = variantes.firstWhere((v) => v.id == varianteId);
        consumos.add(MaterialConsumo(
          materialId: c.materialId,
          materialNombre: c.materialNombre,
          varianteId: variante.id,
          varianteNombre: variante.nombre,
          cantidad: c.cantidad,
        ));
      } else {
        consumos.add(MaterialConsumo(materialId: c.materialId, materialNombre: c.materialNombre, cantidad: c.cantidad));
      }
    }

    // Paso 4: validar stock ANTES de abrir la transacción
    final faltantes = finanzas.validarStock(consumos, inventario.materiales, inventario.variantes);
    if (faltantes.isNotEmpty) {
      final nombres = faltantes
          .map((f) => f.varianteNombre != null ? '${f.materialNombre} (${f.varianteNombre})' : f.materialNombre)
          .join(', ');
      _mostrarAlerta('No hay stock suficiente de: $nombres.');
      return;
    }

    setState(() => _guardando = true);

    final venta = Venta(
      productoId: _itemTipo == 'producto' ? _itemSeleccionado.id as String : null,
      comboId: _itemTipo == 'combo' ? _itemSeleccionado.id as String : null,
      nombreItem: _itemSeleccionado.nombre as String,
      monto: monto,
    );

    // Paso 5: registrar venta dentro de una transacción que descuenta stock
    await finanzas.registrarVenta(venta, consumos);
    await inventario.cargarMateriales(); // refresca el stock que se ve en Inventario

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _guardarGasto(InventarioProvider inventario, FinanzasProvider finanzas) async {
    if (_materialSeleccionado == null) {
      _mostrarAlerta('Elegí qué material compraste.');
      return;
    }
    final variantesDelMaterial = inventario.variantes[_materialSeleccionado!.id] ?? [];
    if (variantesDelMaterial.isNotEmpty && _varianteGastoId == null) {
      _mostrarAlerta('Elegí a qué variante le sumás stock.');
      return;
    }

    final cantidad = double.tryParse(_cantidadGastoCtrl.text.trim());
    final monto = double.tryParse(_montoGastoCtrl.text.trim());
    if (cantidad == null || cantidad <= 0) {
      _mostrarAlerta('Ingresá una cantidad válida.');
      return;
    }
    if (monto == null || monto <= 0) {
      _mostrarAlerta('Ingresá un monto de gasto válido.');
      return;
    }

    setState(() => _guardando = true);

    String? varianteNombre;
    if (_varianteGastoId != null) {
      varianteNombre = variantesDelMaterial.firstWhere((v) => v.id == _varianteGastoId).nombre;
    }

    final gasto = Gasto(
      materialId: _materialSeleccionado!.id,
      materialNombre: _materialSeleccionado!.nombre,
      varianteId: _varianteGastoId,
      varianteNombre: varianteNombre,
      cantidad: cantidad,
      monto: monto,
    );

    // Paso 6: registrar gasto (mismo patrón que la venta, pero sumando stock)
    await finanzas.registrarGasto(gasto);
    await inventario.cargarMateriales();

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // -----------------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final inventario = context.watch<InventarioProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back_ios, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Text('Nuevo movimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Paso 1: selector de tipo
                    SegmentedButton<TipoMovimiento>(
                      segments: const [
                        ButtonSegment(value: TipoMovimiento.venta, label: Text('Venta'), icon: Icon(Icons.point_of_sale)),
                        ButtonSegment(value: TipoMovimiento.gasto, label: Text('Gasto'), icon: Icon(Icons.shopping_cart)),
                      ],
                      selected: {_tipo},
                      onSelectionChanged: (nuevo) {
                        setState(() {
                          _tipo = nuevo.first;
                          _itemSeleccionado = null;
                          _itemTipo = null;
                          _variantesSeleccionadas.clear();
                          _materialSeleccionado = null;
                          _varianteGastoId = null;
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: const Color(0xFFEC6294),
                        selectedForegroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 25),

                    if (_tipo == TipoMovimiento.venta) ..._buildFormularioVenta(inventario) else ..._buildFormularioGasto(inventario),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _guardando ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Color(0xFFEC6294)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: Color(0xFFEC6294), fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: const Color(0xFFEC6294),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _guardando
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFormularioVenta(InventarioProvider inventario) {
    final consumosBase = _itemSeleccionado != null ? _calcularConsumosBase(inventario) : <_ConsumoRequerido>[];

    return [
      const Text('Producto o combo vendido *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
      const SizedBox(height: 5),
      GestureDetector(
        onTap: _elegirItemVenta,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _itemSeleccionado?.nombre ?? 'Tocá para elegir...',
                style: TextStyle(color: _itemSeleccionado == null ? Colors.black38 : Colors.black87, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Text('Monto de la venta (\$) *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
      const SizedBox(height: 5),
      _buildTextField(_montoVentaCtrl, 'Ej. 4500', isNumber: true),
      if (consumosBase.isNotEmpty) ...[
        const SizedBox(height: 25),
        const Text('MATERIALES QUE SE VAN A DESCONTAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 10),
        ...consumosBase.map((c) => _buildFilaConsumo(inventario, c)),
      ],
    ];
  }

  Widget _buildFilaConsumo(InventarioProvider inventario, _ConsumoRequerido c) {
    final variantes = inventario.variantes[c.materialId] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(
            children: [
              TextSpan(text: c.materialNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: '  ·  ${c.cantidad.toStringAsFixed(0)} a descontar', style: const TextStyle(color: Colors.black54)),
            ],
          )),
          if (variantes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('¿De qué variante?', style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 5),
            DropdownButtonFormField<String>(
              value: _variantesSeleccionadas[c.materialId],
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF2F2F2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              hint: const Text('Elegir variante'),
              items: variantes.map((v) => DropdownMenuItem(value: v.id, child: Text('${v.nombre} (stock: ${v.cantidad.toStringAsFixed(0)})'))).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() => _variantesSeleccionadas[c.materialId] = val);
              },
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFormularioGasto(InventarioProvider inventario) {
    final variantes = _materialSeleccionado != null ? (inventario.variantes[_materialSeleccionado!.id] ?? []) : [];

    return [
      const Text('Material comprado *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
      const SizedBox(height: 5),
      GestureDetector(
        onTap: _elegirMaterialGasto,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _materialSeleccionado?.nombre ?? 'Tocá para elegir...',
                style: TextStyle(color: _materialSeleccionado == null ? Colors.black38 : Colors.black87, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
      if (variantes.isNotEmpty) ...[
        const SizedBox(height: 15),
        const Text('¿A qué variante le sumás stock? *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: _varianteGastoId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
          ),
          hint: const Text('Elegir variante'),
          items: variantes.map((v) => DropdownMenuItem(value: v.id, child: Text(v.nombre))).toList(),
          onChanged: (val) => setState(() => _varianteGastoId = val),
        ),
      ],
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cantidad que ingresa *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 5),
                _buildTextField(_cantidadGastoCtrl, 'Ej. 100', isNumber: true),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monto gastado (\$) *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 5),
                _buildTextField(_montoGastoCtrl, 'Ej. 8000', isNumber: true),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
      ),
    );
  }
}