import 'package:flutter/material.dart';

import 'dart:convert';

class SharedPreferences {
  static final Map<String, List<String>> _storage = {};

  static Future<SharedPreferences> getInstance() async => SharedPreferences();

  List<String>? getStringList(String key) => _storage[key];

  Future<bool> setStringList(String key, List<String> value) async {
    _storage[key] = value;
    return true;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanzas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE85E98)),
      ),
      home: const PantallaPedidoBase(),
    );
  }
}

// ============================================================
// COLORES
// ============================================================
const Color kRosa = Color(0xFFE85E98);
const Color kRosaClaro = Color(0xFFFEC1E6);
const Color kRosaIndicator = Color(0xFFF79AD3);
const Color kGrisFondo = Color(0xFFF8F9FA);
const Color kGrisClaro = Color(0xFFF0F0F0);
const Color kGrisBorde = Color(0xFFE0E0E0);
const Color kTextoPrincipal = Color(0xFF212121);
const Color kTextoSecundario = Color(0xFF757575);

// ============================================================
// MODELO DE DATOS
// ============================================================
class RegistroPedido {
  String articulo;
  String cliente;
  String fechaEntrega;
  double monto;
  String observaciones;

  RegistroPedido({
    this.articulo = '',
    this.cliente = '',
    this.fechaEntrega = '',
    this.monto = 0,
    this.observaciones = '',
  });

  Map<String, dynamic> toJson() => {
    'articulo': articulo,
    'cliente': cliente,
    'fechaEntrega': fechaEntrega,
    'monto': monto,
    'observaciones': observaciones,
  };

  factory RegistroPedido.fromJson(Map<String, dynamic> json) => RegistroPedido(
    articulo: json['articulo'] ?? '',
    cliente: json['cliente'] ?? '',
    fechaEntrega: json['fechaEntrega'] ?? '',
    monto: (json['monto'] ?? 0).toDouble(),
    observaciones: json['observaciones'] ?? '',
  );
}

class RegistroVenta {
  String producto;
  String variante;
  String fecha;
  double monto;

  RegistroVenta({
    this.producto = '',
    this.variante = '',
    this.fecha = '',
    this.monto = 0,
  });

  Map<String, dynamic> toJson() => {
    'producto': producto,
    'variante': variante,
    'fecha': fecha,
    'monto': monto,
  };

  factory RegistroVenta.fromJson(Map<String, dynamic> json) => RegistroVenta(
    producto: json['producto'] ?? '',
    variante: json['variante'] ?? '',
    fecha: json['fecha'] ?? '',
    monto: (json['monto'] ?? 0).toDouble(),
  );
}

class RegistroGasto {
  String material;
  String variante;
  String cantidad;
  String unidad;
  String fecha;
  double monto;

  RegistroGasto({
    this.material = '',
    this.variante = '',
    this.cantidad = '',
    this.unidad = '',
    this.fecha = '',
    this.monto = 0,
  });

  Map<String, dynamic> toJson() => {
    'material': material,
    'variante': variante,
    'cantidad': cantidad,
    'unidad': unidad,
    'fecha': fecha,
    'monto': monto,
  };

  factory RegistroGasto.fromJson(Map<String, dynamic> json) => RegistroGasto(
    material: json['material'] ?? '',
    variante: json['variante'] ?? '',
    cantidad: json['cantidad'] ?? '',
    unidad: json['unidad'] ?? '',
    fecha: json['fecha'] ?? '',
    monto: (json['monto'] ?? 0).toDouble(),
  );
}

// ============================================================
// SERVICIO DE PERSISTENCIA
// ============================================================
class StorageService {
  static const _keyPedidos = 'pedidos';
  static const _keyVentas = 'ventas';
  static const _keyGastos = 'gastos';

  static Future<void> guardarPedido(RegistroPedido p) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(_keyPedidos) ?? [];
    lista.add(jsonEncode(p.toJson()));
    await prefs.setStringList(_keyPedidos, lista);
  }

  static Future<List<RegistroPedido>> obtenerPedidos() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(_keyPedidos) ?? [];
    return lista.map((e) => RegistroPedido.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> guardarVenta(RegistroVenta v) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(_keyVentas) ?? [];
    lista.add(jsonEncode(v.toJson()));
    await prefs.setStringList(_keyVentas, lista);
  }

  static Future<List<RegistroVenta>> obtenerVentas() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(_keyVentas) ?? [];
    return lista.map((e) => RegistroVenta.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> guardarGasto(RegistroGasto g) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(_keyGastos) ?? [];
    lista.add(jsonEncode(g.toJson()));
    await prefs.setStringList(_keyGastos, lista);
  }

  static Future<List<RegistroGasto>> obtenerGastos() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(_keyGastos) ?? [];
    return lista.map((e) => RegistroGasto.fromJson(jsonDecode(e))).toList();
  }
}

// ============================================================
// WIDGETS REUTILIZABLES
// ============================================================
class TituloSeccion extends StatelessWidget {
  final String texto;
  const TituloSeccion({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kGrisBorde.withOpacity(0.62)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 13,
            child: Container(
              width: 35,
              height: 4,
              decoration: BoxDecoration(
                color: kGrisBorde,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kTextoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class CampoTexto extends StatelessWidget {
  final String hint;
  final IconData? iconoDerecha;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const CampoTexto({
    super.key,
    required this.hint,
    this.iconoDerecha,
    this.onTap,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: maxLines > 1 ? 70 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kGrisBorde.withOpacity(0.93)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              onTap: onTap,
              readOnly: onTap != null,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kTextoSecundario,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kTextoPrincipal,
              ),
            ),
          ),
          if (iconoDerecha != null) Icon(iconoDerecha, color: kRosa, size: 20),
        ],
      ),
    );
  }
}

class FilaAcordeon extends StatelessWidget {
  final String etiqueta;
  final String precio;
  final VoidCallback? onTap;

  const FilaAcordeon({
    super.key,
    required this.etiqueta,
    required this.precio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: kGrisBorde),
            right: BorderSide(color: kGrisBorde),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                etiqueta,
                style: const TextStyle(fontSize: 14, color: kTextoPrincipal),
              ),
            ),
            Text(
              precio,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextoPrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilaAcordeonFinal extends StatelessWidget {
  final String etiqueta;
  final String precio;
  final VoidCallback? onTap;

  const FilaAcordeonFinal({
    super.key,
    required this.etiqueta,
    required this.precio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            left: const BorderSide(color: kGrisBorde),
            right: const BorderSide(color: kGrisBorde),
            bottom: const BorderSide(color: kGrisBorde),
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                etiqueta,
                style: const TextStyle(fontSize: 14, color: kTextoPrincipal),
              ),
            ),
            Text(
              precio,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextoPrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SeparadorPunteado extends StatelessWidget {
  const SeparadorPunteado({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              height: 1,
              color: index.isEven ? kGrisBorde : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class BotonRegistrar extends StatelessWidget {
  final VoidCallback? onTap;
  const BotonRegistrar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kRosa,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: const Text(
          'Registrar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class BotonCancelar extends StatelessWidget {
  final VoidCallback? onTap;
  const BotonCancelar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kRosa),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Cancelar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kRosa,
          ),
        ),
      ),
    );
  }
}

class SelectorPestanas extends StatelessWidget {
  final int seleccionado;
  final ValueChanged<int>? onChanged;

  const SelectorPestanas({
    super.key,
    required this.seleccionado,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: kGrisClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTab('Pedido', 0),
          _buildTab('Venta', 1),
          _buildTab('Gasto', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String texto, int index) {
    final activo = seleccionado == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged?.call(index),
        child: Container(
          decoration: BoxDecoration(
            color: activo ? kRosa : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: activo
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      offset: const Offset(4, 0),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: activo ? Colors.white : kTextoSecundario,
            ),
          ),
        ),
      ),
    );
  }
}

class SelectorCategoria extends StatelessWidget {
  final int seleccionado;
  final ValueChanged<int> onChanged;

  const SelectorCategoria({
    super.key,
    required this.seleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(0),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 16,
                color: seleccionado == 0 ? kRosaIndicator : kGrisBorde,
              ),
              const SizedBox(width: 8),
              Text(
                'Productos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: seleccionado == 0
                      ? kTextoPrincipal
                      : kTextoPrincipal.withOpacity(0.61),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () => onChanged(1),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 16,
                color: seleccionado == 1 ? kRosaIndicator : kGrisBorde,
              ),
              const SizedBox(width: 8),
              Text(
                'Combos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: seleccionado == 1
                      ? kTextoPrincipal
                      : kTextoPrincipal.withOpacity(0.61),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PANTALLA: PEDIDO BASE CON GUARDADO
// ============================================================
class PantallaPedidoBase extends StatefulWidget {
  const PantallaPedidoBase({super.key});

  @override
  State<PantallaPedidoBase> createState() => _PantallaPedidoBaseState();
}

class _PantallaPedidoBaseState extends State<PantallaPedidoBase> {
  int _pestana = 0;

  final _articuloCtrl = TextEditingController();
  final _clienteCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController(text: '09/09/2026');
  final _montoCtrl = TextEditingController(text: '0');
  final _obsCtrl = TextEditingController();

  @override
  void dispose() {
    _articuloCtrl.dispose();
    _clienteCtrl.dispose();
    _fechaCtrl.dispose();
    _montoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_articuloCtrl.text.isEmpty || _clienteCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá artículo y cliente')),
      );
      return;
    }

    final pedido = RegistroPedido(
      articulo: _articuloCtrl.text,
      cliente: _clienteCtrl.text,
      fechaEntrega: _fechaCtrl.text,
      monto: double.tryParse(_montoCtrl.text) ?? 0,
      observaciones: _obsCtrl.text,
    );

    await StorageService.guardarPedido(pedido);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pedido guardado correctamente'),
        backgroundColor: kRosa,
      ),
    );

    setState(() {
      _articuloCtrl.clear();
      _clienteCtrl.clear();
      _fechaCtrl.text = '09/09/2026';
      _montoCtrl.text = '0';
      _obsCtrl.clear();
    });
  }

  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar?'),
        content: const Text('Se perderán los datos ingresados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí', style: TextStyle(color: kRosa)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _articuloCtrl.clear();
      _clienteCtrl.clear();
      _fechaCtrl.text = '09/09/2026';
      _montoCtrl.text = '0';
      _obsCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrisFondo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'FINANZAS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: kTextoPrincipal,
            letterSpacing: 0.05,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectorPestanas(
              seleccionado: _pestana,
              onChanged: (v) => setState(() => _pestana = v),
            ),
            const SizedBox(height: 24),

            const Text(
              'Artículo encargado *',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            CampoTexto(
              hint: 'Seleccionar Artículo . . .',
              controller: _articuloCtrl,
              iconoDerecha: Icons.keyboard_arrow_down,
            ),
            const SizedBox(height: 24),

            const Text(
              'Nombre del Cliente *',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            CampoTexto(hint: 'Ingresar Nombre . . .', controller: _clienteCtrl),
            const SizedBox(height: 24),

            const Text(
              'Fecha de entrega pactada *',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            CampoTexto(
              hint: 'dd/mm/aaaa',
              controller: _fechaCtrl,
              iconoDerecha: Icons.calendar_today,
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (fecha != null) {
                  _fechaCtrl.text =
                      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
                }
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Monto pactado (\$) *',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            CampoTexto(
              hint: '0',
              controller: _montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Observaciones (Opcional)',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            CampoTexto(
              hint: 'Agregar notas, seña, entrega . . .',
              controller: _obsCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BotonCancelar(onTap: _cancelar),
                BotonRegistrar(onTap: _guardar),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PANTALLA: VENTA CON ACORDEÓN Y GUARDADO
// ============================================================
class PantallaVentaGasto extends StatefulWidget {
  const PantallaVentaGasto({super.key});

  @override
  State<PantallaVentaGasto> createState() => _PantallaVentaGastoState();
}

class _PantallaVentaGastoState extends State<PantallaVentaGasto> {
  int _pestana = 1;
  int _categoria = 0;
  bool _acordeonAbierto = false;

  final _productoCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController(text: '30/08/2026');
  final _montoCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _productoCtrl.dispose();
    _fechaCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_productoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccioná un producto')));
      return;
    }

    final venta = RegistroVenta(
      producto: _productoCtrl.text,
      fecha: _fechaCtrl.text,
      monto: double.tryParse(_montoCtrl.text) ?? 0,
    );

    await StorageService.guardarVenta(venta);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Venta guardada correctamente'),
        backgroundColor: kRosa,
      ),
    );

    setState(() {
      _productoCtrl.clear();
      _fechaCtrl.text = '30/08/2026';
      _montoCtrl.text = '0';
      _acordeonAbierto = false;
    });
  }

  void _cancelar() {
    setState(() {
      _productoCtrl.clear();
      _fechaCtrl.text = '30/08/2026';
      _montoCtrl.text = '0';
      _acordeonAbierto = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrisFondo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'FINANZAS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: kTextoPrincipal,
            letterSpacing: 0.05,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectorPestanas(
              seleccionado: _pestana,
              onChanged: (v) => setState(() => _pestana = v),
            ),
            const SizedBox(height: 24),

            SelectorCategoria(
              seleccionado: _categoria,
              onChanged: (v) => setState(() => _categoria = v),
            ),
            const SizedBox(height: 16),

            const Text(
              'Producto Vendido *',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _acordeonAbierto = !_acordeonAbierto),
              child: Container(
                width: double.infinity,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: _acordeonAbierto
                        ? kTextoPrincipal.withOpacity(0.93)
                        : kGrisBorde,
                    width: _acordeonAbierto ? 1.5 : 1,
                  ),
                  borderRadius: _acordeonAbierto
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        )
                      : BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _productoCtrl.text.isEmpty
                            ? 'Seleccionar producto . . .'
                            : _productoCtrl.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: _productoCtrl.text.isEmpty
                              ? kTextoSecundario
                              : kTextoPrincipal,
                        ),
                      ),
                    ),
                    Icon(
                      _acordeonAbierto
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: kRosa,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            if (_acordeonAbierto)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: kTextoPrincipal.withOpacity(0.93),
                      width: 1.5,
                    ),
                    right: BorderSide(
                      color: kTextoPrincipal.withOpacity(0.93),
                      width: 1.5,
                    ),
                    bottom: BorderSide(
                      color: kTextoPrincipal.withOpacity(0.93),
                      width: 1.5,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  children: [
                    FilaAcordeon(
                      etiqueta: 'Tiara Strass',
                      precio: '\$ 4.500',
                      onTap: () => setState(() {
                        _productoCtrl.text = 'Tiara Strass';
                        _montoCtrl.text = '4500';
                        _acordeonAbierto = false;
                      }),
                    ),
                    const SeparadorPunteado(),
                    FilaAcordeon(
                      etiqueta: 'Vaso Personalizado Glitter',
                      precio: '\$ 3.200',
                      onTap: () => setState(() {
                        _productoCtrl.text = 'Vaso Personalizado Glitter';
                        _montoCtrl.text = '3200';
                        _acordeonAbierto = false;
                      }),
                    ),
                    const SeparadorPunteado(),
                    FilaAcordeonFinal(
                      etiqueta: 'Tutú de Tul',
                      precio: '\$ 5.800',
                      onTap: () => setState(() {
                        _productoCtrl.text = 'Tutú de Tul';
                        _montoCtrl.text = '5800';
                        _acordeonAbierto = false;
                      }),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            const Text(
              'Fecha actual *',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            CampoTexto(
              hint: 'dd/mm/aaaa',
              controller: _fechaCtrl,
              iconoDerecha: Icons.calendar_today,
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (fecha != null) {
                  _fechaCtrl.text =
                      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
                }
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Monto total (\$) *',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            CampoTexto(
              hint: '0',
              controller: _montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BotonCancelar(onTap: _cancelar),
                BotonRegistrar(onTap: _guardar),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PANTALLA: VENTA CON VARIANTE Y GUARDADO
// ============================================================
class PantallaVentaVariante extends StatefulWidget {
  const PantallaVentaVariante({super.key});

  @override
  State<PantallaVentaVariante> createState() => _PantallaVentaVarianteState();
}

class _PantallaVentaVarianteState extends State<PantallaVentaVariante> {
  bool _acordeonMaterialAbierto = false;

  final _productoCtrl = TextEditingController(text: 'Tiara Strass');
  final _varianteCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController(text: '30/08/2026');
  final _montoCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _productoCtrl.dispose();
    _varianteCtrl.dispose();
    _fechaCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_productoCtrl.text.isEmpty || _varianteCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá producto y variante')),
      );
      return;
    }

    final venta = RegistroVenta(
      producto: _productoCtrl.text,
      variante: _varianteCtrl.text,
      fecha: _fechaCtrl.text,
      monto: double.tryParse(_montoCtrl.text) ?? 0,
    );

    await StorageService.guardarVenta(venta);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Venta con variante guardada'),
        backgroundColor: kRosa,
      ),
    );
  }

  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar?'),
        content: const Text('Se perderán los datos ingresados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí', style: TextStyle(color: kRosa)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _productoCtrl.clear();
        _varianteCtrl.clear();
        _fechaCtrl.text = '30/08/2026';
        _montoCtrl.text = '0';
        _acordeonMaterialAbierto = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrisFondo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'FINANZAS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: kTextoPrincipal,
            letterSpacing: 0.05,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SelectorPestanas(seleccionado: 1, onChanged: null),
            const SizedBox(height: 24),

            const Text(
              'Producto Vendido *',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            CampoTexto(
              hint: 'Tiara Strass',
              controller: _productoCtrl,
              iconoDerecha: Icons.keyboard_arrow_down,
            ),
            const SizedBox(height: 24),

            const Text(
              'Variante de material: *',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(
                () => _acordeonMaterialAbierto = !_acordeonMaterialAbierto,
              ),
              child: Container(
                width: double.infinity,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: _acordeonMaterialAbierto
                        ? kTextoPrincipal.withOpacity(0.93)
                        : kGrisBorde,
                    width: _acordeonMaterialAbierto ? 1.5 : 1,
                  ),
                  borderRadius: _acordeonMaterialAbierto
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        )
                      : BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _varianteCtrl.text.isEmpty
                            ? 'Seleccionar material . . .'
                            : _varianteCtrl.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: _varianteCtrl.text.isEmpty
                              ? kTextoSecundario
                              : kTextoPrincipal,
                        ),
                      ),
                    ),
                    Icon(
                      _acordeonMaterialAbierto
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: kRosa,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_acordeonMaterialAbierto)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: kTextoPrincipal.withOpacity(0.93),
                      width: 1.5,
                    ),
                    right: BorderSide(
                      color: kTextoPrincipal.withOpacity(0.93),
                      width: 1.5,
                    ),
                    bottom: BorderSide(
                      color: kTextoPrincipal.withOpacity(0.93),
                      width: 1.5,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  children: [
                    FilaAcordeon(
                      etiqueta: 'Rosa',
                      precio: '',
                      onTap: () => setState(() {
                        _varianteCtrl.text = 'Rosa';
                        _acordeonMaterialAbierto = false;
                      }),
                    ),
                    const SeparadorPunteado(),
                    FilaAcordeon(
                      etiqueta: 'Blanco',
                      precio: '',
                      onTap: () => setState(() {
                        _varianteCtrl.text = 'Blanco';
                        _acordeonMaterialAbierto = false;
                      }),
                    ),
                    const SeparadorPunteado(),
                    FilaAcordeonFinal(
                      etiqueta: 'Dorado',
                      precio: '',
                      onTap: () => setState(() {
                        _varianteCtrl.text = 'Dorado';
                        _acordeonMaterialAbierto = false;
                      }),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            const Text(
              'Fecha actual *',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            CampoTexto(
              hint: 'dd/mm/aaaa',
              controller: _fechaCtrl,
              iconoDerecha: Icons.calendar_today,
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (fecha != null) {
                  _fechaCtrl.text =
                      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
                }
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Monto total (\$) *',
              style: TextStyle(fontSize: 15, color: kTextoSecundario),
            ),
            const SizedBox(height: 8),
            CampoTexto(
              hint: '0',
              controller: _montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BotonCancelar(onTap: _cancelar),
                BotonRegistrar(onTap: _guardar),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
