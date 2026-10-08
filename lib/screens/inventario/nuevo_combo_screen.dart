import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/inventario_provider.dart';
import '../../models/combo.dart';
import '../../models/combo_item.dart';
import '../../models/producto.dart';
import '../../models/material.dart';

class NuevoComboScreen extends StatefulWidget {
  final Combo? comboAEditar;
  final List<ComboItem>? itemsAEditar;

  const NuevoComboScreen({super.key, this.comboAEditar, this.itemsAEditar});

  @override
  State<NuevoComboScreen> createState() => _NuevoComboScreenState();
}

class _NuevoComboScreenState extends State<NuevoComboScreen> {
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  final _nombreFocus = FocusNode();
  final _precioFocus = FocusNode();

  List<ComboItem> _items = [];

  bool get _esEdicion => widget.comboAEditar != null;

  bool get _isFormValid => _nombreCtrl.text.trim().isNotEmpty && _precioCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreCtrl.text = widget.comboAEditar!.nombre;
      _precioCtrl.text = widget.comboAEditar!.precio.toStringAsFixed(0);
      _descCtrl.text = widget.comboAEditar!.descripcion ?? '';
      if (widget.itemsAEditar != null) {
        _items = List.from(widget.itemsAEditar!);
      }
    }
    _nombreCtrl.addListener(_updateState);
    _precioCtrl.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _descCtrl.dispose();
    _nombreFocus.dispose();
    _precioFocus.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_nombreCtrl.text.trim().isEmpty) {
      _nombreFocus.requestFocus();
      return;
    }
    if (_precioCtrl.text.trim().isEmpty) {
      _precioFocus.requestFocus();
      return;
    }

    final id = _esEdicion ? widget.comboAEditar!.id : const Uuid().v4();
    final combo = Combo(
      id: id,
      nombre: _nombreCtrl.text.trim(),
      precio: double.tryParse(_precioCtrl.text) ?? 0,
      descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );

    FocusManager.instance.primaryFocus?.unfocus();
    if (_esEdicion) {
      context.read<InventarioProvider>().editarCombo(combo, _items);
    } else {
      context.read<InventarioProvider>().agregarCombo(combo, _items);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    bool canSave = _isFormValid;

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
                  Text(_esEdicion ? 'Editar combo' : 'Nuevo combo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20, right: 20, top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nombre del combo *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 5),
                    _buildTextField(_nombreCtrl, 'Ej. Combo Cumpleaños Premium', focusNode: _nombreFocus),
                    const SizedBox(height: 20),
                    
                    const Text('Precio del combo (\$) *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 5),
                    _buildTextField(_precioCtrl, 'Ej. \$ 12.500', isNumber: true, focusNode: _precioFocus),
                    const SizedBox(height: 20),
                    
                    const Text('Descripción (Opcional)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 5),
                    _buildTextField(_descCtrl, 'Incluye vincha decorada con strass', maxLines: 3),
                    const SizedBox(height: 30),

                    const Text('ITEMS DEL COMBO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const Text('Define la cantidad para descontar stock (opcional)', style: TextStyle(color: Colors.black45, fontSize: 13)),
                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: () => _mostrarModalSeleccion(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9C4D8).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF9C4D8), style: BorderStyle.solid), // Simular dashed si es complejo, o usar solido claro
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add, color: Color(0xFFEC6294)),
                            SizedBox(width: 5),
                            Text('Añadir Item', style: TextStyle(color: Color(0xFFEC6294), fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    ..._items.map((item) {
                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.black12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Text('Cantidad a descontar: ', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                        SizedBox(
                                          width: 50,
                                          height: 30,
                                          child: TextField(
                                            controller: TextEditingController(text: item.cantidad?.toStringAsFixed(0) ?? '1')
                                              ..selection = TextSelection.collapsed(offset: (item.cantidad?.toStringAsFixed(0) ?? '1').length),
                                            keyboardType: TextInputType.number,
                                            onChanged: (val) {
                                              item = ComboItem(
                                                elementoId: item.elementoId, 
                                                tipo: item.tipo, 
                                                nombre: item.nombre, 
                                                cantidad: double.tryParse(val)
                                              );
                                              // Actualizar en la lista
                                              int idx = _items.indexWhere((i) => i.elementoId == item.elementoId && i.tipo == item.tipo);
                                              if (idx != -1) _items[idx] = item;
                                            },
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                              filled: true,
                                              fillColor: const Color(0xFFEBEBEB),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _items.remove(item);
                                  });
                                },
                                child: const Icon(Icons.delete, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.pop(context);
                      },
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
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: canSave ? const Color(0xFFEC6294) : const Color(0xFFF9C4D8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false, int maxLines = 1, FocusNode? focusNode}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
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

  void _mostrarModalSeleccion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModalSeleccion(
        onSelected: (ComboItem item) {
          setState(() {
            // Verificar si ya existe
            if (!_items.any((i) => i.elementoId == item.elementoId && i.tipo == item.tipo)) {
              _items.add(item);
            }
          });
        }
      )
    );
  }
}

class _ModalSeleccion extends StatefulWidget {
  final Function(ComboItem) onSelected;
  const _ModalSeleccion({required this.onSelected});

  @override
  State<_ModalSeleccion> createState() => _ModalSeleccionState();
}

class _ModalSeleccionState extends State<_ModalSeleccion> {
  int _tabIndex = 0; // 0 = Productos, 1 = Materiales
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    
    List<dynamic> elementos = [];
    if (_tabIndex == 0) {
      elementos = provider.productos.where((p) => p.nombre.toLowerCase().contains(_busqueda.toLowerCase())).toList();
    } else {
      elementos = provider.materiales.where((m) => m.nombre.toLowerCase().contains(_busqueda.toLowerCase())).toList();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Stack(
            children: [
              const Center(
                child: Text('Seleccionar Elemento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Positioned(
                right: 20,
                top: -5,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 28),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tabIndex == 0 ? const Color(0xFFEC6294) : const Color(0xFFF9C4D8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('Productos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tabIndex == 1 ? const Color(0xFFEC6294) : const Color(0xFFF9C4D8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('Materiales', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (val) => setState(() => _busqueda = val),
              decoration: InputDecoration(
                hintText: _tabIndex == 0 ? 'Buscar producto' : 'Buscar material',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('ELEMENTOS DISPONIBLES', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: elementos.length,
              itemBuilder: (ctx, i) {
                final el = elementos[i];
                String nombre = el.nombre;
                String stockTexto = '';
                
                if (el is MaterialItem) {
                  stockTexto = 'Stock disponible: ${el.cantidad.toStringAsFixed(0)} ${el.unidad}';
                }

                return GestureDetector(
                  onTap: () {
                    widget.onSelected(ComboItem(
                      elementoId: el.id,
                      tipo: el is Producto ? 'producto' : 'material',
                      nombre: el.nombre,
                      cantidad: 1, // Por defecto 1
                    ));
                    Navigator.pop(context);
                  },
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          if (stockTexto.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(stockTexto, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
