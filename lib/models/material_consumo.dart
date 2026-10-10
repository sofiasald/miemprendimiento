/// Representa el consumo (venta) o la reposición (gasto) de un material,
/// resuelto a nivel de variante concreta cuando el material tiene variantes.
enum TipoMaterialConsumo { venta, gasto }

class MaterialConsumo {
  final String materialId;
  final String materialNombre;
  final String? varianteId; // null si el material NO tiene variantes
  final String? varianteNombre;
  final TipoMaterialConsumo tipo;
  final double cantidad;

  MaterialConsumo({
    required this.materialId,
    required this.materialNombre,
    this.varianteId,
    this.varianteNombre,
    required this.tipo,
    required this.cantidad,
  });

  /// Devuelve el signo del movimiento para el inventario:
  /// - venta => resta
  /// - gasto/reposición => suma
  double get cantidadAjuste =>
      tipo == TipoMaterialConsumo.venta ? -cantidad : cantidad;

  bool get esVenta => tipo == TipoMaterialConsumo.venta;
  bool get esGasto => tipo == TipoMaterialConsumo.gasto;
}
