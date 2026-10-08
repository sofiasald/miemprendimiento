import 'package:flutter/material.dart';

import '../models/movimiento_models.dart';
import '../models/venta.dart';
import 'selector_articulo_acordeon.dart';

class VentaForm extends StatefulWidget {
  final List<Producto> productos;
  final List<Combo> combos;
  final List<MaterialItem> materiales;
  final Map<String, List<Variante>> variantesPorMaterial;
  final void Function(Venta venta, List<MaterialConsumo> consumos) onRegistrar;

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
  // 'producto' o 'combo' — determina qué lista se muestra en el campo
  String _tipoActivo = 'producto';

  // Artículo elegido
  String? _idSeleccionado;
  String _nombreItem = '';
  double _precio = 0;

  // Controla si el campo está desplegado
  bool _listaAbierta = false;

  final List<_ConsumoForm> _consumos = [];

  @override
  Widget build(BuildContext context) {
    // Lista activa según el círculo seleccionado
    final itemsActivos = _tipoActivo == 'producto'
        ? widget.productos
              .map(
                (p) => _ItemLista(
                  id: p.id,
                  nombre: p.nombre,
                  precio: p.precio,
                  subtitulo: null,
                ),
              )
              .toList()
        : widget.combos
              .map(
                (c) => _ItemLista(
                  id: c.id,
                  nombre: c.nombre,
                  precio: c.precio,
                  subtitulo: null,
                ),
              )
              .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Título del campo ----
          const Text(
            'Producto Vendido *',
            style: TextStyle(fontSize: 15, color: AtelierColors.grisTexto),
          ),
          const SizedBox(height: 10),

          // ---- Círculo + palabras ARRIBA del campo ----
          Row(
            children: [
              // Círculo Productos
              GestureDetector(
                onTap: () => setState(() {
                  _tipoActivo = 'producto';
                  _idSeleccionado = null;
                  _nombreItem = '';
                  _precio = 0;
                  _listaAbierta = true;
                }),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _tipoActivo == 'producto'
                        ? AtelierColors.rosaSuave
                        : AtelierColors.rosaSuave.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _tipoActivo = 'producto';
                  _idSeleccionado = null;
                  _nombreItem = '';
                  _precio = 0;
                  _listaAbierta = true;
                }),
                child: Text(
                  'Productos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _tipoActivo == 'producto'
                        ? AtelierColors.negroSuave
                        : AtelierColors.negroSuave.withValues(alpha: 0.55),
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Círculo Combos
              GestureDetector(
                onTap: () => setState(() {
                  _tipoActivo = 'combo';
                  _idSeleccionado = null;
                  _nombreItem = '';
                  _precio = 0;
                  _listaAbierta = true;
                }),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _tipoActivo == 'combo'
                        ? AtelierColors.rosaSuave
                        : AtelierColors.rosaSuave.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _tipoActivo = 'combo';
                  _idSeleccionado = null;
                  _nombreItem = '';
                  _precio = 0;
                  _listaAbierta = true;
                }),
                child: Text(
                  'Combos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _tipoActivo == 'combo'
                        ? AtelierColors.negroSuave
                        : AtelierColors.negroSuave.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ---- Campo único desplegable ----
          Container(
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
                  ? [
                      const BoxShadow(
                        color: Color(0x40000008),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                // Cabecera clickeable
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

                // Lista desplegable (misma estética que el acordeón del Figma)
                if (_listaAbierta)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: AtelierColors.grisBorde),
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      children: itemsActivos.asMap().entries.map((e) {
                        final item = e.value;
                        final esUltimo = e.key == itemsActivos.length - 1;
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
                                });
                              },
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                color: seleccionado
                                    ? AtelierColors.rosaClaro.withValues(alpha: 0.25)
                                    : Colors.transparent,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                            // Divisor dashed (como el CSS)
                            if (!esUltimo)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: CustomPaint(
                                  size: const Size(double.infinity, 1),
                                  painter: _DashedLinePainter(
                                    color: AtelierColors.grisBorde,
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
          ),

          const SizedBox(height: 20),

          // ---- Precio (solo lectura, autocompletado) ----
          if (_idSeleccionado != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AtelierColors.grisBorde),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monto total (\$)',
                    style: TextStyle(
                      fontSize: 15,
                      color: AtelierColors.grisTexto,
                    ),
                  ),
                  Text(
                    '\$ ${_formatear(_precio)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AtelierColors.negroSuave,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // ---- Consumo de insumos (opcional) ----
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Consumo de insumos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _consumos.add(_ConsumoForm())),
                icon: const Icon(Icons.add, color: AtelierColors.rosa),
                label: const Text(
                  'Añadir',
                  style: TextStyle(color: AtelierColors.rosa),
                ),
              ),
            ],
          ),
          ..._consumos.map(_buildConsumoCard),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _idSeleccionado != null
                    ? AtelierColors.rosa
                    : AtelierColors.rosaClaro,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _idSeleccionado == null ? null : _guardar,
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
    );
  }

  Widget _buildConsumoCard(_ConsumoForm c) {
    final variantes = c.materialId != null
        ? widget.variantesPorMaterial[c.materialId!] ?? []
        : <Variante>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Material',
                    isDense: true,
                  ),
                  initialValue: c.materialId,
                  items: widget.materiales
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (id) => setState(() {
                    c.materialId = id;
                    c.varianteId = null;
                  }),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.black45),
                onPressed: () => setState(() => _consumos.remove(c)),
              ),
            ],
          ),
          if (variantes.isNotEmpty)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Variante',
                isDense: true,
              ),
              initialValue: c.varianteId,
              items: variantes
                  .map(
                    (v) => DropdownMenuItem(
                      value: v.id,
                      child: Text('${v.nombre} (${v.cantidad})'),
                    ),
                  )
                  .toList(),
              onChanged: (id) => setState(() => c.varianteId = id),
            ),
          TextField(
            controller: c.cantidadCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad a descontar',
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  void _guardar() {
    final consumos = _consumos
        .where((c) => c.materialId != null && c.cantidadCtrl.text.isNotEmpty)
        .map(
          (c) => MaterialConsumo(
            materialId: c.materialId!,
            cantidad: double.tryParse(c.cantidadCtrl.text) ?? 0,
          ),
        )
        .toList();

    final venta = Venta(
      productoId: _tipoActivo == 'producto' ? _idSeleccionado : null,
      comboId: _tipoActivo == 'combo' ? _idSeleccionado : null,
      nombreItem: _nombreItem,
      monto: _precio,
    );

    widget.onRegistrar(venta, consumos);
    setState(() {
      _idSeleccionado = null;
      _nombreItem = '';
      _precio = 0;
      _listaAbierta = false;
      _consumos.clear();
    });
  }

  static String _formatear(double v) {
    return v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ItemLista {
  final String id;
  final String nombre;
  final double precio;
  final String? subtitulo;
  _ItemLista({
    required this.id,
    required this.nombre,
    required this.precio,
    this.subtitulo,
  });
}

class _ConsumoForm {
  String? materialId;
  String? varianteId;
  final TextEditingController cantidadCtrl = TextEditingController();
}
