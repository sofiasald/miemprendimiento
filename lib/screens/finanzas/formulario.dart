// Pantalla FINANZAS (Pedido / Venta / Gasto) + hoja acordeón "Seleccionar Artículo"
// Sin barra de navegación inferior (Inicio, Inventario, Finanzas, Ajustes).
//
// pubspec.yaml:
//   dependencies:
//     google_fonts: ^6.2.1
//
// Uso: en main.dart -> home: const FinanzasScreen()

import 'package:flutter/material.dart';

void main() => runApp(
  const MaterialApp(debugShowCheckedModeBanner: false, home: FinanzasScreen()),
);

// ─────────────────────────── Tema / helpers ───────────────────────────

class AppColors {
  static const rosa = Color(0xFFE85E98);
  static const rosaClaro = Color(0xFFF79AD3);
  static const rosaSuave = Color(0xFFFEC1E6);
  static const fondo = Color(0xFFF8F9FA);
  static const texto = Color(0xFF212121);
  static const textoSec = Color(0xFF424242);
  static const gris = Color(0xFF757575);
  static const borde = Color(0xFFE0E0E0);
  static const chip = Color(0xFFF0F0F0);
}

TextStyle inter(double size, FontWeight w, Color c) =>
    TextStyle(fontSize: size, fontWeight: w, color: c);

TextStyle jakarta(double size, FontWeight w, Color c) =>
    TextStyle(fontSize: size, fontWeight: w, color: c);

String fmtMonto(int n) =>
    '\$ ${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

String fmtFecha(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ─────────────────────────── Modelos de ejemplo ───────────────────────────

class Articulo {
  final String nombre;
  final int precio;
  final bool esCombo;
  const Articulo(this.nombre, this.precio, {this.esCombo = false});
}

const productos = [
  Articulo('Tiara Strass', 4500),
  Articulo('Vaso Personalizado Glitter', 3200),
  Articulo('Tutú de Tul', 5800),
];

const combos = [
  Articulo('Combo Cumpleaños Premium', 12500, esCombo: true),
  Articulo('Pack Egresados', 8000, esCombo: true),
];

/// Variantes de material con stock (reemplazar por datos de SQLite).
const variantesTiara = {'Azul': 30, 'Roja': 12, 'Dorada': 5};
const coloresTul = ['Rosa Pastel', 'Blanco', 'Celeste'];
const gemasTiara = ['Roja', 'Azul', 'Dorada'];

const materiales = {
  'Cinta de Raso 25mm': {'Rojo': 12, 'Azul': 20},
  'Strass 4mm': {'Cristal': 300, 'Dorado': 150},
};

// ─────────────────────────── Pantalla principal ───────────────────────────

enum Modo { pedido, venta, gasto }

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  int _tab = 0;
  Modo _modo = Modo.pedido;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: SafeArea(
        child: Column(
          children: [
            // Título
            Container(
              width: double.infinity,
              height: 67,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.borde.withOpacity(0.62)),
              ),
              child: Text(
                'FINANZAS',
                style: jakarta(
                  24,
                  FontWeight.w700,
                  AppColors.texto,
                ).copyWith(letterSpacing: 1.2),
              ),
            ),
            // Tabs superiores
            _TopTabs(
              labels: const ['Registro', 'Historial', 'Reportes'],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const Divider(height: 1, color: Color(0xFFCAC4D0)),
            if (_tab != 0)
              Expanded(
                child: Center(
                  child: Text(
                    'Próximamente',
                    style: inter(15, FontWeight.w500, AppColors.gris),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _Segmented(
                  labels: const ['Pedido', 'Venta', 'Gasto'],
                  selected: _modo.index,
                  onChanged: (i) => setState(() => _modo = Modo.values[i]),
                ),
              ),
              Expanded(
                child: switch (_modo) {
                  Modo.pedido => const PedidoForm(key: ValueKey('pedido')),
                  Modo.venta => const VentaForm(key: ValueKey('venta')),
                  Modo.gasto => const GastoForm(key: ValueKey('gasto')),
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const _TopTabs({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 47,
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = i == selected;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(i),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Center(
                    child: Text(
                      labels[i],
                      style: jakarta(
                        14,
                        FontWeight.w700,
                        sel ? AppColors.texto : AppColors.gris,
                      ),
                    ),
                  ),
                  if (sel) Container(height: 3, color: AppColors.rosaClaro),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const _Segmented({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppColors.rosa : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(2, 0),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: inter(
                    14,
                    FontWeight.w600,
                    sel ? Colors.white : AppColors.gris,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────── Widgets de formulario ───────────────────────────

class FieldLabel extends StatelessWidget {
  final String text;
  final double size;
  const FieldLabel(this.text, {super.key, this.size = 15});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(text, style: inter(size, FontWeight.w400, AppColors.gris)),
  );
}

/// Campo tipo "dropdown" (alto 48, radio 8) que abre una hoja inferior.
class SelectField extends StatelessWidget {
  final String hint;
  final String? value;
  final VoidCallback? onTap;
  const SelectField({super.key, required this.hint, this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 19),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borde.withOpacity(0.93)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                overflow: TextOverflow.ellipsis,
                style: inter(
                  15,
                  FontWeight.w500,
                  value == null ? AppColors.gris : AppColors.texto,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.rosa,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de fecha tipo "pastilla" (alto 40, radio 16).
class DateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final now = DateTime.now();
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: firstDate ?? DateTime(now.year - 2),
          lastDate: DateTime(now.year + 3),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.rosa),
            ),
            child: child!,
          ),
        );
        if (d != null) onChanged(d);
      },
      child: Container(
        width: 181,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _pillDecoration,
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'DD/MM/AAAA' : fmtFecha(value!),
                style: inter(
                  16,
                  FontWeight.w500,
                  value == null ? AppColors.gris : AppColors.texto,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.rosa,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

final _pillDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.borde.withOpacity(0.93)),
);

/// Campo numérico tipo "pastilla".
class PillTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double width;
  final String? prefix;
  final ValueChanged<String>? onChanged;
  final bool numeric;
  const PillTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.width = 116,
    this.prefix,
    this.onChanged,
    this.numeric = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _pillDecoration,
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: inter(18, FontWeight.w500, AppColors.texto),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          prefixText: prefix,
          prefixStyle: inter(18, FontWeight.w500, AppColors.texto),
          hintText: hint,
          hintStyle: inter(18, FontWeight.w500, AppColors.gris),
        ),
      ),
    );
  }
}

/// Campo de texto rectangular (nombre del cliente, observaciones).
class BoxTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final ValueChanged<String>? onChanged;
  const BoxTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minLines == 1 ? 48 : 70),
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borde.withOpacity(0.93)),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : 4,
        style: inter(15, FontWeight.w500, AppColors.texto),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: inter(15, FontWeight.w500, AppColors.gris),
        ),
      ),
    );
  }
}

class ActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onSave; // null = deshabilitado
  const ActionButtons({super.key, required this.onCancel, this.onSave});

  @override
  Widget build(BuildContext context) {
    final enabled = onSave != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.rosa),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black,
                ),
                child: Text(
                  'Cancelar',
                  style: inter(14, FontWeight.w600, AppColors.rosa),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rosa,
                  disabledBackgroundColor: AppColors.rosaSuave,
                  side: const BorderSide(color: AppColors.borde),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Registrar',
                  style: inter(14, FontWeight.w600, Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel gris "PERSONALIZACIÓN / DETALLES Y VARIANTES DEL COMBO".
class ComboPanel extends StatelessWidget {
  final String titulo;
  final String? incluye;
  final String? gemas;
  final String? tul;
  final ValueChanged<String> onGemas;
  final ValueChanged<String> onTul;
  const ComboPanel({
    super.key,
    required this.titulo,
    this.incluye,
    required this.gemas,
    required this.tul,
    required this.onGemas,
    required this.onTul,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEAEA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: inter(12, FontWeight.w700, const Color(0xFF616161)),
          ),
          if (incluye != null) ...[
            const SizedBox(height: 6),
            Text(incluye!, style: inter(12, FontWeight.w400, AppColors.texto)),
          ],
          const SizedBox(height: 12),
          Text(
            'Gemas (para Tiara) *',
            style: inter(13, FontWeight.w400, AppColors.gris),
          ),
          const SizedBox(height: 6),
          _MiniSelect(
            hint: 'Seleccionar gemas',
            value: gemas,
            onTap: () async {
              final v = await showOptionsSheet<String>(
                context,
                'Gemas',
                gemasTiara.map((e) => Opt(e, e)).toList(),
              );
              if (v != null) onGemas(v);
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Color de Tul (para Tutú) *',
            style: inter(13, FontWeight.w400, AppColors.gris),
          ),
          const SizedBox(height: 6),
          _MiniSelect(
            hint: 'Seleccionar color',
            value: tul,
            onTap: () async {
              final v = await showOptionsSheet<String>(
                context,
                'Color de Tul',
                coloresTul.map((e) => Opt(e, e)).toList(),
              );
              if (v != null) onTul(v);
            },
          ),
        ],
      ),
    );
  }
}

class _MiniSelect extends StatelessWidget {
  final String hint;
  final String? value;
  final VoidCallback onTap;
  const _MiniSelect({required this.hint, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borde.withOpacity(0.93)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value ?? hint,
              style: inter(
                15,
                FontWeight.w500,
                value == null ? AppColors.gris : AppColors.texto,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.rosa),
        ],
      ),
    ),
  );
}

// ─────────────────────────── Hojas inferiores ───────────────────────────

class Opt<T> {
  final T value;
  final String label;
  final String? trailing;
  const Opt(this.value, this.label, [this.trailing]);
}

class _SheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.borde.withOpacity(0.62)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 12,
                  child: Container(
                    width: 35,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borde,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 6,
                  child: Text(
                    title,
                    style: inter(16, FontWeight.w700, AppColors.texto),
                  ),
                ),
                const Positioned(
                  right: 12,
                  bottom: 6,
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: AppColors.rosa,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

Future<T?> showOptionsSheet<T>(
  BuildContext context,
  String title,
  List<Opt<T>> options,
) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.fondo,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SheetShell(
      title: title,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          for (final o in options)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borde.withOpacity(0.93)),
              ),
              child: ListTile(
                dense: true,
                title: Text(
                  o.label,
                  style: inter(14, FontWeight.w400, AppColors.texto),
                ),
                trailing: o.trailing == null
                    ? null
                    : Text(
                        o.trailing!,
                        style: inter(14, FontWeight.w600, AppColors.texto),
                      ),
                onTap: () => Navigator.pop(context, o.value),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Hoja acordeón "Seleccionar Artículo": Productos individuales / Combos y paquetes.
Future<Articulo?> showArticuloSheet(BuildContext context) {
  return showModalBottomSheet<Articulo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.fondo,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SheetShell(
      title: 'Seleccionar Artículo',
      child: const _AccordionArticulos(),
    ),
  );
}

class _AccordionArticulos extends StatefulWidget {
  const _AccordionArticulos();

  @override
  State<_AccordionArticulos> createState() => _AccordionArticulosState();
}

class _AccordionArticulosState extends State<_AccordionArticulos> {
  int? _abierto = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        children: [
          _seccion(
            0,
            'PRODUCTOS INDIVIDUALES (${productos.length})',
            productos,
          ),
          const SizedBox(height: 20),
          _seccion(1, 'COMBOS Y PAQUETES (${combos.length})', combos),
        ],
      ),
    );
  }

  Widget _seccion(int idx, String titulo, List<Articulo> items) {
    final abierto = _abierto == idx;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _abierto = abierto ? null : idx),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(8),
                bottom: Radius.circular(abierto ? 0 : 8),
              ),
              border: Border.all(color: AppColors.borde.withOpacity(0.93)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: inter(15, FontWeight.w600, AppColors.textoSec),
                  ),
                ),
                Icon(
                  abierto
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.rosa,
                ),
              ],
            ),
          ),
        ),
        if (abierto)
          Container(
            decoration: BoxDecoration(
              color: AppColors.chip.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              border: Border(
                left: BorderSide(color: AppColors.borde.withOpacity(0.93)),
                right: BorderSide(color: AppColors.borde.withOpacity(0.93)),
                bottom: BorderSide(color: AppColors.borde.withOpacity(0.93)),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  InkWell(
                    onTap: () => Navigator.pop(context, items[i]),
                    child: SizedBox(
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                items[i].nombre,
                                style: inter(
                                  14,
                                  FontWeight.w400,
                                  AppColors.texto,
                                ),
                              ),
                            ),
                            Text(
                              fmtMonto(items[i].precio),
                              style: inter(
                                14,
                                FontWeight.w600,
                                AppColors.texto,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (i < items.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _Dashed(),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) => Row(
      children: List.generate(
        (c.maxWidth / 6).floor(),
        (_) => Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.only(right: 3),
            color: AppColors.borde,
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────── Formulario: PEDIDO ───────────────────────────

class PedidoForm extends StatefulWidget {
  const PedidoForm({super.key});
  @override
  State<PedidoForm> createState() => _PedidoFormState();
}

class _PedidoFormState extends State<PedidoForm> {
  Articulo? _articulo;
  String? _gemas; // variante de tiara (o gemas del combo)
  String? _tul;
  DateTime? _entrega;
  final _cliente = TextEditingController();
  final _monto = TextEditingController();
  final _obs = TextEditingController();

  bool get _esTiara => _articulo?.nombre == 'Tiara Strass';
  bool get _esCombo => _articulo?.esCombo ?? false;

  bool get _valido =>
      _articulo != null &&
      (!_esTiara || _gemas != null) &&
      (!_esCombo || (_gemas != null && _tul != null)) &&
      _cliente.text.trim().isNotEmpty &&
      _entrega != null &&
      (int.tryParse(_monto.text) ?? 0) > 0;

  @override
  void dispose() {
    _cliente.dispose();
    _monto.dispose();
    _obs.dispose();
    super.dispose();
  }

  void _limpiar() => setState(() {
    _articulo = null;
    _gemas = null;
    _tul = null;
    _entrega = null;
    _cliente.clear();
    _monto.clear();
    _obs.clear();
  });

  void _registrar() {
    // TODO: insertar en tabla `pedidos` (SQLite).
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Pedido registrado')));
    _limpiar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const FieldLabel('Artículo encargado *'),
              SelectField(
                hint: 'Seleccionar Artículo . . .',
                value: _articulo?.nombre,
                onTap: () async {
                  final a = await showArticuloSheet(context);
                  if (a != null) {
                    setState(() {
                      _articulo = a;
                      _gemas = null;
                      _tul = null;
                      _monto.text = a.precio.toString();
                    });
                  }
                },
              ),
              if (_esTiara) ...[
                const FieldLabel('Variante de Gemas Strass *'),
                SelectField(
                  hint: 'Seleccionar gemas . . .',
                  value: _gemas,
                  onTap: () async {
                    final v = await showOptionsSheet<String>(
                      context,
                      'Gemas Strass',
                      gemasTiara.map((e) => Opt(e, e)).toList(),
                    );
                    if (v != null) setState(() => _gemas = v);
                  },
                ),
              ],
              if (_esCombo)
                ComboPanel(
                  titulo: 'PERSONALIZACIÓN DEL COMBO',
                  gemas: _gemas,
                  tul: _tul,
                  onGemas: (v) => setState(() => _gemas = v),
                  onTul: (v) => setState(() => _tul = v),
                ),
              const FieldLabel('Nombre del Cliente *'),
              BoxTextField(
                controller: _cliente,
                hint: 'Ingresar Nombre . . .',
                onChanged: (_) => setState(() {}),
              ),
              const FieldLabel('Fecha de entrega pactada *'),
              DateField(
                value: _entrega,
                firstDate: DateTime.now(),
                onChanged: (d) => setState(() => _entrega = d),
              ),
              const FieldLabel('Monto pactado (\$) *'),
              PillTextField(
                controller: _monto,
                hint: '\$ 0',
                prefix: '\$ ',
                onChanged: (_) => setState(() {}),
              ),
              const FieldLabel('Observaciones (Opcional)'),
              BoxTextField(
                controller: _obs,
                hint: 'Agregar notas adicionales, seña, entrega . . .',
                minLines: 2,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        ActionButtons(onCancel: _limpiar, onSave: _valido ? _registrar : null),
      ],
    );
  }
}

// ─────────────────────────── Formulario: VENTA ───────────────────────────

class VentaForm extends StatefulWidget {
  const VentaForm({super.key});
  @override
  State<VentaForm> createState() => _VentaFormState();
}

class _VentaFormState extends State<VentaForm> {
  bool _porCombo = false;
  Articulo? _articulo;
  String? _variante;
  String? _gemas;
  String? _tul;
  DateTime _fecha = DateTime.now();
  final _monto = TextEditingController();

  bool get _esTiara => _articulo?.nombre == 'Tiara Strass';

  bool get _valido =>
      _articulo != null &&
      (!_esTiara || _variante != null) &&
      (!_porCombo || (_gemas != null && _tul != null)) &&
      (int.tryParse(_monto.text) ?? 0) > 0;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  void _limpiar() => setState(() {
    _articulo = null;
    _variante = null;
    _gemas = null;
    _tul = null;
    _fecha = DateTime.now();
    _monto.clear();
  });

  void _registrar() {
    // TODO: insertar en `ventas` y descontar stock (movimiento_stock) en una transacción.
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Venta registrada')));
    _limpiar();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _porCombo ? combos : productos;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              // Toggle Productos / Combos
              Row(
                children: [
                  _ToggleChip(
                    icon: Icons.sell_rounded,
                    label: 'Productos',
                    selected: !_porCombo,
                    onTap: () => setState(() {
                      _porCombo = false;
                      _limpiar();
                    }),
                  ),
                  const SizedBox(width: 24),
                  _ToggleChip(
                    icon: Icons.inventory_2_rounded,
                    label: 'Combos',
                    selected: _porCombo,
                    onTap: () => setState(() {
                      _porCombo = true;
                      _limpiar();
                    }),
                  ),
                ],
              ),
              FieldLabel(_porCombo ? 'Combo Vendido *' : 'Producto Vendido *'),
              SelectField(
                hint: _porCombo
                    ? 'Seleccionar combo . . .'
                    : 'Seleccionar producto . . .',
                value: _articulo?.nombre,
                onTap: () async {
                  final a = await showOptionsSheet<Articulo>(
                    context,
                    _porCombo ? 'Combos' : 'Productos',
                    lista
                        .map((e) => Opt(e, e.nombre, fmtMonto(e.precio)))
                        .toList(),
                  );
                  if (a != null) {
                    setState(() {
                      _articulo = a;
                      _variante = null;
                      _monto.text = a.precio.toString();
                    });
                  }
                },
              ),
              if (!_porCombo && _esTiara) ...[
                const FieldLabel('Variante de material: *'),
                SelectField(
                  hint: 'Seleccionar material . . .',
                  value: _variante == null
                      ? null
                      : '$_variante (Stock disponible: ${variantesTiara[_variante]})',
                  onTap: () async {
                    final v = await showOptionsSheet<String>(
                      context,
                      'Variante de material',
                      variantesTiara.entries
                          .map(
                            (e) => Opt(
                              e.key,
                              e.key,
                              '(Stock disponible: ${e.value})',
                            ),
                          )
                          .toList(),
                    );
                    if (v != null) setState(() => _variante = v);
                  },
                ),
              ],
              if (_porCombo && _articulo != null)
                ComboPanel(
                  titulo: 'DETALLES Y VARIANTES DEL COMBO',
                  incluye:
                      'Incluye: 1 Tiara Strass + 1 Vaso Glitter + Tutú de Tul',
                  gemas: _gemas,
                  tul: _tul,
                  onGemas: (v) => setState(() => _gemas = v),
                  onTul: (v) => setState(() => _tul = v),
                ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 156,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(_porCombo ? 'Fecha actual *' : 'Fecha *'),
                        DateField(
                          value: _fecha,
                          onChanged: (d) => setState(() => _fecha = d),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 116,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Monto total (\$) *'),
                        PillTextField(
                          controller: _monto,
                          hint: '\$ 0',
                          prefix: '\$ ',
                          width: double.infinity,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        ActionButtons(onCancel: _limpiar, onSave: _valido ? _registrar : null),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: selected ? AppColors.rosaClaro : AppColors.borde,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: inter(
            12,
            FontWeight.w600,
            selected ? AppColors.texto : AppColors.texto.withOpacity(0.61),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────── Formulario: GASTO ───────────────────────────

class GastoForm extends StatefulWidget {
  const GastoForm({super.key});
  @override
  State<GastoForm> createState() => _GastoFormState();
}

class _GastoFormState extends State<GastoForm> {
  String? _material;
  String? _variante;
  DateTime _fecha = DateTime.now();
  final _cantidad = TextEditingController();
  final _monto = TextEditingController();
  String _unidad = 'Metros';

  bool get _valido =>
      _material != null &&
      _variante != null &&
      (double.tryParse(_cantidad.text.replaceAll(',', '.')) ?? 0) > 0 &&
      (int.tryParse(_monto.text) ?? 0) > 0;

  @override
  void dispose() {
    _cantidad.dispose();
    _monto.dispose();
    super.dispose();
  }

  void _limpiar() => setState(() {
    _material = null;
    _variante = null;
    _fecha = DateTime.now();
    _cantidad.clear();
    _monto.clear();
  });

  void _registrar() {
    // TODO: insertar en `gastos` y sumar stock a la variante (movimiento_stock).
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Gasto registrado')));
    _limpiar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const FieldLabel('Material / Insumo comprado *'),
              SelectField(
                hint: 'Seleccionar material . . .',
                value: _material,
                onTap: () async {
                  final v = await showOptionsSheet<String>(
                    context,
                    'Material / Insumo',
                    materiales.keys.map((e) => Opt(e, e)).toList(),
                  );
                  if (v != null) {
                    setState(() {
                      _material = v;
                      _variante = null;
                    });
                  }
                },
              ),
              if (_material != null) ...[
                const FieldLabel('Variante de material *'),
                SelectField(
                  hint: 'Seleccionar variante . . .',
                  value: _variante == null
                      ? null
                      : '$_variante (Stock actual: ${materiales[_material]![_variante]} ${_unidad.toLowerCase()})',
                  onTap: () async {
                    final v = await showOptionsSheet<String>(
                      context,
                      'Variante',
                      materiales[_material]!.entries
                          .map((e) => Opt(e.key, e.key, 'Stock: ${e.value}'))
                          .toList(),
                    );
                    if (v != null) setState(() => _variante = v);
                  },
                ),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Cantidad comprada *', size: 14),
                        PillTextField(
                          controller: _cantidad,
                          hint: '0',
                          width: 80,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Unidad (Referencia)', size: 14),
                        Container(
                          width: 96,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.borde.withOpacity(0.93),
                            ),
                          ),
                          child: Text(
                            _unidad,
                            style: inter(16, FontWeight.w500, AppColors.texto),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 156,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Fecha de compra *'),
                        DateField(
                          value: _fecha,
                          onChanged: (d) => setState(() => _fecha = d),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 116,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Monto abonado (\$) *'),
                        PillTextField(
                          controller: _monto,
                          hint: '\$ 0',
                          prefix: '\$ ',
                          width: double.infinity,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        ActionButtons(onCancel: _limpiar, onSave: _valido ? _registrar : null),
      ],
    );
  }
}
