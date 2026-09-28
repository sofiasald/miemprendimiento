import 'package:uuid/uuid.dart';

/// Un pedido a entregar en el futuro. NO descuenta stock todavía: eso ocurre
/// recién cuando se marca como "Entregado" (Sprint 5), momento en el que se
/// convierte en una Venta.
class Pedido {
  final String id;
  final String? productoId;
  final String? comboId;
  final String nombreItem;
  final String cliente;
  final double monto;
  final DateTime fechaEntrega;
  final bool visible;

  Pedido({
    String? id,
    this.productoId,
    this.comboId,
    required this.nombreItem,
    required this.cliente,
    required this.monto,
    required this.fechaEntrega,
    this.visible = true,
  }) : assert(
         productoId != null || comboId != null,
         'Un pedido debe referenciar un producto o un combo',
       ),
       id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'comboId': comboId,
    'nombreItem': nombreItem,
    'cliente': cliente,
    'monto': monto,
    'fechaEntrega': fechaEntrega.toIso8601String(),
    'visible': visible ? 1 : 0,
  };

  factory Pedido.fromMap(Map<String, dynamic> m) => Pedido(
    id: m['id'] as String,
    productoId: m['productoId'] as String?,
    comboId: m['comboId'] as String?,
    nombreItem: m['nombreItem'] as String,
    cliente: m['cliente'] as String,
    monto: (m['monto'] as num).toDouble(),
    fechaEntrega: DateTime.parse(m['fechaEntrega'] as String),
    visible: m['visible'] == 1,
  );
}
