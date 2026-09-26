import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/inventario_provider.dart';
import '../../models/material.dart';
import '../../models/variante.dart';

class NuevoMaterialScreen extends StatefulWidget {
  final MaterialItem? materialAEditar;
  final List<Variante>? variantesAEditar;

  const NuevoMaterialScreen({super.key, this.materialAEditar, this.variantesAEditar});

  @override
  State<NuevoMaterialScreen> createState() => _NuevoMaterialScreenState();
}

class _NuevoMaterialScreenState extends State<NuevoMaterialScreen> {
  final _nombreCtrl = TextEditingController();
  final _nombreFocus = FocusNode();
  String _unidad = 'Unidades';
  bool _tieneVariantes = false;
  
  final _cantidadCtrl = TextEditingController();
  final _stockMinCtrl = TextEditingController();
  
  final List<VarianteForm> _variantes = [];

  bool get _esEdicion => widget.materialAEditar != null;

  bool get _isFormValid {
    return _nombreCtrl.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreCtrl.text = widget.materialAEditar!.nombre;
      _unidad = widget.materialAEditar!.unidad;
      
      if (widget.variantesAEditar != null && widget.variantesAEditar!.isNotEmpty) {
        _tieneVariantes = true;
        for (var v in widget.variantesAEditar!) {
          final vf = VarianteForm();
          vf.nombreCtrl.text = v.nombre;
          vf.cantidadCtrl.text = v.cantidad.toStringAsFixed(0);
          vf.minCtrl.text = v.stockMinimo.toStringAsFixed(0);
          vf.nombreCtrl.addListener(_updateState);
          vf.cantidadCtrl.addListener(_updateState);
          _variantes.add(vf);
        }
      } else {
        _cantidadCtrl.text = widget.materialAEditar!.cantidad.toStringAsFixed(0);
        _stockMinCtrl.text = widget.materialAEditar!.stockMinimo.toStringAsFixed(0);
      }
    }
    _nombreCtrl.addListener(_updateState);
    _cantidadCtrl.addListener(_updateState);
    _stockMinCtrl.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nombreFocus.dispose();
    _cantidadCtrl.dispose();
    _stockMinCtrl.dispose();
    for (var v in _variantes) {
      v.nombreCtrl.dispose();
      v.cantidadCtrl.dispose();
      v.minCtrl.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    if (_nombreCtrl.text.trim().isEmpty) {
      _nombreFocus.requestFocus();
      return;
    }

    final materialId = _esEdicion ? widget.materialAEditar!.id : const Uuid().v4();
    double cantidadTotal = 0;
    
    List<Variante> variantesAGuardar = [];
    
    if (_tieneVariantes) {
      for (var vForm in _variantes) {
        if (vForm.nombreCtrl.text.trim().isEmpty) continue;
        double cant = double.tryParse(vForm.cantidadCtrl.text) ?? 0;
        double min = double.tryParse(vForm.minCtrl.text) ?? 0;
        cantidadTotal += cant;
        variantesAGuardar.add(Variante(
          materialId: materialId,
          nombre: vForm.nombreCtrl.text.trim(),
          cantidad: cant,
          stockMinimo: min,
        ));
      }
    } else {
      cantidadTotal = double.tryParse(_cantidadCtrl.text) ?? 0;
    }

    double stockMinimoGeneral = double.tryParse(_stockMinCtrl.text) ?? 0;

    final nuevoMaterial = MaterialItem(
      id: materialId,
      nombre: _nombreCtrl.text.trim(),
      unidad: _unidad,
      cantidad: cantidadTotal,
      stockMinimo: stockMinimoGeneral,
    );

    FocusManager.instance.primaryFocus?.unfocus();
    if (_esEdicion) {
      context.read<InventarioProvider>().editarMaterial(nuevoMaterial, variantesAGuardar).then((_) {
        if (!mounted) return;
        Navigator.pop(context);
      });
    } else {
      context.read<InventarioProvider>().agregarMaterial(nuevoMaterial, variantesAGuardar).then((_) {
        if (!mounted) return;
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
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
                  Text(_esEdicion ? 'Editar material' : 'Nuevo material', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20, right: 20, top: 0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nombre del material *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _nombreCtrl,
                      focusNode: _nombreFocus,
                      decoration: InputDecoration(
                        hintText: 'Ej: Vinchas plásticas',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Unidad de medida. *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 5),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return DropdownMenu<String>(
                          initialSelection: _unidad,
                          width: constraints.maxWidth,
                          menuHeight: 200,
                          onSelected: (val) {
                            if (val != null) setState(() => _unidad = val);
                          },
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: 'Unidades', label: 'Unidades'),
                            DropdownMenuEntry(value: 'Metros', label: 'Metros'),
                            DropdownMenuEntry(value: 'cm', label: 'cm'),
                            DropdownMenuEntry(value: 'Gramos', label: 'Gramos'),
                          ],
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('¿Tiene variantes?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Switch(
                            value: _tieneVariantes,
                            activeTrackColor: const Color(0xFFF9C4D8),
                            activeThumbColor: const Color(0xFFEC6294),
                            onChanged: (val) {
                              setState(() => _tieneVariantes = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (!_tieneVariantes)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Cantidad actual *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 5),
                                TextField(
                                  controller: _cantidadCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Ej. 50',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Stock minimo*', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 5),
                                TextField(
                                  controller: _stockMinCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Ej. 10',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Variante de este material', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                final vf = VarianteForm();
                                vf.nombreCtrl.addListener(_updateState);
                                vf.cantidadCtrl.addListener(_updateState);
                                _variantes.add(vf);
                              });
                            },
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
                                  Text('Añadir variante', style: TextStyle(color: Color(0xFFEC6294), fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ..._variantes.map((v) => Container(
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
                                        const Text('Variante', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _variantes.remove(v);
                                            });
                                          },
                                          child: const Icon(Icons.close, color: Colors.grey, size: 20),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildFieldRow('Nombre variante:', 'Ej. Azul', v.nombreCtrl),
                                    const SizedBox(height: 10),
                                    _buildFieldRow('Cantidad:', 'Ej. 30', v.cantidadCtrl, isNumber: true),
                                    const SizedBox(height: 10),
                                    _buildFieldRow('Stock mínimo:', 'Ej. 5', v.minCtrl, isNumber: true),
                                  ],
                                ),
                              ))
                        ],
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
                        backgroundColor: _isFormValid ? const Color(0xFFEC6294) : const Color(0xFFF9C4D8),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
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

  Widget _buildFieldRow(String label, String hint, TextEditingController ctrl, {bool isNumber = false}) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: ctrl,
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFF2F2F2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class VarianteForm {
  final nombreCtrl = TextEditingController();
  final cantidadCtrl = TextEditingController();
  final minCtrl = TextEditingController();
}
