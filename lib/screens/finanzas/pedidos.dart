import 'package:uuid/uuid.dart';

class Pedido {
  final String id;
  final String? productoId;
  final String? comboId;
  final String cliente;
  final DateTime fechaEntrega;
  final bool visible;

  // Solo en memoria (no van a la tabla)
  final String nombreItem;
  final double monto;

  Pedido({
    String? id,
    this.productoId,
    this.comboId,
    required this.cliente,
    required this.fechaEntrega,
    this.visible = true,
    this.nombreItem = '',
    this.monto = 0,
  }) : assert(
         productoId != null || comboId != null,
         'Un pedido debe referenciar un producto o un combo',
       ),
       id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'comboId': comboId,
    'cliente': cliente,
    'fechaEntrega': fechaEntrega.toIso8601String(),
    'visible': visible ? 1 : 0,
    // nombreItem y monto → NO van
  };

  factory Pedido.fromMap(Map<String, dynamic> m) => Pedido(
    id: m['id'] as String,
    productoId: m['productoId'] as String?,
    comboId: m['comboId'] as String?,
    cliente: m['cliente'] as String,
    fechaEntrega: DateTime.parse(m['fechaEntrega'] as String),
    visible: m['visible'] == 1,
  );
}
