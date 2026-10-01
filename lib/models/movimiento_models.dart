enum TipoMovimiento { pedido, venta, gasto }

class Producto {
  final String id;
  final String nombre;
  final double precio;
  Producto({required this.id, required this.nombre, required this.precio});
}

class Combo {
  final String id;
  final String nombre;
  final double precio;
  Combo({required this.id, required this.nombre, required this.precio});
}

class MaterialItem {
  final String id;
  final String nombre;
  final String unidad;
  double cantidad;
  final double stockMinimo;
  MaterialItem({
    required this.id,
    required this.nombre,
    required this.unidad,
    required this.cantidad,
    required this.stockMinimo,
  });
}

class Variante {
  final String id;
  final String materialId;
  final String nombre;
  double cantidad;
  Variante({
    required this.id,
    required this.materialId,
    required this.nombre,
    required this.cantidad,
  });
}

class MaterialConsumo {
  final String materialId;
  final double cantidad;
  MaterialConsumo({required this.materialId, required this.cantidad});
}

// Validación de stock (Sprint 4 - Paso 4)
bool hayStockSuficiente(
  List<MaterialConsumo> consumos,
  List<MaterialItem> materialesDisponibles,
) {
  for (final c in consumos) {
    final mat = materialesDisponibles.firstWhere((m) => m.id == c.materialId);
    if (mat.cantidad < c.cantidad) return false;
  }
  return true;
}
