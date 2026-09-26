import 'package:uuid/uuid.dart';

class Gasto {
  final String id;
  String materialId;
  double monto;
  String fecha;
  bool visible;

  Gasto({
    String? id,
    required this.materialId,
    required this.monto,
    required this.fecha,
    this.visible = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'materialId': materialId,
        'monto': monto,
        'fecha': fecha,
        'visible': visible ? 1 : 0,
      };

  factory Gasto.fromMap(Map<String, dynamic> m) => Gasto(
        id: m['id'],
        materialId: m['materialId'],
        monto: m['monto'],
        fecha: m['fecha'],
        visible: m['visible'] == 1,
      );
}
