import 'package:flutter/material.dart';

class SelectorSimple<T> extends StatefulWidget {
  final String titulo;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSeleccionado;
  final String? seleccionadoLabel;

  const SelectorSimple({
    super.key,
    required this.titulo,
    required this.items,
    required this.labelBuilder,
    required this.onSeleccionado,
    this.seleccionadoLabel,
  });

  @override
  State<SelectorSimple<T>> createState() => _SelectorSimpleState<T>();
}

class _SelectorSimpleState<T> extends State<SelectorSimple<T>> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
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
                      widget.seleccionadoLabel ?? widget.titulo,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: widget.seleccionadoLabel != null
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
                  return InkWell(
                    onTap: () {
                      widget.onSeleccionado(item);
                      setState(() => _abierto = false);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        widget.labelBuilder(item),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF212121),
                        ),
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
