import 'package:uuid/uuid.dart';

class MaterialItem {
  final String id;
  String nombre;
  String unidad;
  double cantidad;
  double stockMinimo;
  bool visible;

  MaterialItem({
    String? id,
    required this.nombre,
    required this.unidad,
    this.cantidad = 0,
    this.stockMinimo = 0,
    this.visible = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'unidad': unidad,
        'cantidad': cantidad,
        'stockMinimo': stockMinimo,
        'visible': visible ? 1 : 0,
      };

  factory MaterialItem.fromMap(Map<String, dynamic> m) => MaterialItem(
        id: m['id'],
        nombre: m['nombre'],
        unidad: m['unidad'],
        cantidad: m['cantidad'] ?? 0,
        stockMinimo: m['stockMinimo'] ?? 0,
        visible: m['visible'] == 1,
      );
}
