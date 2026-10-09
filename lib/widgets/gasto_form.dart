import 'package:flutter/material.dart';

import '../models/movimiento_models.dart';
import '../models/gasto.dart';
import 'selector_articulo_acordeon.dart';

class GastoForm extends StatefulWidget {
  final List<MaterialItem> materiales;
  final Map<String, List<Variante>> variantesPorMaterial;
  final void Function(Gasto gasto) onRegistrar;

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
  String? _materialId;
  String? _varianteId;
  final _cantidadCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();

  bool _listaMaterialesAbierta = true;
  bool _listaVariantesAbierta = true;

  // 👇 Validación del formulario completo
  bool get _formularioCompleto {
    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    final cantidad = double.tryParse(_cantidadCtrl.text) ?? 0;
    return _materialId != null && cantidad > 0 && monto > 0;
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variantes = _materialId != null
        ? widget.variantesPorMaterial[_materialId!] ?? []
        : <Variante>[];
    final materialSel = widget.materiales.firstWhere(
      (m) => m.id == _materialId,
      orElse: () => MaterialItem(
        id: '',
        nombre: '',
        unidad: '',
        cantidad: 0,
        stockMinimo: 0,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Material / Insumo comprado ----
          const Text(
            'Material / Insumo comprado *',
            style: TextStyle(fontSize: 15, color: AtelierColors.grisTexto),
          ),
          const SizedBox(height: 8),

          _listadoMateriales(),

          // ---- Si el material tiene variantes, segundo listado ----
          if (variantes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Variante de ${materialSel.nombre}',
              style: const TextStyle(
                fontSize: 15,
                color: AtelierColors.grisTexto,
              ),
            ),
            const SizedBox(height: 8),
            _listadoVariantes(variantes),
          ],

          const SizedBox(height: 20),

          // ---- Cantidad + Unidad ----
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cantidad comprada *',
                      style: TextStyle(
                        fontSize: 14,
                        color: AtelierColors.grisTexto,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cantidadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('0'),
                      onChanged: (_) => setState(() {}), // 👈
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unidad (Referencia)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AtelierColors.grisTexto,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AtelierColors.grisBorde),
                      ),
                      child: Text(
                        materialSel.unidad.isEmpty ? '—' : materialSel.unidad,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AtelierColors.negroSuave,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---- Fecha + Monto ----
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha de compra *',
                      style: TextStyle(
                        fontSize: 15,
                        color: AtelierColors.grisTexto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AtelierColors.grisBorde),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _fechaHoy(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AtelierColors.negroSuave,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AtelierColors.rosa,
                          ),
                        ],
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
                    const Text(
                      'Monto abonado (\$) *',
                      style: TextStyle(
                        fontSize: 15,
                        color: AtelierColors.grisTexto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _montoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecorationMonto('\$ 0'),
                      onChanged: (_) => setState(() {}), // 👈
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: AtelierColors.rosa),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: AtelierColors.rosa,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    // 👇 Color dinámico
                    backgroundColor: _formularioCompleto
                        ? AtelierColors.rosa
                        : AtelierColors.rosaClaro,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // 👇 Habilitado solo si el form está completo
                  onPressed: _formularioCompleto ? _guardar : null,
                  child: const Text(
                    'Registrar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Listado plegable de materiales (acordeón simple).
  Widget _listadoMateriales() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AtelierColors.grisBorde),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(
              () => _listaMaterialesAbierta = !_listaMaterialesAbierta,
            ),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _materialId == null
                        ? 'Seleccionar material . . .'
                        : widget.materiales
                              .firstWhere((m) => m.id == _materialId)
                              .nombre,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _materialId == null
                          ? FontWeight.w500
                          : FontWeight.w600,
                      color: _materialId == null
                          ? AtelierColors.grisTexto
                          : AtelierColors.negroSuave,
                    ),
                  ),
                  Icon(
                    _listaMaterialesAbierta
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AtelierColors.rosa,
                  ),
                ],
              ),
            ),
          ),
          if (_listaMaterialesAbierta)
            ...widget.materiales.asMap().entries.map((e) {
              final m = e.value;
              final esUltimo = e.key == widget.materiales.length - 1;
              return Column(
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    color: _materialId == m.id
                        ? AtelierColors.rosaClaro.withValues(alpha: 0.25)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() {
                        _materialId = m.id;
                        _varianteId = null;
                        _listaMaterialesAbierta = false;
                      }),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m.nombre, style: const TextStyle(fontSize: 14)),
                          Text(
                            'Stock: ${m.cantidad.toStringAsFixed(0)} ${m.unidad}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AtelierColors.grisTexto,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!esUltimo)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CustomPaint(
                        size: const Size(double.infinity, 1),
                        painter: _DashedLinePainter(
                          color: AtelierColors.grisBorde,
                        ),
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  /// Listado plegable de variantes.
  Widget _listadoVariantes(List<Variante> variantes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AtelierColors.grisBorde),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(
              () => _listaVariantesAbierta = !_listaVariantesAbierta,
            ),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _varianteId == null
                        ? 'Seleccionar variante . . .'
                        : variantes
                              .firstWhere((v) => v.id == _varianteId)
                              .nombre,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _varianteId == null
                          ? FontWeight.w500
                          : FontWeight.w600,
                      color: _varianteId == null
                          ? AtelierColors.grisTexto
                          : AtelierColors.negroSuave,
                    ),
                  ),
                  Icon(
                    _listaVariantesAbierta
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AtelierColors.rosa,
                  ),
                ],
              ),
            ),
          ),
          if (_listaVariantesAbierta)
            ...variantes.asMap().entries.map((e) {
              final v = e.value;
              final esUltimo = e.key == variantes.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() {
                      _varianteId = v.id;
                      _listaVariantesAbierta = false;
                    }),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      color: _varianteId == v.id
                          ? AtelierColors.rosaClaro.withValues(alpha: 0.25)
                          : Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(v.nombre, style: const TextStyle(fontSize: 14)),
                          Text(
                            '(Stock disponible: ${v.cantidad.toStringAsFixed(0)})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AtelierColors.grisTexto,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!esUltimo)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CustomPaint(
                        size: const Size(double.infinity, 1),
                        painter: _DashedLinePainter(
                          color: AtelierColors.grisBorde,
                        ),
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AtelierColors.grisBorde),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AtelierColors.grisBorde),
    ),
  );

  InputDecoration _inputDecorationMonto(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AtelierColors.grisBorde),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AtelierColors.grisBorde),
    ),
  );

  String _fechaHoy() {
    final h = DateTime.now();
    return '${h.day.toString().padLeft(2, '0')}/${h.month.toString().padLeft(2, '0')}/${h.year}';
  }

  void _guardar() {
    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    if (_materialId == null || monto <= 0) return;

    final material = widget.materiales.firstWhere(
      (m) => m.id == _materialId,
      orElse: () => widget.materiales.first,
    );

    final gasto = Gasto(
      materialId: _materialId,
      materialNombre: material.nombre,
      varianteId: _varianteId,
      varianteNombre: _varianteId != null
          ? (widget.variantesPorMaterial[_materialId!] ?? [])
                .firstWhere((v) => v.id == _varianteId)
                .nombre
          : null,
      cantidad: double.tryParse(_cantidadCtrl.text) ?? 0,
      monto: monto,
    );

    widget.onRegistrar(gasto);
    setState(() {
      _materialId = null;
      _varianteId = null;
      _cantidadCtrl.clear();
      _montoCtrl.clear();
    });
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
