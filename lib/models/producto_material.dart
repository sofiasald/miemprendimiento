class ProductoMaterial {
  String materialId;
  String materialNombre;
  String materialUnidad;
  double? cantidad; // Puede ser null si es referencial

  ProductoMaterial({
    required this.materialId,
    required this.materialNombre,
    required this.materialUnidad,
    this.cantidad,
  });
}
