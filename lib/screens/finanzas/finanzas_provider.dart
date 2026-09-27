import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../models/venta.dart';
import '../models/gasto.dart';
import '../models/pedido.dart';
import '../models/material_consumo.dart';
import '../models/material.dart';
import '../models/variante.dart';

enum TipoMovimiento { venta, gasto }

class FinanzasProvider extends ChangeNotifier {
  List<Venta> ventas = [];
  List<Gasto> gastos = [];
  List<Pedido> pedidos = [];

  // ---------------------------------------------------------------------
  // Carga
  // ---------------------------------------------------------------------

  Future<void> cargarVentas() async {
    final db = await DBHelper.instance.database;
    final maps = await db.query('ventas', where: 'visible = 1', orderBy: 'fecha DESC');
    ventas = maps.map((m) => Venta.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> cargarGastos() async {
    final db = await DBHelper.instance.database;
    final maps = await db.query('gastos', where: 'visible = 1', orderBy: 'fecha DESC');
    gastos = maps.map((m) => Gasto.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> cargarPedidos() async {
    final db = await DBHelper.instance.database;
    final maps = await db.query('pedidos', where: 'visible = 1', orderBy: 'fechaEntrega ASC');
    pedidos = maps.map((m) => Pedido.fromMap(m)).toList();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Paso 4 — Validar stock ANTES de abrir la transacción.
  // Devuelve la lista de consumos para los que NO alcanza el stock actual.
  // Lista vacía = hay stock para todo lo que se necesita.
  // ---------------------------------------------------------------------

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

  // ---------------------------------------------------------------------
  // Paso 5 — Registrar venta: TODO dentro de una única transacción.
  // ---------------------------------------------------------------------

  Future<void> registrarVenta(Venta venta, List<MaterialConsumo> consumos) async {
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

  // ---------------------------------------------------------------------
  // Paso 6 — Registrar gasto: mismo patrón, pero SUMANDO stock.
  // ---------------------------------------------------------------------

  Future<void> registrarGasto(Gasto gasto) async {
    final db = await DBHelper.instance.database;

    await db.transaction((txn) async {
      await txn.insert('gastos', gasto.toMap());

      if (gasto.varianteId != null) {
        await txn.rawUpdate(
          'UPDATE variantes SET cantidad = cantidad + ? WHERE id = ?',
          [gasto.cantidad, gasto.varianteId],
        );
      } else {
        await txn.rawUpdate(
          'UPDATE materiales SET cantidad = cantidad + ? WHERE id = ?',
          [gasto.cantidad, gasto.materialId],
        );
      }
    });

    gastos.insert(0, gasto);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Paso 7 — Registrar pedido: NO toca stock todavía.
  // ---------------------------------------------------------------------

  Future<void> registrarPedido(Pedido pedido) async {
    final db = await DBHelper.instance.database;
    await db.insert('pedidos', pedido.toMap());
    pedidos.add(pedido);
    pedidos.sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));
    notifyListeners();
  }
}