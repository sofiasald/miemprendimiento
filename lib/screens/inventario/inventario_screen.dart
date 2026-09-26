import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/inventario_provider.dart';
import '../../models/material.dart';
import '../../models/variante.dart';
import '../../models/producto.dart';
import '../../models/producto_material.dart';
import '../../models/combo.dart';
import '../../models/combo_item.dart';
import 'nuevo_material_screen.dart';
import 'nuevo_producto_screen.dart';
import 'nuevo_combo_screen.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InventarioProvider>();
      provider.cargarMateriales();
      provider.cargarProductos();
      provider.cargarCombos();
    });
  }

  void _mostrarDialogoEliminar(BuildContext context, InventarioProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Eliminar material', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de que querés eliminar este material?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.ocultarMaterial(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC6294),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEliminarProducto(BuildContext context, InventarioProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Eliminar producto', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de que querés eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.ocultarProducto(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC6294),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'INVENTARIO',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Barra de Pestañas
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEBEBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildTab('Materiales', 0),
                  _buildTab('Productos', 1),
                  _buildTab('Combos', 2),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Buscador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: provider.buscar,
                decoration: InputDecoration(
                  hintText: _tabIndex == 0 
                      ? 'Buscar en materiales...' 
                      : _tabIndex == 1 
                          ? 'Buscar en productos...' 
                          : 'Buscar en combos...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFEBEBEB),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Lista Dinámica
            Expanded(
              child: _tabIndex == 0 
                  ? _buildMaterialesList(provider) 
                  : _tabIndex == 1 
                      ? _buildProductosList(provider)
                      : _buildCombosList(provider),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEC6294),
        shape: const CircleBorder(),
        onPressed: () async {
          if (_tabIndex == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoMaterialScreen()));
          } else if (_tabIndex == 1) {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoProductoScreen()));
            if (res == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Producto guardado correctamente', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                      Icon(Icons.check_rounded, color: Color(0xFFEC6294), size: 30),
                    ],
                  ),
                  backgroundColor: Colors.white,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  duration: const Duration(seconds: 2),
                  elevation: 4,
                ),
              );
            }
          } else if (_tabIndex == 2) {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const NuevoComboScreen()));
            if (res == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Combo guardado correctamente', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                      Icon(Icons.check_rounded, color: Color(0xFFEC6294), size: 30),
                    ],
                  ),
                  backgroundColor: Colors.white,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  duration: const Duration(seconds: 2),
                  elevation: 4,
                ),
              );
            }
          }
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildProductosList(InventarioProvider provider) {
    if (provider.productos.isEmpty) {
      return const Center(child: Text('No hay productos creados.', style: TextStyle(color: Colors.black54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 80),
      itemCount: provider.productos.length,
      itemBuilder: (context, index) {
        final prod = provider.productos[index];
        final insumos = provider.insumosProductos[prod.id] ?? [];
        String insumosText = insumos.map((i) {
          if (i.cantidad == null) return i.materialNombre;
          return '${i.cantidad!.toStringAsFixed(0)} ${i.materialNombre}';
        }).join(', ');

        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.black12)
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              prod.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final res = await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => NuevoProductoScreen(productoAEditar: prod, insumosAEditar: insumos)
                            ));
                            if (res == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text('Producto guardado correctamente', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                                      Icon(Icons.check_rounded, color: Color(0xFFEC6294), size: 30),
                                    ],
                                  ),
                                  backgroundColor: Colors.white,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                  margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                                  duration: const Duration(seconds: 2),
                                  elevation: 4,
                                ),
                              );
                            }
                          },
                          child: const Icon(Icons.edit, size: 20),
                        ),
                        const SizedBox(width: 15),
                        GestureDetector(
                          onTap: () => _mostrarDialogoEliminarProducto(context, provider, prod.id),
                          child: const Icon(Icons.delete, size: 20, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '\$ ${prod.precio.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                ),
                if (insumosText.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text('Insumos: $insumosText', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterialesList(InventarioProvider provider) {
    if (provider.materiales.isEmpty) {
      return const Center(child: Text('No hay materiales registrados aún.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: provider.materiales.length,
      itemBuilder: (context, index) {
        final material = provider.materiales[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.black12)
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              material.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          if (provider.variantes[material.id] != null && provider.variantes[material.id]!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${provider.variantes[material.id]!.length} variaciones',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final variantes = await provider.obtenerVariantes(material.id);
                            if (!mounted) return;
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => NuevoMaterialScreen(materialAEditar: material, variantesAEditar: variantes)
                            ));
                          },
                          child: const Icon(Icons.edit, size: 20),
                        ),
                        const SizedBox(width: 15),
                        GestureDetector(
                          onTap: () => _mostrarDialogoEliminar(context, provider, material.id),
                          child: const Icon(Icons.delete, size: 20, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildCardContent(material, provider.variantes[material.id] ?? []),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(MaterialItem material, List<Variante> variantes) {
    if (variantes.isEmpty) {
      bool stockBajo = material.cantidad <= material.stockMinimo;
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(TextSpan(
                children: [
                  const TextSpan(text: 'Stock: ', style: TextStyle(color: Colors.black54)),
                  TextSpan(text: '${material.cantidad.toStringAsFixed(0)} ${material.unidad.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              )),
              Text.rich(TextSpan(
                children: [
                  const TextSpan(text: 'Mínimo: ', style: TextStyle(color: Colors.black54)),
                  TextSpan(text: '${material.stockMinimo.toStringAsFixed(0)} ${material.unidad.toLowerCase()[0]}', style: const TextStyle(fontWeight: FontWeight.bold)), // e.g. "5 u"
                ],
              )),
            ],
          ),
          if (stockBajo) _buildStockBajoPill(),
        ],
      );
    } else {
      bool algunStockBajo = variantes.any((v) => v.cantidad <= v.stockMinimo);
      return Column(
        children: [
          ...variantes.map((v) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(TextSpan(
                  children: [
                    TextSpan(text: '${v.nombre}: ', style: const TextStyle(color: Colors.black54)),
                    TextSpan(text: '${v.cantidad.toStringAsFixed(0)} ${material.unidad.toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                )),
                Text.rich(TextSpan(
                  children: [
                    const TextSpan(text: '(Mínimo: ', style: TextStyle(color: Colors.black54)),
                    TextSpan(text: '${v.stockMinimo.toStringAsFixed(0)} ${material.unidad.toLowerCase()[0]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ')', style: TextStyle(color: Colors.black54)),
                  ],
                )),
              ],
            ),
          )),
          if (algunStockBajo) _buildStockBajoPill(),
        ],
      );
    }
  }

  Widget _buildStockBajoPill() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEC6294),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Stock bajo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildCombosList(InventarioProvider provider) {
    if (provider.combos.isEmpty) {
      return const Center(child: Text('No hay combos creados.', style: TextStyle(color: Colors.black54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 80),
      itemCount: provider.combos.length,
      itemBuilder: (context, index) {
        final combo = provider.combos[index];
        final items = provider.itemsPorCombo[combo.id] ?? [];
        
        final prods = items.where((i) => i.tipo == 'producto');
        final mats = items.where((i) => i.tipo == 'material');
        
        String prodText = prods.map((i) => i.cantidad != null ? '${i.cantidad!.toStringAsFixed(0)} ${i.nombre}' : i.nombre).join(', ');
        String matText = mats.map((i) => i.cantidad != null ? '${i.cantidad!.toStringAsFixed(0)} ${i.nombre}' : i.nombre).join(', ');

        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.black12)
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              combo.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final res = await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => NuevoComboScreen(comboAEditar: combo, itemsAEditar: items)
                            ));
                            if (res == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text('Combo guardado correctamente', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                                      Icon(Icons.check_rounded, color: Color(0xFFEC6294), size: 30),
                                    ],
                                  ),
                                  backgroundColor: Colors.white,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                  margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                                  duration: const Duration(seconds: 2),
                                  elevation: 4,
                                ),
                              );
                            }
                          },
                          child: const Icon(Icons.edit, size: 20),
                        ),
                        const SizedBox(width: 15),
                        GestureDetector(
                          onTap: () => _mostrarDialogoEliminarCombo(context, provider, combo.id),
                          child: const Icon(Icons.delete, size: 20, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '\$ ${combo.precio.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                ),
                if (prodText.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text('Productos: $prodText', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
                if (matText.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text('Insumos: $matText', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoEliminarCombo(BuildContext context, InventarioProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Eliminar combo', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro que deseas eliminar este combo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.ocultarCombo(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC6294),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEC6294) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
