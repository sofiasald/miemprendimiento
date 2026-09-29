import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/producto.dart';
import '../../models/producto_material.dart';
import '../../models/material.dart';
import '../../providers/inventario_provider.dart';

class NuevoProductoScreen extends StatefulWidget {
  final Producto? productoAEditar;
  final List<ProductoMaterial>? insumosAEditar;

  const NuevoProductoScreen({super.key, this.productoAEditar, this.insumosAEditar});

  @override
  State<NuevoProductoScreen> createState() => _NuevoProductoScreenState();
}

class _NuevoProductoScreenState extends State<NuevoProductoScreen> {
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _nombreFocus = FocusNode();
  final _precioFocus = FocusNode();

  final List<ProductoMaterialForm> _insumos = [];

  bool get _esEdicion => widget.productoAEditar != null;

  bool get _isFormValid {
    return _nombreCtrl.text.trim().isNotEmpty && _precioCtrl.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreCtrl.text = widget.productoAEditar!.nombre;
      _precioCtrl.text = widget.productoAEditar!.precio.toStringAsFixed(0);
      _descCtrl.text = widget.productoAEditar!.descripcion ?? '';
      
      if (widget.insumosAEditar != null) {
        for (var i in widget.insumosAEditar!) {
          final form = ProductoMaterialForm(
            materialId: i.materialId,
            materialNombre: i.materialNombre,
            materialUnidad: i.materialUnidad,
          );
          if (i.cantidad != null) {
            form.cantidadCtrl.text = i.cantidad!.toStringAsFixed(0);
          }
          _insumos.add(form);
        }
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
    for (var i in _insumos) {
      i.cantidadCtrl.dispose();
    }
    super.dispose();
  }

  void _guardarProducto() {
    if (_nombreCtrl.text.trim().isEmpty) {
      _nombreFocus.requestFocus();
      return;
    }
    if (_precioCtrl.text.trim().isEmpty) {
      _precioFocus.requestFocus();
      return;
    }

    final double precio = double.tryParse(_precioCtrl.text.trim()) ?? 0;

    final nuevoProducto = Producto(
      id: _esEdicion ? widget.productoAEditar!.id : const Uuid().v4(),
      nombre: _nombreCtrl.text.trim(),
      precio: precio,
      descripcion: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
    );

    List<ProductoMaterial> insumosAGuardar = _insumos.map((i) {
      double? cant = double.tryParse(i.cantidadCtrl.text.trim());
      return ProductoMaterial(
        materialId: i.materialId,
        materialNombre: i.materialNombre,
        materialUnidad: i.materialUnidad,
        cantidad: cant,
      );
    }).toList();

    FocusManager.instance.primaryFocus?.unfocus();
    final provider = context.read<InventarioProvider>();
    if (_esEdicion) {
      provider.editarProducto(nuevoProducto, insumosAGuardar).then((_) {
        if (!mounted) return;
        Navigator.pop(context, true);
      });
    } else {
      provider.agregarProducto(nuevoProducto, insumosAGuardar).then((_) {
        if (!mounted) return;
        Navigator.pop(context, true);
      });
    }
  }

  void _abrirModalMateriales() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SeleccionarMaterialModal(
        materialesActuales: _insumos.map((i) => i.materialId).toList(),
      ),
    ).then((selectedMaterial) {
      if (selectedMaterial != null && selectedMaterial is MaterialItem) {
        setState(() {
          _insumos.add(ProductoMaterialForm(
            materialId: selectedMaterial.id,
            materialNombre: selectedMaterial.nombre,
            materialUnidad: selectedMaterial.unidad,
          ));
        });
      }
    });
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
                  Text(_esEdicion ? 'Editar producto' : 'Nuevo producto', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    const Text('Nombre del producto *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 5),
                    _buildTextField(_nombreCtrl, 'Ej. Tiara Strass', focusNode: _nombreFocus),
                    const SizedBox(height: 20),

                    const Text('Precio de venta (\$) *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 5),
                    _buildTextField(_precioCtrl, 'Ej. 4500', isNumber: true, focusNode: _precioFocus),
                    const SizedBox(height: 20),

                    const Text('Descripción (Opcional)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 5),
                    _buildTextField(_descCtrl, 'Vincha con base metálica y apliques de gemas...', maxLines: 3),
                    const SizedBox(height: 30),

                    Text('MATERIALES CONSUMIDOS (${_insumos.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 5),
                    const Text('Deja la cantidad vacía si es solo referencial', style: TextStyle(color: Colors.black45, fontSize: 13)),
                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: _abrirModalMateriales,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE4F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEC6294).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add, color: Color(0xFFEC6294)),
                            SizedBox(width: 10),
                            Text('Añadir material', style: TextStyle(color: Color(0xFFEC6294), fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ..._insumos.map((insumo) => _buildInsumoCard(insumo)),
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
                      onPressed: _guardarProducto,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: canSave ? const Color(0xFFEC6294) : const Color(0xFFF9C4D8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEC6294))),
      ),
    );
  }

  Widget _buildInsumoCard(ProductoMaterialForm insumo) {
    int index = _insumos.indexOf(insumo);
    int occurrence = 1;
    for (int i = 0; i < index; i++) {
      if (_insumos[i].materialId == insumo.materialId) {
        occurrence++;
      }
    }
    String suffix = occurrence > 1 ? ' ($occurrence)' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('${insumo.materialNombre}$suffix', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _insumos.remove(insumo);
                  });
                },
                child: const Icon(Icons.delete, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Cantidad a descontar:', style: TextStyle(color: Colors.black54)),
              const SizedBox(width: 10),
              Container(
                width: 60,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: insumo.cantidadCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(bottom: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(insumo.materialUnidad.toLowerCase(), style: const TextStyle(color: Colors.black54)),
            ],
          )
        ],
      ),
    );
  }
}

class ProductoMaterialForm {
  String materialId;
  String materialNombre;
  String materialUnidad;
  TextEditingController cantidadCtrl = TextEditingController();

  ProductoMaterialForm({
    required this.materialId,
    required this.materialNombre,
    required this.materialUnidad,
  });
}

class SeleccionarMaterialModal extends StatefulWidget {
  final List<String> materialesActuales;

  const SeleccionarMaterialModal({super.key, required this.materialesActuales});

  @override
  State<SeleccionarMaterialModal> createState() => _SeleccionarMaterialModalState();
}

class _SeleccionarMaterialModalState extends State<SeleccionarMaterialModal> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final materialesDisponibles = provider.materiales;
    
    List<MaterialItem> filtrados = _busqueda.isEmpty 
      ? materialesDisponibles 
      : materialesDisponibles.where((m) => m.nombre.toLowerCase().contains(_busqueda.toLowerCase())).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Seleccionar Material', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Color(0xFFEC6294), size: 28),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (val) => setState(() => _busqueda = val),
              decoration: InputDecoration(
                hintText: 'Buscar material . . .',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF2F2F2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('MATERIALES DISPONIBLES (${filtrados.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtrados.length,
              itemBuilder: (context, index) {
                final m = filtrados[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, m),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text.rich(TextSpan(
                          children: [
                            const TextSpan(text: 'Stock disponible: ', style: TextStyle(color: Colors.black54)),
                            TextSpan(text: '${m.cantidad.toStringAsFixed(0)} ${m.unidad.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )),
                      ],
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
