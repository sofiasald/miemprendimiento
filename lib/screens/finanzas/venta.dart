/// Una venta registrada. Referencia un Producto O un Combo (nunca ambos) y
/// guarda una "foto" del nombre y el monto al momento de vender, para que el
/// historial no cambie si el precio del producto se edita después.
class Venta {
  final String id;
  final String? productoId;
  final String? comboId;
  final String nombreItem;
  final double monto;
  final DateTime fecha;
  final bool visible;

  Venta({
    String? id,
    this.productoId,
    this.comboId,
    required this.nombreItem,
    required this.monto,
    DateTime? fecha,
    this.visible = true,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'comboId': comboId,
    'nombreItem': nombreItem,
    'monto': monto,
    'fecha': fecha.toIso8601String(),
    'visible': visible ? 1 : 0,
  };

  factory Venta.fromMap(Map<String, dynamic> m) => Venta(
    id: m['id'] as String,
    productoId: m['productoId'] as String?,
    comboId: m['comboId'] as String?,
    nombreItem: m['nombreItem'] as String,
    monto: (m['monto'] as num).toDouble(),
    fecha: DateTime.parse(m['fecha'] as String),
    visible: m['visible'] == 1,
  );
}
