import 'package:flutter/material.dart';

import '../services/db_helper.dart';
import '../models/venta.dart';
import '../models/gasto.dart';
import '../models/pedido.dart';
import '../models/material_consumo.dart';
import '../models/material.dart';
import '../models/variante.dart';

class FinanzasProvider extends ChangeNotifier {
  List<Venta> ventas = [];
  List<Gasto> gastos = [];
  List<Pedido> pedidos = [];

  // Carga

  Future<void> cargarVentas() async {
    final db = await DBHelper.instance.database;
    final maps = await db.query(
      'ventas',
      where: 'visible = 1',
      orderBy: 'fecha DESC',
    );
    ventas = maps.map((m) => Venta.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> cargarGastos() async {
    final db = await DBHelper.instance.database;
    final maps = await db.query(
      'gastos',
      where: 'visible = 1',
      orderBy: 'fecha DESC',
    );
    gastos = maps.map((m) => Gasto.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> cargarPedidos() async {
    final db = await DBHelper.instance.database;
    final maps = await db.query(
      'pedidos',
      where: 'visible = 1',
      orderBy: 'fechaEntrega ASC',
    );
    pedidos = maps.map((m) => Pedido.fromMap(m)).toList();
    notifyListeners();
  }

  // Paso 4 — Validar stock ANTES de abrir la transacción.
  // Devuelve la lista de consumos para los que NO alcanza el stock actual.
  // Lista vacía = hay stock para todo lo que se necesita.

  List<MaterialConsumo> validarStock(
    List<MaterialConsumo> consumos,
    List<MaterialItem> materiales,
    Map<String, List<Variante>> variantesPorMaterial,
  ) {
    final faltantes = <MaterialConsumo>[];

    for (final c in consumos) {
      double disponible = 0;

      if (c.varianteId != null) {
        final variantes = variantesPorMaterial[c.materialId] ?? [];
        final coincidencias = variantes.where((v) => v.id == c.varianteId);
        if (coincidencias.isNotEmpty) disponible = coincidencias.first.cantidad;
      } else {
        final coincidencias = materiales.where((m) => m.id == c.materialId);
        if (coincidencias.isNotEmpty) disponible = coincidencias.first.cantidad;
      }

      if (disponible < c.cantidad) {
        faltantes.add(c);
      }
    }

    return faltantes;
  }

  // Paso 5 — Registrar venta: TODO dentro de una única transacción.

  Future<void> registrarVenta(
    Venta venta,
    List<MaterialConsumo> consumos,
  ) async {
    final db = await DBHelper.instance.database;

    await db.transaction((txn) async {
      await txn.insert('ventas', venta.toMap());

      for (final c in consumos) {
        if (c.varianteId != null) {
          await txn.rawUpdate(
            'UPDATE variantes SET cantidad = cantidad - ? WHERE id = ?',
            [c.cantidad, c.varianteId],
          );
        } else {
          await txn.rawUpdate(
            'UPDATE materiales SET cantidad = cantidad - ? WHERE id = ?',
            [c.cantidad, c.materialId],
          );
        }
      }
    });

    ventas.insert(0, venta);
    notifyListeners();
  }

  // Paso 6 — Registrar gasto: mismo patrón, pero SUMANDO stock.

  Future<void> registrarGasto(Gasto gasto) async {
    final db = await DBHelper.instance.database;
    final gastoMap = gasto.toMap();
    final cantidadGasto = (gastoMap['cantidad'] as num?)?.toDouble() ?? 0.0;
    final varianteId = gastoMap['varianteId'];

    await db.transaction((txn) async {
      await txn.insert('gastos', gastoMap);
      if (varianteId != null) {
        await txn.rawUpdate(
          'UPDATE variantes SET cantidad = cantidad + ? WHERE id = ?',
          [cantidadGasto, varianteId],
        );
      } else {
        await txn.rawUpdate(
          'UPDATE materiales SET cantidad = cantidad + ? WHERE id = ?',
          [cantidadGasto, gasto.materialId],
        );
      }
    });

    gastos.insert(0, gasto);
    notifyListeners();
  }

  // Paso 7 — Registrar pedido: NO toca stock todavía.

  Future<void> registrarPedido(Pedido pedido) async {
    final db = await DBHelper.instance.database;
    await db.insert('pedidos', pedido.toMap());
    pedidos.add(pedido);
    pedidos.sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));
    notifyListeners();
  }

  /// Carga datos iniciales de demostración basados en la maqueta de Figma de Atelier.
  void cargarDatosDemostracion() {
    // 1. Pedido de Elena Gómez ($65.000)
    pedidos = [
      Pedido(
        id: 'pedido-demo-1',
        cliente: 'Elena Gómez',
        nombreItem: 'Tiara Strass',
        variante: 'Color de Gemas: Azul',
        cantidad: 2,
        monto: 65000,
        fechaRegistro: DateTime(2026, 8, 12),
        fechaEntrega: DateTime(2026, 9, 28),
        observaciones: 'Seña de \$25.000',
        estado: 'pendiente',
      )
    ];

    // 2. Venta de Tiara Strass ($200.000)
    ventas = [
      Venta(
        nombreItem: 'Tiara Strass',
        monto: 135000,
        fecha: '12 de Septiembre 2026',
      ),
    ];

    // 3. Gasto en Cinta de Raso ($11.200)
    gastos = [
      Gasto(
        materialNombre: 'Cinta de Raso',
        monto: 11200,
        fecha: '11 de Septiembre 2026',
      ),
    ];

    // Notificamos a los widgets para que se redibujen automáticamente
    notifyListeners();
  }

  /// Registra una nueva venta, la persiste y actualiza la UI reactivamente.
  Future<void> agregarVenta(Venta nuevaVenta) async {
    // Si tu proyecto usa un helper de base de datos SQLite (ej. DBHelper / DatabaseHelper):
    // await DBHelper.insertarVenta(nuevaVenta.toMap());
    
    ventas.add(nuevaVenta);
    notifyListeners(); // Notifica a HistorialScreen y ReporteScreen para redibujarse
  }

  /// Elimina un pedido completado por su identificador único.
  Future<void> eliminarPedido(String id) async {
    // Si tu proyecto usa base de datos SQLite:
    // await DBHelper.eliminarPedido(id);
    
    pedidos.removeWhere((p) => p.id == id);
    notifyListeners(); // Quita la tarjeta de la lista en vivo
  }

  /// Actualiza los datos de un pedido existente (modificación o cambio de estado).
  Future<void> actualizarPedido(Pedido pedidoModificado) async {
    final indice = pedidos.indexWhere((p) => p.id == pedidoModificado.id);
    if (indice != -1) {
      pedidos[indice] = pedidoModificado;
      notifyListeners();
    }
  }

  /// Elimina una venta y actualiza los balances de ReporteScreen.
  Future<void> eliminarVenta(String id) async {
    ventas.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  /// Elimina un gasto y actualiza los balances de ReporteScreen.
  Future<void> eliminarGasto(String id) async {
    gastos.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  /// Limpia los movimientos para visualizar el estado vacío ($0).
  void vaciarDatos() {
    pedidos = [];
    ventas = [];
    gastos = [];
    notifyListeners();
  }
}
