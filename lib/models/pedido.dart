//import 'package:uuid/uuid.dart';

/// Modelo de datos para pedidos de Atelier con soporte de ciclo de vida e inventario.
class Pedido {
  final String id;
  final String? productoId; // ID del producto asociado en inventario (si aplica)
  final String? comboId;    // ID del combo asociado en inventario (si aplica)
  String cliente;
  String nombreItem;
  String variante;
  int cantidad;
  double monto;
  DateTime fechaEntrega;      // Fecha pactada original
  DateTime? fechaRegistro;    // Cuándo el cliente hizo el encargo
  DateTime? fechaEntregaReal; // Cuándo se entregó efectivamente
  String observaciones;       // Señas, notas de diseño, entrega
  String estado;              // 'pendiente', 'entregado', 'cancelado'
  String? fotoPath;

  Pedido({
    String? id, // Opcional: si viene de un formulario nuevo, se autogenera abajo
    this.productoId,
    this.comboId,
    required this.cliente,
    required this.nombreItem,
    this.variante = 'Estándar',
    this.cantidad = 1,
    required this.monto,
    required this.fechaEntrega,
    this.fechaRegistro,
    this.fechaEntregaReal,
    this.observaciones = '',
    this.estado = 'pendiente',
    this.fotoPath,
  }) : id = id ?? 'ped_${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toMap() => {
    'id': id,
    'productoId': productoId,
    'comboId': comboId,
    'cliente': cliente,
    'nombreItem': nombreItem,
    'variante': variante,
    'cantidad': cantidad,
    'monto': monto,
    'fechaEntrega': fechaEntrega.toIso8601String(),
    'fechaRegistro': (fechaRegistro ?? DateTime.now()).toIso8601String(),
    'fechaEntregaReal': fechaEntregaReal?.toIso8601String(),
    'observaciones': observaciones,
    'estado': estado,
    'fotoPath': fotoPath,
  };

  factory Pedido.fromMap(Map<String, dynamic> map) => Pedido(
    id: map['id']?.toString(),
    productoId: map['productoId']?.toString(),
    comboId: map['comboId']?.toString(),
    cliente: map['cliente'] ?? '',
    nombreItem: map['nombreItem'] ?? '',
    variante: map['variante'] ?? 'Estándar',
    cantidad: map['cantidad'] ?? 1,
    monto: (map['monto'] as num?)?.toDouble() ?? 0.0,
    fechaEntrega: map['fechaEntrega'] != null
        ? (DateTime.tryParse(map['fechaEntrega'].toString()) ?? DateTime.now())
        : DateTime.now(),
    fechaRegistro: map['fechaRegistro'] != null
        ? DateTime.tryParse(map['fechaRegistro'].toString())
        : null,
    fechaEntregaReal: map['fechaEntregaReal'] != null
        ? DateTime.tryParse(map['fechaEntregaReal'].toString())
        : null,
    observaciones: map['observaciones'] ?? '',
    estado: map['estado'] ?? 'pendiente',
    fotoPath: map['fotoPath'] as String?,
  );
}