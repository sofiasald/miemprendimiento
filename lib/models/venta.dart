import 'package:uuid/uuid.dart';

class Venta {
  final String id;
  String? productoId;
  String? comboId;
  double monto;
  String fecha;
  bool visible;

  Venta({
    String? id,
    this.productoId,
    this.comboId,
    required this.monto,
    required this.fecha,
    this.visible = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'productoId': productoId,
        'comboId': comboId,
        'monto': monto,
        'fecha': fecha,
        'visible': visible ? 1 : 0,
      };

  factory Venta.fromMap(Map<String, dynamic> m) => Venta(
        id: m['id'],
        productoId: m['productoId'],
        comboId: m['comboId'],
        monto: m['monto'],
        fecha: m['fecha'],
        visible: m['visible'] == 1,
      );
}
