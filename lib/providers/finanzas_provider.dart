import 'package:flutter/material.dart';

import '../services/db_helper.dart';
import '../models/venta.dart';
import '../models/gasto.dart';
import '../models/pedido.dart';
import '../models/material_consumo.dart';
import '../models/material.dart';
import '../models/variante.dart';
import 'inventario_provider.dart';

class FinanzasProvider extends ChangeNotifier {
  List<Venta> ventas = [];
  List<Gasto> gastos = [];
  List<Pedido> pedidos = [];

  // Carga

  Future<void> cargarVentas() async {
    final db = await DBHelper.instance.database;
    final maps = await db.query(
      'ventas',
      where: 'visible = 1 OR visible IS NULL',
      orderBy: 'fecha DESC',
    );
    ventas = maps.map((m) => Venta.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> cargarGastos() async {
    final db = await DBHelper.instance.database;
    final maps = await db.query(
      'gastos',
      where: 'visible = 1 OR visible IS NULL',
      orderBy: 'fecha DESC',
    );
    gastos = maps.map((m) => Gasto.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> cargarPedidos() async {
    final db = await DBHelper.instance.database;
    final maps = await db.query(
      'pedidos',
      where: 'visible = 1 OR visible IS NULL',
      orderBy: 'fechaEntrega ASC',
    );
    pedidos = maps.map((m) => Pedido.fromMap(m)).toList();
    notifyListeners();
  }

  /// Carga ventas, gastos y pedidos de forma paralela desde SQLite.
  Future<void> cargarTodo() async {
    await Future.wait([
      cargarVentas(),
      cargarGastos(),
      cargarPedidos(),
    ]);
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
    String? matId = gasto.materialId;

    await db.transaction((txn) async {
      await txn.insert('gastos', gastoMap);
      if (varianteId != null) {
        await txn.rawUpdate(
          'UPDATE variantes SET cantidad = cantidad + ? WHERE id = ?',
          [cantidadGasto, varianteId],
        );
        if (matId == null) {
          final res = await txn.query(
            'variantes',
            columns: ['materialId'],
            where: 'id = ?',
            whereArgs: [varianteId],
          );
          if (res.isNotEmpty) {
            matId = res.first['materialId'] as String?;
          }
        }
      }
      if (matId != null) {
        await txn.rawUpdate(
          'UPDATE materiales SET cantidad = cantidad + ? WHERE id = ?',
          [cantidadGasto, matId],
        );
      }
    });

    gastos.insert(0, gasto);
    notifyListeners();
  }

  Future<void> agregarGasto(Gasto gasto) => registrarGasto(gasto);
  Future<void> guardarGasto(Gasto gasto) => registrarGasto(gasto);

  // Paso 7 — Registrar pedido: NO toca stock todavía.

  Future<void> registrarPedido(Pedido pedido) async {
    final db = await DBHelper.instance.database;
    await db.insert('pedidos', pedido.toMap());
    pedidos.add(pedido);
    pedidos.sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));
    notifyListeners();
  }

  Future<void> agregarPedido(Pedido pedido) => registrarPedido(pedido);
  Future<void> guardarPedido(Pedido pedido) => registrarPedido(pedido);

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
      ),
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

  /// Registra una nueva venta, la persiste en SQLite y actualiza la UI reactivamente.
  Future<void> agregarVenta(Venta nuevaVenta) async {
    final db = await DBHelper.instance.database;
    await db.insert('ventas', nuevaVenta.toMap());
    ventas.insert(0, nuevaVenta);
    notifyListeners();
  }

  Future<void> guardarVenta(Venta nuevaVenta) => agregarVenta(nuevaVenta);

  /// Marca un pedido como entregado, descuenta insumos y registra la venta correspondiente con origen 'pedido'.
  Future<void> entregarPedido({
    required Pedido pedido,
    required InventarioProvider inventarioProvider,
  }) async {
    // 1. Descontar stock de insumos según la cantidad del pedido
    await inventarioProvider.descontarStockPorVentaOPedido(
      productoId: pedido.productoId,
      comboId: pedido.comboId,
      nombreItem: pedido.nombreItem,
      varianteNombre: pedido.variante,
      unidades: pedido.cantidad,
    );

    // 2. Registrar la venta con origen 'pedido'
    final nuevaVenta = Venta(
      id: 'venta-${DateTime.now().millisecondsSinceEpoch}',
      productoId: pedido.productoId,
      comboId: pedido.comboId,
      pedidoId: pedido.id,
      cliente: pedido.cliente,
      nombreItem: pedido.nombreItem,
      variante: pedido.variante,
      cantidad: pedido.cantidad,
      monto: pedido.monto,
      fecha: DateTime.now().toIso8601String(),
      tipo: 'pedido',
    );
    await agregarVenta(nuevaVenta);

    // 3. Actualizar estado y fecha de entrega real del pedido
    pedido.estado = 'entregado';
    pedido.fechaEntregaReal = DateTime.now();
    await actualizarPedido(pedido);
  }

  /// Elimina un pedido completado por su identificador único.
  Future<void> eliminarPedido(String id) async {
    final db = await DBHelper.instance.database;
    await db.update('pedidos', {'visible': 0}, where: 'id = ?', whereArgs: [id]);
    pedidos.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Actualiza los datos de un pedido existente (modificación o cambio de estado).
  Future<void> actualizarPedido(Pedido pedidoModificado) async {
    final db = await DBHelper.instance.database;
    await db.update(
      'pedidos',
      pedidoModificado.toMap(),
      where: 'id = ?',
      whereArgs: [pedidoModificado.id],
    );
    final indice = pedidos.indexWhere((p) => p.id == pedidoModificado.id);
    if (indice != -1) {
      pedidos[indice] = pedidoModificado;
      notifyListeners();
    }
  }

  /// Elimina una venta y actualiza los balances de ReporteScreen.
  Future<void> eliminarVenta(String id) async {
    final db = await DBHelper.instance.database;
    await db.update('ventas', {'visible': 0}, where: 'id = ?', whereArgs: [id]);
    ventas.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  /// Elimina un gasto y actualiza los balances de ReporteScreen.
  Future<void> eliminarGasto(String id) async {
    final db = await DBHelper.instance.database;
    await db.update('gastos', {'visible': 0}, where: 'id = ?', whereArgs: [id]);
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
