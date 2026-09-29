import 'package:uuid/uuid.dart';

class Venta {
  final String id;
  final String? productoId;
  final String? comboId;
  final double monto;
  final DateTime fecha;
  final bool visible;

  // Solo en memoria (no van a la tabla)
  final String nombreItem;

  Venta({
    String? id,
    this.productoId,
    this.comboId,
    required this.monto,
    DateTime? fecha,
    this.visible = true,
    this.nombreItem = '',
  }) : assert(
         productoId != null || comboId != null,
         'Una venta debe referenciar un producto o un combo',
       ),
       id = id ?? const Uuid().v4(),
       fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'comboId': comboId,
    'monto': monto,
    'fecha': fecha.toIso8601String(),
    'visible': visible ? 1 : 0,
  };

  factory Venta.fromMap(Map<String, dynamic> m) => Venta(
    id: m['id'] as String,
    productoId: m['productoId'] as String?,
    comboId: m['comboId'] as String?,
    monto: (m['monto'] as num).toDouble(),
    fecha: DateTime.parse(m['fecha'] as String),
    visible: m['visible'] == 1,
    // nombreItem no está en la tabla: queda vacío al reconstruir desde DB
  );
}
