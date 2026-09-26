class ComboItem {
  final String elementoId;
  final String tipo; // 'producto' o 'material'
  final String nombre;
  final double? cantidad; // null si es opcional/referencial

  ComboItem({
    required this.elementoId,
    required this.tipo,
    required this.nombre,
    this.cantidad,
  });

  Map<String, dynamic> toMap(String comboId) {
    return {
      'comboId': comboId,
      'productoId': tipo == 'producto' ? elementoId : null,
      'materialId': tipo == 'material' ? elementoId : null,
      'cantidad': cantidad,
    };
  }

  factory ComboItem.fromMap(Map<String, dynamic> map) {
    return ComboItem(
      elementoId: map['elementoId'],
      tipo: map['tipo'],
      nombre: map['nombre'],
      cantidad: map['cantidad'] is int ? (map['cantidad'] as int).toDouble() : map['cantidad'],
    );
  }
}
