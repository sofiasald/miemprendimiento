import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movimiento_models.dart' hide Variante;
import '../models/venta.dart';
import '../models/variante.dart';
import '../providers/inventario_provider.dart';
import 'selector_articulo_acordeon.dart';

class VentaForm extends StatefulWidget {
  final List<Producto> productos;
  final List<Combo> combos;
  final List<MaterialItem> materiales;
  final dynamic variantesPorMaterial;
  final void Function(Venta venta, Map<String, String> variantesElegidas) onRegistrar;

  const VentaForm({
    super.key,
    required this.productos,
    required this.combos,
    required this.materiales,
    this.variantesPorMaterial,
    required this.onRegistrar,
    Map<String, List<VarianteRequerida>>? variantesRequeridasPorCombo,
  });

  @override
  State<VentaForm> createState() => _VentaFormState();
}

class _VentaFormState extends State<VentaForm> {
  String _tipoActivo = 'producto'; // 'producto' | 'combo'

  String? _idSeleccionado;
  String _nombreItem = '';
  double _precio = 0;

  bool _listaAbierta = false;

  final Map<String, String?> _variantesElegidas = {};
  final Set<String> _listasVariantesAbiertas = {};

  late DateTime _fecha;
  final _montoCtrl = TextEditingController();

  // 👇 Validación del formulario completo
  bool get _formularioCompleto {
    if (_idSeleccionado == null) return false;

    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    if (monto <= 0) return false;

    final inv = context.read<InventarioProvider>();
    final reqs = inv.obtenerVariantesRequeridas(
      productoId: _tipoActivo == 'producto' ? _idSeleccionado : null,
      comboId: _tipoActivo == 'combo' ? _idSeleccionado : null,
    );
    for (final req in reqs) {
      if (_variantesElegidas[req.key] == null) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _fecha = DateTime.now();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsActivos = _tipoActivo == 'producto'
        ? widget.productos
              .map(
                (p) => _ItemLista(id: p.id, nombre: p.nombre, precio: p.precio),
              )
              .toList()
        : widget.combos
              .map(
                (c) => _ItemLista(id: c.id, nombre: c.nombre, precio: c.precio),
              )
              .toList();

    final inv = context.watch<InventarioProvider>();
    final variantesReq = _idSeleccionado != null
        ? inv.obtenerVariantesRequeridas(
            productoId: _tipoActivo == 'producto' ? _idSeleccionado : null,
            comboId: _tipoActivo == 'combo' ? _idSeleccionado : null,
          )
        : <VarianteRequerida>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tipoActivo == 'producto'
                ? 'Producto vendido *'
                : 'Combo vendido *',
            style: const TextStyle(
              fontSize: 15,
              color: AtelierColors.grisTexto,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _puntoYTexto(
                activo: _tipoActivo == 'producto',
                texto: 'Productos',
                onTap: () => setState(() {
                  _tipoActivo = 'producto';
                  _idSeleccionado = null;
                  _nombreItem = '';
                  _precio = 0;
                  _listaAbierta = false;
                  _variantesElegidas.clear();
                  _listasVariantesAbiertas.clear();
                  _montoCtrl.clear();
                }),
              ),
              const SizedBox(width: 24),
              _puntoYTexto(
                activo: _tipoActivo == 'combo',
                texto: 'Combos',
                onTap: () => setState(() {
                  _tipoActivo = 'combo';
                  _idSeleccionado = null;
                  _nombreItem = '';
                  _precio = 0;
                  _listaAbierta = false;
                  _variantesElegidas.clear();
                  _listasVariantesAbiertas.clear();
                  _montoCtrl.clear();
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _campoDesplegable(itemsActivos),

          if (variantesReq.isNotEmpty) ...[
            const SizedBox(height: 20),
            _seccionDetallesCombo(variantesReq),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha actual *',
                      style: TextStyle(
                        fontSize: 15,
                        color: AtelierColors.grisTexto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _campoFecha(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monto total (\$) *',
                      style: TextStyle(
                        fontSize: 15,
                        color: AtelierColors.grisTexto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _campoMonto(),
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
                    backgroundColor: _formularioCompleto
                        ? AtelierColors.rosa
                        : AtelierColors.rosaDeshabilitado,
                    disabledBackgroundColor: AtelierColors.rosaDeshabilitado,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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

  // ---------------------------------------------------------------------------
  // WIDGETS INTERNOS
  // ---------------------------------------------------------------------------

  Widget _puntoYTexto({
    required bool activo,
    required String texto,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: activo
                  ? AtelierColors.rosaSuave
                  : AtelierColors.rosaSuave.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: activo
                  ? AtelierColors.negroSuave
                  : AtelierColors.negroSuave.withValues(alpha: 0.61),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoDesplegable(List<_ItemLista> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _listaAbierta
              ? AtelierColors.negroSuave
              : AtelierColors.grisBorde,
          width: _listaAbierta ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(8),
          bottom: Radius.circular(_listaAbierta ? 0 : 8),
        ),
        boxShadow: _listaAbierta
            ? const [
                BoxShadow(
                  color: Color(0x40000008),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _listaAbierta = !_listaAbierta),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _idSeleccionado == null
                          ? 'Seleccionar ${_tipoActivo == 'producto' ? 'producto' : 'combo'} . . .'
                          : _nombreItem,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _idSeleccionado == null
                            ? FontWeight.w500
                            : FontWeight.w600,
                        color: _idSeleccionado == null
                            ? AtelierColors.grisTexto
                            : AtelierColors.negroSuave,
                      ),
                    ),
                  ),
                  Icon(
                    _listaAbierta
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AtelierColors.rosa,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (_listaAbierta)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: AtelierColors.grisBorde),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Column(
                children: items.asMap().entries.map((e) {
                  final item = e.value;
                  final esUltimo = e.key == items.length - 1;
                  final seleccionado = _idSeleccionado == item.id;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _idSeleccionado = item.id;
                            _nombreItem = item.nombre;
                            _precio = item.precio;
                            _listaAbierta = false;
                            _montoCtrl.text = item.precio.toInt().toString();
                            _variantesElegidas.clear();
                            _listasVariantesAbiertas.clear();
                          });
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          color: seleccionado
                              ? AtelierColors.rosaClaro.withValues(alpha: 0.25)
                              : Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.nombre,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AtelierColors.negroSuave,
                                  ),
                                ),
                              ),
                              Text(
                                '\$ ${_formatear(item.precio)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AtelierColors.negroSuave,
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
                              dashWidth: 4,
                              dashSpace: 4,
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _seccionDetallesCombo(List<VarianteRequerida> variantes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < variantes.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _selectorVariante(variantes[i]),
        ],
      ],
    );
  }

  Widget _selectorVariante(VarianteRequerida req) {
    final valorElegido = _variantesElegidas[req.key];
    final estaAbierta = _listasVariantesAbiertas.contains(req.key);
    final varianteSel = valorElegido != null
        ? req.opciones.where((v) => v.id == valorElegido).firstOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          req.etiqueta,
          style: const TextStyle(
            fontSize: 15,
            color: AtelierColors.grisTexto,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AtelierColors.grisBorde),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() {
                  if (estaAbierta) {
                    _listasVariantesAbiertas.remove(req.key);
                  } else {
                    _listasVariantesAbiertas.add(req.key);
                  }
                }),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        varianteSel == null
                            ? 'Seleccionar variante . . .'
                            : varianteSel.nombre,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: varianteSel == null
                              ? FontWeight.w500
                              : FontWeight.w600,
                          color: varianteSel == null
                              ? AtelierColors.grisTexto
                              : AtelierColors.negroSuave,
                        ),
                      ),
                      Icon(
                        estaAbierta
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AtelierColors.rosa,
                      ),
                    ],
                  ),
                ),
              ),
              if (estaAbierta)
                ...req.opciones.asMap().entries.map((e) {
                  final v = e.value;
                  final esUltimo = e.key == req.opciones.length - 1;
                  final seleccionado = valorElegido == v.id;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() {
                          _variantesElegidas[req.key] = v.id;
                          _listasVariantesAbiertas.remove(req.key);
                        }),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          color: seleccionado
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
        ),
      ],
    );
  }

  Widget _campoFecha() {
    return InkWell(
      onTap: _seleccionarFecha,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AtelierColors.grisBorde),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(
              _formatearFecha(_fecha),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AtelierColors.negroSuave,
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
    );
  }

  Widget _campoMonto() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AtelierColors.grisBorde),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text(
            '\$ ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AtelierColors.negroSuave,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AtelierColors.negroSuave,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 18,
                  color: AtelierColors.grisTexto,
                ),
              ),
              onChanged: (val) {
                final n = double.tryParse(val);
                setState(() {
                  _precio = n ?? 0; // 👈 setState para repintar el botón
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LÓGICA
  // ---------------------------------------------------------------------------

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AtelierColors.rosa,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  void _guardar() {
    final mapaVariantes = <String, String>{};
    _variantesElegidas.forEach((k, v) {
      if (v != null && v.isNotEmpty) {
        mapaVariantes[k] = v;
      }
    });

    final venta = Venta(
      productoId: _tipoActivo == 'producto' ? _idSeleccionado : null,
      comboId: _tipoActivo == 'combo' ? _idSeleccionado : null,
      nombreItem: _nombreItem,
      monto: _precio,
      fecha: _fecha.toIso8601String(),
    );

    widget.onRegistrar(venta, mapaVariantes);
    setState(() {
      _idSeleccionado = null;
      _nombreItem = '';
      _precio = 0;
      _listaAbierta = false;
      _variantesElegidas.clear();
      _listasVariantesAbiertas.clear();
      _montoCtrl.clear();
      _fecha = DateTime.now();
    });
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static String _formatear(double v) {
    return v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  static String _formatearFecha(DateTime f) {
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const _DashedLinePainter({
    this.color = Colors.grey,
    this.dashWidth = 4,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      final endX = startX + dashWidth;
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(endX > size.width ? size.width : endX, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}

class _ItemLista {
  final String id;
  final String nombre;
  final double precio;
  _ItemLista({required this.id, required this.nombre, required this.precio});
}
