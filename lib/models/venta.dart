import 'package:uuid/uuid.dart';

class Venta {
  final String id;
  String? productoId;
  String? comboId;
  String? pedidoId;
  String? cliente;
  String? nombreItem; // Nombre histórico del producto o combo vendido
  String? variante;   // Variantes seleccionadas (ej: "tutú: azul, gemas: rosa")
  int cantidad;       // Cantidad de unidades vendidas
  double monto;
  String fecha;
  String tipo;        // 'directa' o 'pedido'
  String? fotoPath;
  bool visible;

  Venta({
    String? id,
    this.productoId,
    this.comboId,
    this.pedidoId,
    this.cliente,
    this.nombreItem,
    this.variante,
    this.cantidad = 1,
    required this.monto,
    String? fecha,
    this.tipo = 'directa',
    this.fotoPath,
    this.visible = true,
  }) : id = id ?? const Uuid().v4(),
       fecha = fecha ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'comboId': comboId,
    'pedidoId': pedidoId,
    'cliente': cliente,
    'nombreItem': nombreItem,
    'variante': variante,
    'cantidad': cantidad,
    'monto': monto,
    'fecha': fecha,
    'tipo': tipo,
    'fotoPath': fotoPath,
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
      variante: map['variante'] as String?,
      cantidad: (map['cantidad'] as num?)?.toInt() ?? 1,
      monto: (map['monto'] as num).toDouble(),
      fecha: map['fecha'] as String,
      tipo: (map['tipo'] as String?) ?? (map['pedidoId'] != null ? 'pedido' : 'directa'),
      fotoPath: map['fotoPath'] as String?,
      visible: (map['visible'] as int?) == 1,
    );
  }
}