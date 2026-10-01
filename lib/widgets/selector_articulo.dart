import 'package:flutter/material.dart';

class ArticuloItem {
  final String id;
  final String nombre;
  final double precio;
  const ArticuloItem({
    required this.id,
    required this.nombre,
    required this.precio,
  });
}

class SelectorArticulo extends StatefulWidget {
  final List<ArticuloItem> items;
  final String? seleccionadoId;
  final ValueChanged<ArticuloItem> onSeleccionado;

  const SelectorArticulo({
    super.key,
    required this.items,
    required this.onSeleccionado,
    this.seleccionadoId,
  });

  @override
  State<SelectorArticulo> createState() => _SelectorArticuloState();
}

class _SelectorArticuloState extends State<SelectorArticulo> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    ArticuloItem? sel;
    for (final i in widget.items) {
      if (i.id == widget.seleccionadoId) {
        sel = i;
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _abierto = !_abierto),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sel?.nombre ?? 'Seleccionar artículo . . .',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: sel != null
                            ? const Color(0xFF212121)
                            : const Color(0xFF757575),
                      ),
                    ),
                  ),
                  Icon(
                    _abierto
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFFE85E98),
                  ),
                ],
              ),
            ),
          ),
          if (_abierto)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
              ),
              child: Column(
                children: widget.items.map((item) {
                  final s = item.id == widget.seleccionadoId;
                  return InkWell(
                    onTap: () {
                      widget.onSeleccionado(item);
                      setState(() => _abierto = false);
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: s ? const Color(0xFFFCE4EF) : null,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.nombre,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Color(0xFF212121),
                              ),
                            ),
                          ),
                          Text(
                            '\$ ${item.precio.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
