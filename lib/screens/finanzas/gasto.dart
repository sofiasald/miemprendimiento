import 'package:uuid/uuid.dart';

class Gasto {
  final String id;
  final String materialId;
  final double monto;
  final DateTime fecha;
  final bool visible;

  // Solo en memoria (no van a la tabla)
  final String materialNombre;
  final String? varianteId;
  final String? varianteNombre;
  final double cantidad;

  Gasto({
    String? id,
    required this.materialId,
    required this.monto,
    DateTime? fecha,
    this.visible = true,
    this.materialNombre = '',
    this.varianteId,
    this.varianteNombre,
    this.cantidad = 0,
  }) : id = id ?? const Uuid().v4(),
       fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'materialId': materialId,
    'monto': monto,
    'fecha': fecha.toIso8601String(),
    'visible': visible ? 1 : 0,
    // materialNombre, varianteId, varianteNombre, cantidad → NO van
  };

  factory Gasto.fromMap(Map<String, dynamic> m) => Gasto(
    id: m['id'] as String,
    materialId: m['materialId'] as String,
    monto: (m['monto'] as num).toDouble(),
    fecha: DateTime.parse(m['fecha'] as String),
    visible: m['visible'] == 1,
  );
}
