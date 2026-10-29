// lib/utils/utils.dart

/// Clase utilitaria con funciones puras e independientes.
/// No interactúa con SQLite ni con la UI directamente (Alta Cohesión y Bajo Acoplamiento).
class AppUtils {
  AppUtils._(); // Constructor privado para evitar instanciación

  /// Formatea un monto numérico con separador de miles.
  /// Ej: 123456.0 -> "123.456"
  static String formatearMonto(double monto) {
    final partes = monto.toInt().toString();
    return partes.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Formatea una fecha en formato descriptivo mensual.
  /// Ej: DateTime(2026, 10, 23) -> "23 Oct 2026"
  static String formatearFecha(DateTime dt) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${meses[dt.month - 1]} ${dt.year}';
  }

  /// Formatea una fecha en formato estándar numérico.
  /// Ej: DateTime(2026, 10, 23) -> "23/10/2026"
  static String formatearFechaCorta(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year}';
  }

  /// Convierte una cadena ISO 8601 a fecha y hora legible.
  /// Ej: "2026-10-23T14:30:00" -> "23/10/2026 • 14:30 hs"
  static String formatearFechaHora(String? fechaIso) {
    if (fechaIso == null || fechaIso.isEmpty) return 'Fecha no disponible';
    try {
      final dt = DateTime.parse(fechaIso);
      final dia = dt.day.toString().padLeft(2, '0');
      final mes = dt.month.toString().padLeft(2, '0');
      final hora = dt.hour.toString().padLeft(2, '0');
      final minutos = dt.minute.toString().padLeft(2, '0');
      return '$dia/$mes/${dt.year} • $hora:$minutos hs';
    } catch (_) {
      return fechaIso;
    }
  }

  /// Función matemática pura que calcula los días restantes para la entrega de un pedido.
  static int calcularDiasRestantes(DateTime fechaActual, DateTime fechaEntrega) {
    final fActual = DateTime(fechaActual.year, fechaActual.month, fechaActual.day);
    final fEntrega = DateTime(fechaEntrega.year, fechaEntrega.month, fechaEntrega.day);
    return fEntrega.difference(fActual).inDays;
  }
}