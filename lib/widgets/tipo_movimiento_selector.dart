import 'package:flutter/material.dart';

import '../models/movimiento_models.dart';

class TipoMovimientoSelector extends StatelessWidget {
  final TipoMovimiento seleccionado;
  final ValueChanged<TipoMovimiento> onChanged;

  const TipoMovimientoSelector({
    super.key,
    required this.seleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _tab('Pedido', TipoMovimiento.pedido),
          _tab('Venta', TipoMovimiento.venta),
          _tab('Gasto', TipoMovimiento.gasto),
        ],
      ),
    );
  }

  Widget _tab(String label, TipoMovimiento tipo) {
    final activo = seleccionado == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tipo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: activo ? const Color(0xFFE85E98) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: activo
                ? [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(4, 0),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: activo ? Colors.white : const Color(0xFF757575),
            ),
          ),
        ),
      ),
    );
  }
}
