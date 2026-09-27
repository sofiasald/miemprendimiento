import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/producto.dart';
import '../../models/combo.dart';

/// Modal para elegir un Producto o un Combo (para registrar una Venta o un
/// Pedido). Al tocar un elemento, devuelve la instancia via
/// Navigator.pop(context, item); el que llama distingue el tipo con
/// `item is Producto` / `item is Combo`, igual que ya hacen las pantallas
/// de Inventario con SeleccionarMaterialModal.
class SeleccionarProductoComboModal extends StatefulWidget {
  const SeleccionarProductoComboModal({super.key});

  @override
  State<SeleccionarProductoComboModal> createState() => _SeleccionarProductoComboModalState();
}

class _SeleccionarProductoComboModalState extends State<SeleccionarProductoComboModal> {
  int _tabIndex = 0; // 0 = Productos, 1 = Combos
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();

    final List<dynamic> elementos = _tabIndex == 0
        ? provider.productos.where((p) => p.nombre.toLowerCase().contains(_busqueda.toLowerCase())).toList()
        : provider.combos.where((c) => c.nombre.toLowerCase().contains(_busqueda.toLowerCase())).toList();

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
                child: Text('¿Qué vendiste?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Positioned(
                right: 20,
                top: -5,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 28),
                ),
              ),
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
                        child: Text('Combos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                hintText: _tabIndex == 0 ? 'Buscar producto' : 'Buscar combo',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: elementos.isEmpty
                ? Center(
                    child: Text(
                      _tabIndex == 0 ? 'No hay productos cargados.' : 'No hay combos cargados.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: elementos.length,
                    itemBuilder: (ctx, i) {
                      final el = elementos[i];
                      final precio = el is Producto ? el.precio : (el as Combo).precio;
                      return GestureDetector(
                        onTap: () => Navigator.pop(context, el),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: Text(el.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                Text(
                                  '\$ ${precio.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
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