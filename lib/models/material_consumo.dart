/// Representa el consumo (venta) o la reposición (gasto) de un material,
/// resuelto a nivel de variante concreta cuando el material tiene variantes.
class MaterialConsumo {
  final String materialId;
  final String materialNombre;
  final String? varianteId; // null si el material NO tiene variantes
  final String? varianteNombre;
  final double cantidad;

  MaterialConsumo({
    required this.materialId,
    required this.materialNombre,
    this.varianteId,
    this.varianteNombre,
    required this.cantidad,
  });
}
