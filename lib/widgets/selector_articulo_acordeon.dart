import 'package:flutter/material.dart';

/// Colores extraídos del CSS de Figma
class AtelierColors {
  static const rosa = Color(0xFFE85E98);
  static const rosaClaro = Color(0xFFFEC1E6);
  static const rosaSuave = Color(0xFFF79AD3);
  static const grisFondo = Color(0xFFF8F9FA);
  static const grisBorde = Color(0xFFE0E0E0);
  static const grisTexto = Color(0xFF757575);
  static const negroSuave = Color(0xFF212121);
  static const grisFila = Color(0xFFF0F0F0);
}

/// Fila de artículo dentro del acordeón.
class FilaArticulo extends StatelessWidget {
  final String nombre;
  final String precio; // ya formateado, ej "$ 4.500"
  final bool seleccionado;
  final VoidCallback onTap;
  final bool mostrarDivisor;

  const FilaArticulo({
    super.key,
    required this.nombre,
    required this.precio,
    required this.onTap,
    this.seleccionado = false,
    this.mostrarDivisor = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: seleccionado
                  ? AtelierColors.rosaClaro.withValues(alpha: 0.25)
                  : Colors.transparent,
              border: Border(
                left: BorderSide(color: AtelierColors.grisBorde, width: 1),
                right: BorderSide(color: AtelierColors.grisBorde, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AtelierColors.negroSuave,
                    ),
                  ),
                ),
                Text(
                  precio,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AtelierColors.negroSuave,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (mostrarDivisor)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(color: AtelierColors.grisBorde),
            ),
          ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
