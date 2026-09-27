import 'package:uuid/uuid.dart';

/// Un gasto registrado: compra de un material (o una variante puntual)
/// que aumenta su stock.
class Gasto {
  final String id;
  final String materialId;
  final String materialNombre;
  final String? varianteId;
  final String? varianteNombre;
  final double cantidad; // cantidad de material que ingresa al stock
  final double monto; // dinero gastado
  final DateTime fecha;
  final bool visible;

  Gasto({
    String? id,
    required this.materialId,
    required this.materialNombre,
    this.varianteId,
    this.varianteNombre,
    required this.cantidad,
    required this.monto,
    DateTime? fecha,
    this.visible = true,
  })  : id = id ?? const Uuid().v4(),
        fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'materialId': materialId,
        'materialNombre': materialNombre,
        'varianteId': varianteId,
        'varianteNombre': varianteNombre,
        'cantidad': cantidad,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
        'visible': visible ? 1 : 0,
      };

  factory Gasto.fromMap(Map<String, dynamic> m) => Gasto(
        id: m['id'] as String,
        materialId: m['materialId'] as String,
        materialNombre: m['materialNombre'] as String,
        varianteId: m['varianteId'] as String?,
        varianteNombre: m['varianteNombre'] as String?,
        cantidad: (m['cantidad'] as num).toDouble(),
        monto: (m['monto'] as num).toDouble(),
        fecha: DateTime.parse(m['fecha'] as String),
        visible: m['visible'] == 1,
      );
}