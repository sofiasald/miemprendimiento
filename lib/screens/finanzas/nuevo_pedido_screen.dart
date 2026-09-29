import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/pedido.dart';
import '../../models/producto.dart';
import '../../models/combo.dart';
import 'seleccionar_producto_combo_modal.dart';
import '../../providers/finanzas_provider.dart';

class NuevoPedidoScreen extends StatefulWidget {
  const NuevoPedidoScreen({super.key});

  @override
  State<NuevoPedidoScreen> createState() => _NuevoPedidoScreenState();
}

class _NuevoPedidoScreenState extends State<NuevoPedidoScreen> {
  dynamic _itemSeleccionado; // Producto o Combo
  String? _itemTipo;
  final _clienteCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  DateTime? _fechaEntrega;
  bool _guardando = false;

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirItem() async {
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
      final precio = resultado is Producto
          ? resultado.precio
          : (resultado as Combo).precio;
      _montoCtrl.text = precio.toStringAsFixed(0);
    });
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    // Paso 7 / cuidado del Sprint 1: un pedido no puede tener fecha en el pasado
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega ?? ahora.add(const Duration(days: 1)),
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 365)),
    );
    if (fecha != null) setState(() => _fechaEntrega = fecha);
  }

  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Atención',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: Color(0xFFEC6294),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (_itemSeleccionado == null) {
      _mostrarAlerta('Elegí qué producto o combo pidieron.');
      return;
    }
    if (_clienteCtrl.text.trim().isEmpty) {
      _mostrarAlerta('Ingresá el nombre del cliente.');
      return;
    }
    final monto = double.tryParse(_montoCtrl.text.trim());
    if (monto == null || monto <= 0) {
      _mostrarAlerta('Ingresá un monto válido.');
      return;
    }
    if (_fechaEntrega == null) {
      _mostrarAlerta('Elegí la fecha de entrega.');
      return;
    }

    setState(() => _guardando = true);

    // Paso 7: el pedido se guarda SIN tocar el stock. Eso pasa recién cuando
    // se marca como "Entregado" (Sprint 5), momento en que se convierte en venta.

      final pedido = Pedido(
        productoId: _itemTipo == 'producto' ? _itemSeleccionado.id as String : null,
        comboId: _itemTipo == 'combo' ? _itemSeleccionado.id as String : null,
        nombreItem: _itemSeleccionado.nombre as String,
        cliente: _clienteCtrl.text.trim(),
        monto: monto,
        fechaEntrega: _fechaEntrega!, // Pasamos el DateTime directamente
      );

    await context.read<FinanzasProvider>().registrarPedido(pedido);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Nuevo pedido',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 10,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Producto o combo pedido *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: _elegirItem,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _itemSeleccionado?.nombre ??
                                  'Tocá para elegir...',
                              style: TextStyle(
                                color: _itemSeleccionado == null
                                    ? Colors.black38
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Cliente *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _buildTextField(_clienteCtrl, 'Ej. Martina Gómez'),
                    const SizedBox(height: 20),
                    const Text(
                      'Monto (\$) *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _buildTextField(_montoCtrl, 'Ej. 4500', isNumber: true),
                    const SizedBox(height: 20),
                    const Text(
                      'Fecha de entrega *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: _elegirFecha,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _fechaEntrega == null
                                  ? 'Tocá para elegir...'
                                  : DateFormat('dd-MM-yyyy')
                                        .format(_fechaEntrega!),
                              style: TextStyle(
                                color: _fechaEntrega == null
                                    ? Colors.black38
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.black38,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _guardando
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Color(0xFFEC6294)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFFEC6294),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: const Color(0xFFEC6294),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _guardando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }
}
