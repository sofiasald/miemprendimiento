import 'package:uuid/uuid.dart';

class Combo {
  final String id;
  String nombre;
  double precio;
  String? descripcion;
  bool visible;

  Combo({
    String? id,
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.visible = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'precio': precio,
        'descripcion': descripcion,
        'visible': visible ? 1 : 0,
      };

  factory Combo.fromMap(Map<String, dynamic> m) => Combo(
        id: m['id'],
        nombre: m['nombre'],
        precio: m['precio'],
        descripcion: m['descripcion'],
        visible: m['visible'] == 1,
      );
}
