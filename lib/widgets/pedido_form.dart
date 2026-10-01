import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/movimiento_models.dart';
import 'lista_desplegable.dart';

class PedidoForm extends StatefulWidget {
  final List<Producto> productos;
  final List<Combo> combos;
  final void Function(Map<String, dynamic> pedido) onRegistrar;

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
  ItemLista? _itemSeleccionado;
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();
  DateTime _fechaEntrega = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _clienteController.dispose();
    _montoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // ── Artículo encargado ─────────────────────────
        const _Label('Artículo encargado *'),
        const SizedBox(height: 8),
        ListaDesplegable(
          productos: widget.productos
              .map(
                (p) => ItemLista(
                  id: p!.id,
                  nombre: p.nombre,
                  precio: p.precio,
                ),
              )
              .toList(),
          combos: widget.combos
              .map(
                (c) => ItemLista(
                  id: c!.id,
                  nombre: c.nombre,
                  precio: c.precio,
                  esCombo: true,
                ),
              )
              .toList(),
          seleccionadoId: _itemSeleccionado?.id,
          onSeleccionado: (item) {
            setState(() {
              _itemSeleccionado = item;
              _montoController.text = item.precio.toStringAsFixed(0);
            });
          },
        ),

        const SizedBox(height: 20),

        // ── Nombre del cliente ─────────────────────────
        const _Label('Nombre del Cliente *'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _InputBox(
            controller: _clienteController,
            hint: 'Ingresar Nombre . . .',
          ),
        ),

        const SizedBox(height: 20),

        // ── Fecha de entrega (solo futuras) ────────────
        const _Label('Fecha de entrega pactada *'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _fechaEntrega,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _fechaEntrega = picked);
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
                    DateFormat('dd/MM/yyyy').format(_fechaEntrega),
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
          ),
        ),

        const SizedBox(height: 20),

        // ── Monto pactado ──────────────────────────────
        const _Label('Monto pactado (\$) *'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _InputBox(
            controller: _montoController,
            hint: '\$ 0',
            keyboard: TextInputType.number,
            prefix: '\$ ',
          ),
        ),

        const SizedBox(height: 20),

        // ── Observaciones ──────────────────────────────
        const _Label('Observaciones (Opcional)'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _observacionesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Agregar notas adicionales, seña, entrega . . .',
                hintStyle: TextStyle(color: Color(0xFF757575)),
                border: InputBorder.none,
              ),
            ),
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
    if (_itemSeleccionado == null) {
      _snack('Seleccione un artículo');
      return;
    }
    if (_clienteController.text.trim().isEmpty) {
      _snack('Ingrese el nombre del cliente');
      return;
    }
    if (_fechaEntrega.isBefore(DateTime.now())) {
      _snack('La fecha de entrega debe ser futura');
      return;
    }

    // ⚠ Sprint 4 - Paso 7: un pedido NO descuenta stock todavía.
    final pedido = {
      'tipo': _itemSeleccionado!.esCombo ? 'combo' : 'producto',
      'itemId': _itemSeleccionado!.id,
      'cliente': _clienteController.text.trim(),
      'fechaEntrega': _fechaEntrega.toIso8601String(),
      'monto': double.tryParse(_montoController.text) ?? 0,
      'observaciones': _observacionesController.text.trim(),
      'estado': 'pendiente',
    };

    widget.onRegistrar(pedido);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 15,
          color: Color(0xFF757575),
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboard;
  final String? prefix;

  const _InputBox({
    required this.controller,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          hintStyle: const TextStyle(color: Color(0xFF757575)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
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
