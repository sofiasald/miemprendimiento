import 'package:uuid/uuid.dart';

class Pedido {
  final String id;
  String? productoId;
  String? comboId;
  String nombreItem;     // Nombre del producto o combo encargado A
  String cliente;        // Nombre o contacto del cliente
  double monto;          // Precio pactado del encargo A
  DateTime fechaEntrega; // Fecha acordada para la entrega A
  bool visible;

  Pedido({
    String? id,
    this.productoId,
    this.comboId,
    required this.nombreItem,
    required this.cliente,
    required this.monto,
    required this.fechaEntrega,
    this.visible = true,
  }) : id = id ?? const Uuid().v4();

  /// Serializa los datos para insertarlos o actualizarlos en SQLite. A
  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'comboId': comboId,
    'nombreItem': nombreItem,
    'cliente': cliente,
    'monto': monto,
    'fechaEntrega': fechaEntrega.toIso8601String(), // Se guarda como texto ISO estándar
    'visible': visible ? 1 : 0,
  };

  /// Deserializa los datos leídos desde SQLite. A
  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      id: map['id'] as String,
      productoId: map['productoId'] as String?,
      comboId: map['comboId'] as String?,
      nombreItem: (map['nombreItem'] as String?) ?? 'Pedido personalizado',
      cliente: map['cliente'] as String,
      monto: (map['monto'] as num?)?.toDouble() ?? 0.0,
      fechaEntrega: map['fechaEntrega'] is String
          ? DateTime.parse(map['fechaEntrega'] as String)
          : DateTime.now(),
      visible: (map['visible'] as int?) == 1,
    );
  }
}
