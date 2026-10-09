import 'package:flutter/material.dart';

import '../models/venta.dart';
import '../models/gasto.dart';
import '../models/pedido.dart';
import '../services/db_helper.dart';

class FinanzasProvider extends ChangeNotifier {
  List<Venta> _ventas = [];
  List<Gasto> _gastos = [];
  List<Pedido> _pedidos = [];

  List<Venta> get ventas => List.unmodifiable(_ventas);
  List<Gasto> get gastos => List.unmodifiable(_gastos);
  List<Pedido> get pedidos => List.unmodifiable(_pedidos);

  // -------- Totales rápidos para Reporte --------
  double get totalVentas => _ventas.fold(0.0, (s, v) => s + v.monto);
  double get totalGastos => _gastos.fold(0.0, (s, g) => s + g.monto);
  double get balance => totalVentas - totalGastos;

  // -------- Cargas --------
  Future<void> cargarVentas() async {
    final db = await DBHelper.instance.database;
    final res = await db.query('ventas', orderBy: 'fecha DESC');
    _ventas = res.map((v) => Venta.fromMap(v)).toList();
    notifyListeners();
  }

  Future<void> cargarGastos() async {
    final db = await DBHelper.instance.database;
    final res = await db.query('gastos', orderBy: 'fecha DESC');
    _gastos = res.map((g) => Gasto.fromMap(g)).toList();
    notifyListeners();
  }

  Future<void> cargarPedidos() async {
    final db = await DBHelper.instance.database;
    final res = await db.query('pedidos', orderBy: 'fechaRegistro DESC');
    _pedidos = res.map((p) => Pedido.fromMap(p)).toList();
    notifyListeners();
  }

  // -------- Altas --------
  Future<void> agregarVenta(Venta venta) async {
    final db = await DBHelper.instance.database;
    await db.insert('ventas', venta.toMap());
    await cargarVentas();
  }

  Future<void> agregarGasto(Gasto gasto) async {
    final db = await DBHelper.instance.database;
    await db.insert('gastos', gasto.toMap());
    await cargarGastos();
  }

  Future<void> agregarPedido(Pedido pedido) async {
    final db = await DBHelper.instance.database;
    await db.insert('pedidos', pedido.toMap());
    await cargarPedidos();
  }

  // -------- Bajas --------
  Future<void> eliminarVenta(String id) async {
    final db = await DBHelper.instance.database;
    await db.delete('ventas', where: 'id = ?', whereArgs: [id]);
    await cargarVentas();
  }

  Future<void> eliminarGasto(String id) async {
    final db = await DBHelper.instance.database;
    await db.delete('gastos', where: 'id = ?', whereArgs: [id]);
    await cargarGastos();
  }

  Future<void> eliminarPedido(String id) async {
    final db = await DBHelper.instance.database;
    await db.delete('pedidos', where: 'id = ?', whereArgs: [id]);
    await cargarPedidos();
  }

  // -------- Cambios de estado del pedido --------
  Future<void> cambiarEstadoPedido(String id, String nuevoEstado) async {
    final db = await DBHelper.instance.database;
    await db.update(
      'pedidos',
      {'estado': nuevoEstado},
      where: 'id = ?',
      whereArgs: [id],
    );
    await cargarPedidos();
  }
}
