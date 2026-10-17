import 'package:uuid/uuid.dart';

class Venta {
  final String id;
  String? productoId;
  String? comboId;
  String? pedidoId;
  String? cliente;
  String? nombreItem; // Nombre histórico del producto o combo vendido
  double monto;
  String fecha;
  String tipo; // 'directa' o 'pedido'
  bool visible;

  Venta({
    String? id,
    this.productoId,
    this.comboId,
    this.pedidoId,
    this.cliente,
    this.nombreItem,
    required this.monto,
    String? fecha,
    this.tipo = 'directa',
    this.visible = true,
  }) : id = id ?? const Uuid().v4(),
       fecha = fecha ?? DateTime.now().toIso8601String(); // Si no se pasa fecha, toma el momento exacto actual

  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'comboId': comboId,
    'pedidoId': pedidoId,
    'cliente': cliente,
    'nombreItem': nombreItem,
    'monto': monto,
    'fecha': fecha,
    'tipo': tipo,
    'visible': visible ? 1 : 0,
  };

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] as String,
      productoId: map['productoId'] as String?,
      comboId: map['comboId'] as String?,
      pedidoId: map['pedidoId'] as String?,
      cliente: map['cliente'] as String?,
      nombreItem: map['nombreItem'] as String?,
      monto: (map['monto'] as num).toDouble(),
      fecha: map['fecha'] as String,
      tipo: (map['tipo'] as String?) ?? (map['pedidoId'] != null ? 'pedido' : 'directa'),
      visible: (map['visible'] as int?) == 1,
    );
  }
}
