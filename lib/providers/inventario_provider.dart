import 'package:flutter/material.dart';
import '../models/material.dart';
import '../models/variante.dart';
import '../models/producto.dart';
import '../models/producto_material.dart';
import '../models/combo.dart';
import '../models/combo_item.dart';
import '../services/db_helper.dart';

class InventarioProvider extends ChangeNotifier {
  List<MaterialItem> _materiales = [];
  List<MaterialItem> _materialesFiltrados = [];
  final Map<String, List<Variante>> _variantes = {};
  
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  final Map<String, List<ProductoMaterial>> _insumosPorProducto = {};

  List<Combo> _combos = [];
  List<Combo> _combosFiltrados = [];
  final Map<String, List<ComboItem>> _itemsPorCombo = {};

  String _busqueda = '';

  List<MaterialItem> get materiales => _materialesFiltrados;
  Map<String, List<Variante>> get variantes => _variantes;
  
  List<Producto> get productos => _productosFiltrados;
  Map<String, List<ProductoMaterial>> get insumosProductos => _insumosPorProducto;

  List<Combo> get combos => _combosFiltrados;
  Map<String, List<ComboItem>> get itemsPorCombo => _itemsPorCombo;

  Future<void> cargarMateriales() async {
    final db = await DBHelper.instance.database;
    final res = await db.query('materiales', where: 'visible = 1');
    _materiales = res.map((m) => MaterialItem.fromMap(m)).toList();
    
    _variantes.clear();
    for (var m in _materiales) {
      final resVars = await db.query('variantes', where: 'materialId = ?', whereArgs: [m.id]);
      _variantes[m.id] = resVars.map((v) => Variante.fromMap(v)).toList();
    }
    
    _aplicarFiltro();
  }

  void buscar(String query) {
    _busqueda = query.toLowerCase();
    _aplicarFiltro();
  }

  void _aplicarFiltro() {
    if (_busqueda.isEmpty) {
      _materialesFiltrados = List.from(_materiales);
      _productosFiltrados = List.from(_productos);
      _combosFiltrados = List.from(_combos);
    } else {
      _materialesFiltrados = _materiales.where((m) => 
        m.nombre.toLowerCase().contains(_busqueda)
      ).toList();
      _productosFiltrados = _productos.where((p) => 
        p.nombre.toLowerCase().contains(_busqueda)
      ).toList();
      _combosFiltrados = _combos.where((c) => 
        c.nombre.toLowerCase().contains(_busqueda)
      ).toList();
    }
    notifyListeners();
  }

  Future<void> cargarProductos() async {
    final db = await DBHelper.instance.database;
    final res = await db.query('productos', where: 'visible = 1');
    _productos = res.map((p) => Producto.fromMap(p)).toList();

    _insumosPorProducto.clear();
    for (var p in _productos) {
      final resInsumos = await db.rawQuery('''
        SELECT pm.materialId, pm.cantidad, m.nombre as materialNombre, m.unidad as materialUnidad
        FROM producto_material pm
        JOIN materiales m ON pm.materialId = m.id
        WHERE pm.productoId = ?
      ''', [p.id]);

      _insumosPorProducto[p.id] = resInsumos.map((i) => ProductoMaterial(
        materialId: i['materialId'] as String,
        materialNombre: i['materialNombre'] as String,
        materialUnidad: i['materialUnidad'] as String,
        cantidad: i['cantidad'] != null ? (i['cantidad'] as num).toDouble() : null,
      )).toList();
    }
    _aplicarFiltro();
  }

  Future<void> agregarProducto(Producto producto, List<ProductoMaterial> insumos) async {
    final db = await DBHelper.instance.database;
    await db.transaction((txn) async {
      await txn.insert('productos', producto.toMap());
      for (var i in insumos) {
        await txn.insert('producto_material', {
          'productoId': producto.id,
          'materialId': i.materialId,
          'cantidad': i.cantidad,
        });
      }
    });
    await cargarProductos();
  }

  Future<void> editarProducto(Producto producto, List<ProductoMaterial> insumos) async {
    final db = await DBHelper.instance.database;
    await db.transaction((txn) async {
      await txn.update('productos', producto.toMap(), where: 'id = ?', whereArgs: [producto.id]);
      await txn.delete('producto_material', where: 'productoId = ?', whereArgs: [producto.id]);
      for (var i in insumos) {
        await txn.insert('producto_material', {
          'productoId': producto.id,
          'materialId': i.materialId,
          'cantidad': i.cantidad,
        });
      }
    });
    await cargarProductos();
  }

  Future<void> ocultarProducto(String id) async {
    final db = await DBHelper.instance.database;
    await db.update('productos', {'visible': 0}, where: 'id = ?', whereArgs: [id]);
    await cargarProductos();
  }

  Future<void> agregarMaterial(MaterialItem material, List<Variante> variantes) async {
    final db = await DBHelper.instance.database;
    await db.transaction((txn) async {
      await txn.insert('materiales', material.toMap());
      for (var v in variantes) {
        await txn.insert('variantes', v.toMap());
      }
    });
    await cargarMateriales();
  }

  Future<void> ocultarMaterial(String id) async {
    final db = await DBHelper.instance.database;
    await db.update('materiales', {'visible': 0}, where: 'id = ?', whereArgs: [id]);
    await cargarMateriales();
  }

  Future<List<Variante>> obtenerVariantes(String materialId) async {
    final db = await DBHelper.instance.database;
    final res = await db.query('variantes', where: 'materialId = ?', whereArgs: [materialId]);
    return res.map((v) => Variante.fromMap(v)).toList();
  }

  Future<void> editarMaterial(MaterialItem material, List<Variante> variantes) async {
    final db = await DBHelper.instance.database;
    await db.transaction((txn) async {
      await txn.update('materiales', material.toMap(), where: 'id = ?', whereArgs: [material.id]);
      await txn.delete('variantes', where: 'materialId = ?', whereArgs: [material.id]);
      for (var v in variantes) {
        await txn.insert('variantes', v.toMap());
      }
    });
    await cargarMateriales();
  }

  Future<void> cargarCombos() async {
    final db = await DBHelper.instance.database;
    final res = await db.query('combos', where: 'visible = 1');
    _combos = res.map((c) => Combo.fromMap(c)).toList();

    _itemsPorCombo.clear();
    for (var c in _combos) {
      final resItems = await db.rawQuery('''
        SELECT 
          CASE WHEN ci.productoId IS NOT NULL THEN ci.productoId ELSE ci.materialId END as elementoId,
          CASE WHEN ci.productoId IS NOT NULL THEN 'producto' ELSE 'material' END as tipo,
          ci.cantidad,
          CASE WHEN ci.productoId IS NOT NULL THEN p.nombre ELSE m.nombre END as nombre
        FROM combo_item ci
        LEFT JOIN productos p ON ci.productoId = p.id
        LEFT JOIN materiales m ON ci.materialId = m.id
        WHERE ci.comboId = ?
      ''', [c.id]);

      _itemsPorCombo[c.id] = resItems.map((i) => ComboItem.fromMap(i)).toList();
    }
    _aplicarFiltro();
  }

  Future<void> agregarCombo(Combo combo, List<ComboItem> items) async {
    final db = await DBHelper.instance.database;
    await db.transaction((txn) async {
      await txn.insert('combos', combo.toMap());
      for (var i in items) {
        await txn.insert('combo_item', i.toMap(combo.id));
      }
    });
    await cargarCombos();
  }

  Future<void> editarCombo(Combo combo, List<ComboItem> items) async {
    final db = await DBHelper.instance.database;
    await db.transaction((txn) async {
      await txn.update('combos', combo.toMap(), where: 'id = ?', whereArgs: [combo.id]);
      await txn.delete('combo_item', where: 'comboId = ?', whereArgs: [combo.id]);
      for (var i in items) {
        await txn.insert('combo_item', i.toMap(combo.id));
      }
    });
    await cargarCombos();
  }

  Future<void> ocultarCombo(String id) async {
    final db = await DBHelper.instance.database;
    await db.update('combos', {'visible': 0}, where: 'id = ?', whereArgs: [id]);
    await cargarCombos();
  }
}
