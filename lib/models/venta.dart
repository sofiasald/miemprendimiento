import 'package:uuid/uuid.dart';

class Venta {
  final String id;
  String? productoId;
  String? comboId;
  String? nombreItem; // Nombre histórico del producto o combo vendido. A
  double monto;
  String fecha;
  bool visible;

  Venta({
    String? id,
    this.productoId,
    this.comboId,
    this.nombreItem, //A
    required this.monto,
    String? fecha,
    this.visible = true,
  }) : id = id ?? const Uuid().v4(),
  fecha = fecha ?? DateTime.now().toIso8601String(); // Si no se pasa fecha, toma el momento exacto actual

  Map<String, dynamic> toMap() => {
        'id': id,
        'productoId': productoId,
        'comboId': comboId,
        'nombreItem': nombreItem,
        'monto': monto,
        'fecha': fecha,
        'visible': visible ? 1 : 0,
      };

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as String,
      productoId: map['productoId'] as String?,
      comboId: map['comboId'] as String?,
      nombreItem: map['nombreItem'] as String?,
      monto: (map['monto'] as num).toDouble(),
      fecha: map['fecha'] as String,
      visible: (map['visible'] as int?) == 1,
    );
  }
}
