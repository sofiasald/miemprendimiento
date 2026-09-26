import 'package:uuid/uuid.dart';

class Pedido {
  final String id;
  String? productoId;
  String? comboId;
  String cliente;
  String fechaEntrega;
  bool visible;

  Pedido({
    String? id,
    this.productoId,
    this.comboId,
    required this.cliente,
    required this.fechaEntrega,
    this.visible = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'productoId': productoId,
        'comboId': comboId,
        'cliente': cliente,
        'fechaEntrega': fechaEntrega,
        'visible': visible ? 1 : 0,
      };

  factory Pedido.fromMap(Map<String, dynamic> m) => Pedido(
        id: m['id'],
        productoId: m['productoId'],
        comboId: m['comboId'],
        cliente: m['cliente'],
        fechaEntrega: m['fechaEntrega'],
        visible: m['visible'] == 1,
      );
}
