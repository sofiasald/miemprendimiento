import 'package:uuid/uuid.dart';

class Gasto {
  final String id;
  String? materialId; // Insumo comprado (opcional si es un gasto general) A
  String? materialNombre; // Nombre histórico del material comprado A 
  String? varianteId; // Variante específica de color/medida (opcional) A
  String? varianteNombre; // Nombre histórico de la variante (color/tamaño) A
  double cantidad; // Cantidad adquirida para sumar al stock A
  double monto; //Dinero pagado
  String fecha;
  bool visible; // Borrado logico para SQLite

  Gasto({
    String? id,
    this.materialId, // A
    this.materialNombre, // A
    this.varianteId, // A
    this.varianteNombre, // A
    this.cantidad = 0.0, // A
    required this.monto,
    String? fecha,
    this.visible = true,
  }) : id = id ?? const Uuid().v4(),
  fecha = fecha ?? DateTime.now().toIso8601String(); // Fecha automática si la pantalla no la provee

  //A
  Map<String, dynamic> toMap() => {
        'id': id,
        'materialId': materialId,
        'materialNombre': materialNombre,
        'varianteId' : varianteId,
        'varianteNombre': varianteNombre,
        'cantidad' : cantidad,
        'monto': monto,
        'fecha': fecha,
        'visible': visible ? 1 : 0,
      };

  // Convierte un mapa de SQLite en una instancia del objeto Gasto. A
  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'] as String,
      materialId: map['materialId'] as String?,
      materialNombre: map['materialNombre'] as String?,
      varianteId: map['varianteId'] as String?,
      varianteNombre: map['varianteNombre'] as String?,
      cantidad: (map['cantidad'] as num?)?.toDouble() ?? 0.0,
      monto: (map['monto'] as num).toDouble(),
      fecha: map['fecha'] as String,
      visible: (map['visible'] as int?) == 1,
    );
  }
}