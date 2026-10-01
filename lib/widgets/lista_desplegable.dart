import 'package:flutter/material.dart';

class ItemLista {
  final String id;
  final String nombre;
  final double precio;
  final bool esCombo;

  const ItemLista({
    required this.id,
    required this.nombre,
    required this.precio,
    this.esCombo = false,
  });
}

class ListaDesplegable extends StatefulWidget {
  final List<ItemLista> productos;
  final List<ItemLista> combos;
  final String? seleccionadoId;
  final ValueChanged<ItemLista> onSeleccionado;
  final VoidCallback? onCerrar;

  const ListaDesplegable({
    super.key,
    required this.productos,
    required this.combos,
    required this.onSeleccionado,
    this.seleccionadoId,
    this.onCerrar,
  });

  @override
  State<ListaDesplegable> createState() => _ListaDesplegableState();
}

class _ListaDesplegableState extends State<ListaDesplegable> {
  bool _productosAbierto = false;
  bool _combosAbierto = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.8),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Seleccionar Artículo',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                if (widget.onCerrar != null)
                  GestureDetector(
                    onTap: widget.onCerrar,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 22,
                        color: Color(0xFFE85E98),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _SeccionHeader(
            titulo: 'PRODUCTOS INDIVIDUALES (${widget.productos.length})',
            abierto: _productosAbierto,
            onTap: () => setState(() => _productosAbierto = !_productosAbierto),
          ),
          if (_productosAbierto)
            _ListaItems(
              items: widget.productos,
              seleccionadoId: widget.seleccionadoId,
              onSeleccionado: widget.onSeleccionado,
            ),
          _SeccionHeader(
            titulo: 'COMBOS Y PAQUETES (${widget.combos.length})',
            abierto: _combosAbierto,
            onTap: () => setState(() => _combosAbierto = !_combosAbierto),
            topBorder: true,
          ),
          if (_combosAbierto)
            _ListaItems(
              items: widget.combos,
              seleccionadoId: widget.seleccionadoId,
              onSeleccionado: widget.onSeleccionado,
            ),
        ],
      ),
    );
  }
}

class _SeccionHeader extends StatelessWidget {
  final String titulo;
  final bool abierto;
  final VoidCallback onTap;
  final bool topBorder;

  const _SeccionHeader({
    required this.titulo,
    required this.abierto,
    required this.onTap,
    this.topBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: topBorder
              ? const Border(
                  top: BorderSide(color: Color(0xFFE0E0E0), width: 0.8),
                )
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF424242),
                ),
              ),
            ),
            Icon(
              abierto ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFFE85E98),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaItems extends StatelessWidget {
  final List<ItemLista> items;
  final String? seleccionadoId;
  final ValueChanged<ItemLista> onSeleccionado;

  const _ListaItems({
    required this.items,
    required this.seleccionadoId,
    required this.onSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'No hay ítems cargados',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF757575),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _FilaItem(
            item: items[i],
            seleccionado: items[i].id == seleccionadoId,
            onTap: () => onSeleccionado(items[i]),
          ),
          if (i < items.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _SeparadorPunteado(),
            ),
        ],
      ],
    );
  }
}

class _FilaItem extends StatelessWidget {
  final ItemLista item;
  final bool seleccionado;
  final VoidCallback onTap;

  const _FilaItem({
    required this.item,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: seleccionado ? const Color(0xFFFCE4EF) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.nombre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF212121),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
  }
}

class _SeparadorPunteado extends StatelessWidget {
  const _SeparadorPunteado();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace))
            .floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: 1,
              color: const Color(0xFFE0E0E0),
            );
          }),
        );
      },
    );
  }
}
