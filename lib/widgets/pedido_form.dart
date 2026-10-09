import 'package:flutter/material.dart';

import '../models/movimiento_models.dart';
import '../models/pedido.dart';
import 'selector_articulo_acordeon.dart';

class PedidoForm extends StatefulWidget {
  final List<Producto> productos;
  final List<Combo> combos;
  final void Function(Pedido pedido) onRegistrar;

  const PedidoForm({
    super.key,
    required this.productos,
    required this.combos,
    required this.onRegistrar,
  });

  @override
  State<PedidoForm> createState() => _PedidoFormState();
}

class _PedidoFormState extends State<PedidoForm> {
  final _clienteCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');

  String? _tipoSeleccionado;
  String? _idSeleccionado;
  String _nombreItem = '';
  DateTime _fechaEntrega = DateTime.now().add(const Duration(days: 7));

  // 👇 Validación del formulario completo
  bool get _formularioCompleto {
    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    final cantidad = int.tryParse(_cantidadCtrl.text) ?? 0;
    return _idSeleccionado != null &&
        _clienteCtrl.text.trim().isNotEmpty &&
        cantidad > 0 &&
        monto > 0;
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _montoCtrl.dispose();
    _observacionesCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Artículo encargado ----
          const Text(
            'Artículo encargado *',
            style: TextStyle(fontSize: 15, color: AtelierColors.grisTexto),
          ),
          const SizedBox(height: 8),

          InkWell(
            onTap: _abrirSelectorArticulo,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AtelierColors.grisBorde),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _idSeleccionado == null
                          ? 'Seleccionar Artículo . . .'
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
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AtelierColors.rosa,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---- Cantidad + Nombre cliente ----
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cantidad *',
                      style: TextStyle(
                        fontSize: 15,
                        color: AtelierColors.grisTexto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cantidadCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: _inputDecoration('1'),
                      onChanged: (_) => setState(() {}), // 👈
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nombre del Cliente *',
                      style: TextStyle(
                        fontSize: 15,
                        color: AtelierColors.grisTexto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clienteCtrl,
                      decoration: _inputDecoration('Ingresar Nombre . . .'),
                      onChanged: (_) => setState(() {}), // 👈
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---- Fecha de entrega ----
          const Text(
            'Fecha de entrega pactada *',
            style: TextStyle(fontSize: 15, color: AtelierColors.grisTexto),
          ),
          const SizedBox(height: 8),
          InkWell(
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
                    _formatearFecha(_fechaEntrega),
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
          ),

          const SizedBox(height: 20),

          // ---- Monto pactado ----
          const Text(
            'Monto pactado (\$) *',
            style: TextStyle(fontSize: 15, color: AtelierColors.grisTexto),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _montoCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('\$ 0'),
            onChanged: (_) => setState(() {}), // 👈
          ),

          const SizedBox(height: 20),

          // ---- Observaciones ----
          const Text(
            'Observaciones (Opcional)',
            style: TextStyle(fontSize: 15, color: AtelierColors.grisTexto),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _observacionesCtrl,
            maxLines: 3,
            decoration: _inputDecoration(
              'Agregar Notas adicionales, seña, entrega . . .',
            ),
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
                        : AtelierColors.rosaSuave,
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

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null) setState(() => _fechaEntrega = picked);
  }

  void _abrirSelectorArticulo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SelectorArticuloSheet(
        productos: widget.productos,
        combos: widget.combos,
        idSeleccionado: _idSeleccionado,
        onSeleccionar: (tipo, id, nombre, precio) {
          setState(() {
            _tipoSeleccionado = tipo;
            _idSeleccionado = id;
            _nombreItem = nombre;
            _montoCtrl.text = precio.toInt().toString();
          });
        },
      ),
    );
  }

  String _formatearFecha(DateTime f) {
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  }

  void _guardar() {
    if (_clienteCtrl.text.trim().isEmpty || _idSeleccionado == null) return;

    final pedido = Pedido(
      productoId: _tipoSeleccionado == 'producto' ? _idSeleccionado : null,
      comboId: _tipoSeleccionado == 'combo' ? _idSeleccionado : null,
      cliente: _clienteCtrl.text.trim(),
      nombreItem: _nombreItem,
      cantidad: int.tryParse(_cantidadCtrl.text) ?? 1,
      monto: double.tryParse(_montoCtrl.text) ?? 0,
      fechaEntrega: _fechaEntrega,
      fechaRegistro: DateTime.now(),
      observaciones: _observacionesCtrl.text.trim(),
      estado: 'pendiente',
    );

    widget.onRegistrar(pedido);
    setState(() {
      _idSeleccionado = null;
      _tipoSeleccionado = null;
      _nombreItem = '';
      _clienteCtrl.clear();
      _montoCtrl.clear();
      _observacionesCtrl.clear();
      _cantidadCtrl.text = '1';
    });
  }
}

// ---------------------------------------------------------------------------
// BOTTOM SHEET CON EL ACORDEÓN PLEGABLE
// ---------------------------------------------------------------------------

class _SelectorArticuloSheet extends StatefulWidget {
  final List<Producto> productos;
  final List<Combo> combos;
  final String? idSeleccionado;
  final void Function(String tipo, String id, String nombre, double precio)
  onSeleccionar;

  const _SelectorArticuloSheet({
    required this.productos,
    required this.combos,
    required this.idSeleccionado,
    required this.onSeleccionar,
  });

  @override
  State<_SelectorArticuloSheet> createState() => _SelectorArticuloSheetState();
}

class _SelectorArticuloSheetState extends State<_SelectorArticuloSheet> {
  bool _productosAbierto = true;
  bool _combosAbierto = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AtelierColors.grisFondo,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 35,
            height: 4,
            decoration: BoxDecoration(
              color: AtelierColors.grisBorde,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AtelierColors.grisBorde),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Seleccionar Artículo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AtelierColors.negroSuave,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: AtelierColors.rosa,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _acordeon(
            titulo: 'PRODUCTOS INDIVIDUALES',
            abierto: _productosAbierto,
            onToggle: () =>
                setState(() => _productosAbierto = !_productosAbierto),
            items: widget.productos
                .map(
                  (p) => FilaArticulo(
                    nombre: p.nombre,
                    precio: '\$ ${_formatear(p.precio)}',
                    seleccionado: widget.idSeleccionado == p.id,
                    onTap: () {
                      widget.onSeleccionar(
                        'producto',
                        p.id,
                        p.nombre,
                        p.precio,
                      );
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 20),

          _acordeon(
            titulo: 'COMBOS Y PAQUETES',
            abierto: _combosAbierto,
            onToggle: () => setState(() => _combosAbierto = !_combosAbierto),
            items: widget.combos
                .map(
                  (c) => FilaArticulo(
                    nombre: c.nombre,
                    precio: '\$ ${_formatear(c.precio)}',
                    seleccionado: widget.idSeleccionado == c.id,
                    onTap: () {
                      widget.onSeleccionar('combo', c.id, c.nombre, c.precio);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _acordeon({
    required String titulo,
    required bool abierto,
    required VoidCallback onToggle,
    required List<Widget> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AtelierColors.grisBorde),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: abierto ? AtelierColors.grisFila : Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(8),
                  bottom: Radius.circular(abierto ? 0 : 8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AtelierColors.negroSuave,
                    ),
                  ),
                  Icon(
                    abierto
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AtelierColors.rosa,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (abierto)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AtelierColors.grisBorde)),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Column(children: items),
            ),
        ],
      ),
    );
  }

  static String _formatear(double v) {
    return v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
