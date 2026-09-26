import 'package:uuid/uuid.dart';

class Variante {
  final String id;
  final String materialId;
  String nombre;
  double cantidad;
  double stockMinimo;
  bool visible;

  Variante({
    String? id,
    required this.materialId,
    required this.nombre,
    this.cantidad = 0,
    this.stockMinimo = 0,
    this.visible = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'materialId': materialId,
        'nombre': nombre,
        'cantidad': cantidad,
        'stockMinimo': stockMinimo,
        'visible': visible ? 1 : 0,
      };

  factory Variante.fromMap(Map<String, dynamic> m) => Variante(
        id: m['id'],
        materialId: m['materialId'],
        nombre: m['nombre'],
        cantidad: m['cantidad'] ?? 0,
        stockMinimo: m['stockMinimo'] ?? 0,
        visible: m['visible'] == 1,
      );
}
