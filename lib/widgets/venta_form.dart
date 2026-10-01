import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movimiento_models.dart';
import 'selector_articulo.dart';

class VentaForm extends StatefulWidget {
  final List<Producto> productos;
  final List<Combo> combos;
  final List<MaterialItem> materiales;
  final Map<String, List<Variante>> variantesPorMaterial;
  final void Function(dynamic venta, List<MaterialConsumo> consumos)
  onRegistrar;

  const VentaForm({
    super.key,
    required this.productos,
    required this.combos,
    required this.materiales,
    required this.variantesPorMaterial,
    required this.onRegistrar,
  });

  @override
  State<VentaForm> createState() => _VentaFormState();
}

class _VentaFormState extends State<VentaForm> {
  ArticuloItem? _itemSeleccionado;
  bool _esCombo = false;
  DateTime _fecha = DateTime.now();
  final TextEditingController _montoController = TextEditingController();

  final Map<String, String?> _varianteElegida = {};
  final Map<String, TextEditingController> _cantidadControllers = {};

  @override
  void dispose() {
    _montoController.dispose();
    for (final c in _cantidadControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _montoTotal => double.tryParse(_montoController.text) ?? 0;

  List<MaterialItem> get _materialesAsociados {
    if (_itemSeleccionado == null) return const [];
    return widget.materiales;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const _Label('Producto Vendido *'),
        const SizedBox(height: 8),
        SelectorArticulo(
          items: [
            ...widget.productos.map(
              (p) => ArticuloItem(id: p.id, nombre: p.nombre, precio: p.precio),
            ),
            ...widget.combos.map(
              (c) => ArticuloItem(id: c.id, nombre: c.nombre, precio: c.precio),
            ),
          ],
          seleccionadoId: _itemSeleccionado?.id,
          onSeleccionado: (item) {
            setState(() {
              _itemSeleccionado = item;
              _esCombo = widget.combos.any((c) => c.id == item.id);
              _montoController.text = item.precio.toStringAsFixed(0);
              _varianteElegida.clear();
              _cantidadControllers.clear();
              for (final m in _materialesAsociados) {
                _cantidadControllers[m.id] = TextEditingController();
              }
            });
          },
        ),

        if (_itemSeleccionado != null &&
            !_esCombo &&
            _materialesAsociados.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _Label('Variante de material:'),
          const SizedBox(height: 8),
          _buildVarianteProducto(),
        ],

        if (_itemSeleccionado != null && _esCombo) ...[
          const SizedBox(height: 20),
          _buildDetallesCombo(),
        ],

        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Fecha *'),
                    const SizedBox(height: 8),
                    _FechaBox(
                      fecha: _fecha,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fecha,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _fecha = picked);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Monto total (\$) *'),
                    const SizedBox(height: 8),
                    _MontoBox(controller: _montoController),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        _Botones(
          onCancelar: () => Navigator.pop(context),
          onRegistrar: _onRegistrarPressed,
        ),
      ],
    );
  }

  Widget _buildVarianteProducto() {
    final material = _materialesAsociados.first;
    final variantes = widget.variantesPorMaterial[material.id] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                variantes.isEmpty
                    ? '${material.nombre} (Stock: ${material.cantidad} ${material.unidad})'
                    : (_varianteElegida[material.id] == null
                          ? 'Seleccionar variante . . .'
                          : variantes
                                .firstWhere(
                                  (v) => v.id == _varianteElegida[material.id],
                                )
                                .nombre),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: _varianteElegida[material.id] == null
                      ? const Color(0xFF757575)
                      : const Color(0xFF212121),
                ),
              ),
            ),
            if (variantes.isNotEmpty)
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _varianteElegida[material.id],
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFFE85E98),
                  ),
                  items: variantes.map((v) {
                    return DropdownMenuItem(
                      value: v.id,
                      child: Text(
                        '${v.nombre}  (Stock: ${v.cantidad})',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setState(() => _varianteElegida[material.id] = v),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetallesCombo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEAEA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETALLES Y VARIANTES DEL COMBO',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
              color: Color(0xFF616161),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Incluye: ${_materialesAsociados.map((m) => m.nombre).join(' + ')}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          for (final material in _materialesAsociados) ...[
            _buildFilaCombo(material),
            if (material != _materialesAsociados.last)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildFilaCombo(MaterialItem material) {
    final variantes = widget.variantesPorMaterial[material.id] ?? [];
    final tieneVariantes = variantes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${material.nombre} *',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tieneVariantes
                      ? (_varianteElegida[material.id] == null
                            ? 'Seleccionar variante . . .'
                            : variantes
                                  .firstWhere(
                                    (v) =>
                                        v.id == _varianteElegida[material.id],
                                  )
                                  .nombre)
                      : '${material.nombre} (Stock: ${material.cantidad} ${material.unidad})',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: _varianteElegida[material.id] == null
                        ? const Color(0xFF757575)
                        : const Color(0xFF212121),
                  ),
                ),
              ),
              if (tieneVariantes)
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _varianteElegida[material.id],
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFFE85E98),
                    ),
                    items: variantes.map((v) {
                      return DropdownMenuItem(
                        value: v.id,
                        child: Text(
                          '${v.nombre}  (Stock: ${v.cantidad})',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _varianteElegida[material.id] = v),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _onRegistrarPressed() {
    if (_itemSeleccionado == null) {
      _snack('Seleccione un producto o combo');
      return;
    }
    if (_montoTotal <= 0) {
      _snack('Ingrese el monto total');
      return;
    }

    final consumos = <MaterialConsumo>[];
    for (final material in _materialesAsociados) {
      final cantText = _cantidadControllers[material.id]?.text ?? '';
      final cant = double.tryParse(cantText) ?? 0;
      if (cant <= 0) continue;

      consumos.add(MaterialConsumo(materialId: material.id, cantidad: cant));
    }

    if (!hayStockSuficiente(consumos, widget.materiales)) {
      _snack('No hay stock, revisar materiales');
      return;
    }

    final venta = {
      'tipo': _esCombo ? 'combo' : 'producto',
      'itemId': _itemSeleccionado!.id,
      'monto': _montoTotal,
      'fecha': _fecha.toIso8601String(),
    };

    widget.onRegistrar(venta, consumos);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        color: Color(0xFF757575),
      ),
    ),
  );
}

class _FechaBox extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onTap;
  const _FechaBox({required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(fecha),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF212121),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.calendar_today,
              size: 18,
              color: Color(0xFFE85E98),
            ),
          ],
        ),
      ),
    );
  }
}

class _MontoBox extends StatelessWidget {
  final TextEditingController controller;
  const _MontoBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text(
            '\$ ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              color: Color(0xFF757575),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Color(0xFF212121),
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(color: Color(0xFF757575)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Botones extends StatelessWidget {
  final VoidCallback onCancelar;
  final VoidCallback onRegistrar;
  const _Botones({required this.onCancelar, required this.onRegistrar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: onCancelar,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE85E98)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFFE85E98),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onRegistrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE85E98),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Registrar',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
