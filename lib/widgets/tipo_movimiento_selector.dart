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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(10),
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: activo ? const Color(0xFFEC6294) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: activo ? Colors.white : Colors.grey[600],
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
