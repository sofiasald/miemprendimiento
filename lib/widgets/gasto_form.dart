import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movimiento_models.dart';
import 'selector_simple.dart';

class GastoForm extends StatefulWidget {
  final List<MaterialItem> materiales;
  final Map<String, List<Variante>> variantesPorMaterial;
  final void Function(dynamic gasto) onRegistrar;

  const GastoForm({
    super.key,
    required this.materiales,
    required this.variantesPorMaterial,
    required this.onRegistrar,
  });

  @override
  State<GastoForm> createState() => _GastoFormState();
}

class _GastoFormState extends State<GastoForm> {
  MaterialItem? _materialSeleccionado;
  Variante? _varianteSeleccionada;
  DateTime _fecha = DateTime.now();

  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();

  @override
  void dispose() {
    _cantidadController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  List<Variante> get _variantesDelMaterial {
    if (_materialSeleccionado == null) return [];
    return widget.variantesPorMaterial[_materialSeleccionado!.id] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const _Label('Material / Insumo comprado *'),
        const SizedBox(height: 8),
        SelectorSimple<MaterialItem>(
          titulo: 'Seleccionar material . . .',
          seleccionadoLabel: _materialSeleccionado?.nombre,
          items: widget.materiales,
          labelBuilder: (m) =>
              '${m.nombre}  (Stock: ${m.cantidad} ${m.unidad})',
          onSeleccionado: (m) {
            setState(() {
              _materialSeleccionado = m;
              _varianteSeleccionada = null;
            });
          },
        ),

        if (_materialSeleccionado != null &&
            _variantesDelMaterial.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _Label('Variante de material'),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Variante>(
                  isExpanded: true,
                  hint: const Text(
                    'Seleccionar variante . . .',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF757575),
                    ),
                  ),
                  value: _varianteSeleccionada,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFFE85E98),
                  ),
                  items: _variantesDelMaterial.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Text(
                        '${v.nombre}  (Stock actual: ${v.cantidad})',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF212121),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _varianteSeleccionada = v),
                ),
              ),
            ),
          ),
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
                    const _Label('Cantidad comprada *'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _cantidadController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFF212121),
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: const TextStyle(color: Color(0xFF757575)),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Unidad (Referencia)'),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _materialSeleccionado?.unidad ?? '—',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Fecha de compra *'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fecha,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _fecha = picked);
                      },
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
                              DateFormat('dd/MM/yyyy').format(_fecha),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
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
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('Monto abonado (\$) *'),
                    const SizedBox(height: 8),
                    Container(
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
                              fontSize: 16,
                              color: Color(0xFF757575),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _montoController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
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
                    ),
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

  void _onRegistrarPressed() {
    if (_materialSeleccionado == null) {
      _snack('Seleccione un material');
      return;
    }
    final cantidad = double.tryParse(_cantidadController.text) ?? 0;
    final monto = double.tryParse(_montoController.text) ?? 0;

    if (cantidad <= 0) {
      _snack('Ingrese la cantidad comprada');
      return;
    }
    if (monto <= 0) {
      _snack('Ingrese el monto abonado');
      return;
    }

    final gasto = {
      'materialId': _materialSeleccionado!.id,
      'varianteId': _varianteSeleccionada?.id,
      'cantidad': cantidad,
      'unidad': _materialSeleccionado!.unidad,
      'monto': monto,
      'fecha': _fecha.toIso8601String(),
    };

    widget.onRegistrar(gasto);
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
