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

  /// Devuelve los insumos con variantes requeridos para un producto o combo,
  /// respetando cada insumo individual configurado y su cantidad específica.
  List<VarianteRequerida> obtenerVariantesRequeridas({
    String? productoId,
    String? comboId,
  }) {
    final List<VarianteRequerida> resultado = [];
    final Map<String, int> ocurrencias = {};

    void agregarInsumo({
      required String materialId,
      required String materialNombre,
      required double? rawCantidad,
      String? prefijoContexto,
    }) {
      final vars = _variantes[materialId] ?? [];
      final varsVisibles = vars.where((v) => v.visible).toList();
      if (varsVisibles.isEmpty) return;

      final count = (ocurrencias[materialId] ?? 0) + 1;
      ocurrencias[materialId] = count;

      final sufijo = count > 1 ? ' ($count)' : '';
      final cant = (rawCantidad != null && rawCantidad > 0) ? rawCantidad.round() : 1;

      final etiqueta = prefijoContexto != null && prefijoContexto.isNotEmpty
          ? 'Variante de $materialNombre$sufijo ($prefijoContexto) *'
          : 'Variante de $materialNombre$sufijo *';

      resultado.add(
        VarianteRequerida(
          key: '${materialId}_slot_$count',
          materialId: materialId,
          materialNombre: materialNombre,
          etiqueta: etiqueta,
          cantidad: cant,
          ocurrencia: count,
          opciones: varsVisibles,
        ),
      );
    }

    if (productoId != null) {
      final insumos = _insumosPorProducto[productoId] ?? [];
      for (final i in insumos) {
        agregarInsumo(
          materialId: i.materialId,
          materialNombre: i.materialNombre,
          rawCantidad: i.cantidad,
        );
      }
    }

    if (comboId != null) {
      final items = _itemsPorCombo[comboId] ?? [];
      for (final item in items) {
        if (item.tipo == 'material') {
          agregarInsumo(
            materialId: item.elementoId,
            materialNombre: item.nombre,
            rawCantidad: item.cantidad,
          );
        } else if (item.tipo == 'producto') {
          final subInsumos = _insumosPorProducto[item.elementoId] ?? [];
          for (final sub in subInsumos) {
            final cantComboItem = (item.cantidad != null && item.cantidad! > 0) ? item.cantidad!.round() : 1;
            final subCant = (sub.cantidad != null && sub.cantidad! > 0) ? sub.cantidad! * cantComboItem : cantComboItem.toDouble();
            agregarInsumo(
              materialId: sub.materialId,
              materialNombre: sub.materialNombre,
              rawCantidad: subCant,
              prefijoContexto: item.nombre,
            );
          }
        }
      }
    }

    return resultado;
  }

  /// Descuenta de la base de datos el stock de los insumos requeridos
  /// para un producto o combo, en unidades enteras y coordinado con las variantes.
  Future<void> descontarStockPorVentaOPedido({
    String? productoId,
    String? comboId,
    String? nombreItem,
    String? varianteNombre,
    Map<String, String>? variantesElegidas,
    int unidades = 1,
  }) async {
    if (unidades <= 0) return;
    final db = await DBHelper.instance.database;

    String? pId = productoId;
    String? cId = comboId;

    if (pId == null && cId == null && nombreItem != null && nombreItem.trim().isNotEmpty) {
      final itemLimpio = nombreItem.trim();
      final resProd = await db.rawQuery(
        'SELECT id FROM productos WHERE (LOWER(nombre) = LOWER(?) OR LOWER(?) LIKE LOWER(nombre || "%")) AND (visible = 1 OR visible IS NULL) LIMIT 1',
        [itemLimpio, itemLimpio],
      );
      if (resProd.isNotEmpty) {
        pId = resProd.first['id'] as String;
      } else {
        final resCombo = await db.rawQuery(
          'SELECT id FROM combos WHERE (LOWER(nombre) = LOWER(?) OR LOWER(?) LIKE LOWER(nombre || "%")) AND (visible = 1 OR visible IS NULL) LIMIT 1',
          [itemLimpio, itemLimpio],
        );
        if (resCombo.isNotEmpty) {
          cId = resCombo.first['id'] as String;
        }
      }
    }

    final Map<String, int> insumosADescontar = {};

    if (pId != null) {
      final resInsumos = await db.query(
        'producto_material',
        columns: ['materialId', 'cantidad'],
        where: 'productoId = ?',
        whereArgs: [pId],
      );
      for (final row in resInsumos) {
        final matId = row['materialId'] as String;
        final rawCant = (row['cantidad'] as num?)?.toDouble() ?? 1.0;
        final cantEntera = rawCant > 0 ? rawCant.round() : 1;
        final totalADescontar = cantEntera * unidades;
        insumosADescontar[matId] = (insumosADescontar[matId] ?? 0) + totalADescontar;
      }
    }

    if (cId != null) {
      final resItems = await db.query(
        'combo_item',
        columns: ['productoId', 'materialId', 'cantidad'],
        where: 'comboId = ?',
        whereArgs: [cId],
      );
      for (final item in resItems) {
        final rawCant = (item['cantidad'] as num?)?.toDouble() ?? 1.0;
        final cantComboItem = rawCant > 0 ? rawCant.round() : 1;

        final directMatId = item['materialId'] as String?;
        final prodId = item['productoId'] as String?;

        if (directMatId != null && directMatId.isNotEmpty) {
          final totalADescontar = cantComboItem * unidades;
          insumosADescontar[directMatId] = (insumosADescontar[directMatId] ?? 0) + totalADescontar;
        } else if (prodId != null && prodId.isNotEmpty) {
          final resSubInsumos = await db.query(
            'producto_material',
            columns: ['materialId', 'cantidad'],
            where: 'productoId = ?',
            whereArgs: [prodId],
          );
          for (final sub in resSubInsumos) {
            final matId = sub['materialId'] as String;
            final subRawCant = (sub['cantidad'] as num?)?.toDouble() ?? 1.0;
            final subCantEntera = subRawCant > 0 ? subRawCant.round() : 1;
            final totalADescontar = subCantEntera * cantComboItem * unidades;
            insumosADescontar[matId] = (insumosADescontar[matId] ?? 0) + totalADescontar;
          }
        }
      }
    }

    // Calcular variantes específicas a descontar
    final reqs = obtenerVariantesRequeridas(productoId: pId, comboId: cId);
    final Map<String, int> variantesADescontar = {};

    final Map<String, String> variantesPorTexto = {};
    if (varianteNombre != null && varianteNombre.isNotEmpty && varianteNombre != 'Estándar') {
      final partes = varianteNombre.split(', ');
      for (final parte in partes) {
        final dosPuntos = parte.indexOf(':');
        if (dosPuntos != -1) {
          final etiqueta = parte.substring(0, dosPuntos).trim();
          final valorVar = parte.substring(dosPuntos + 1).trim();
          variantesPorTexto[etiqueta.toLowerCase()] = valorVar.toLowerCase();
        }
      }
    }

    for (final req in reqs) {
      String? targetVarId;

      // 1. Prioridad: variante explícitamente elegida por slot key
      if (variantesElegidas != null && variantesElegidas.containsKey(req.key)) {
        final id = variantesElegidas[req.key];
        if (id != null && id.isNotEmpty) {
          targetVarId = id;
        }
      }

      // 1b. Fallback a materialId directo si vino mapa legado
      if (targetVarId == null && variantesElegidas != null && variantesElegidas.containsKey(req.materialId)) {
        final id = variantesElegidas[req.materialId];
        if (id != null && id.isNotEmpty) {
          targetVarId = id;
        }
      }

      // 2. Coincidencia por texto de pedido guardado
      if (targetVarId == null && variantesPorTexto.isNotEmpty) {
        final sufijo = req.ocurrencia > 1 ? ' (${req.ocurrencia})' : '';
        final nombreClave = '${req.materialNombre}$sufijo'.toLowerCase();
        final nombreVarBuscada = variantesPorTexto[nombreClave];

        if (nombreVarBuscada != null) {
          final coincidente = req.opciones.where(
            (v) => v.nombre.trim().toLowerCase() == nombreVarBuscada,
          );
          if (coincidente.isNotEmpty) {
            targetVarId = coincidente.first.id;
          }
        }
      }

      // 2b. Coincidencia difusa en varianteNombre si no vino con formato exacto
      if (targetVarId == null && varianteNombre != null && varianteNombre.isNotEmpty && varianteNombre != 'Estándar') {
        final coincidente = req.opciones.where((v) {
          final n = v.nombre.trim().toLowerCase();
          return n.isNotEmpty && varianteNombre.toLowerCase().contains(n);
        });
        if (coincidente.isNotEmpty) {
          targetVarId = coincidente.first.id;
        }
      }

      // 3. Fallback: la variante con más stock disponible
      if (targetVarId == null && req.opciones.isNotEmpty) {
        final ordenada = List<Variante>.from(req.opciones)
          ..sort((a, b) => b.cantidad.compareTo(a.cantidad));
        targetVarId = ordenada.first.id;
      }

      if (targetVarId != null) {
        final cantVar = req.cantidad * unidades;
        variantesADescontar[targetVarId] = (variantesADescontar[targetVarId] ?? 0) + cantVar;
      }
    }

    if (insumosADescontar.isEmpty && variantesADescontar.isEmpty) return;

    await db.transaction((txn) async {
      // 1. Descontar materiales
      for (final entry in insumosADescontar.entries) {
        final materialId = entry.key;
        final cant = entry.value;

        await txn.rawUpdate(
          'UPDATE materiales SET cantidad = CASE WHEN cantidad - ? < 0 THEN 0 ELSE cantidad - ? END WHERE id = ?',
          [cant, cant, materialId],
        );
      }

      // 2. Descontar variantes seleccionadas
      for (final entry in variantesADescontar.entries) {
        final varId = entry.key;
        final cant = entry.value;

        await txn.rawUpdate(
          'UPDATE variantes SET cantidad = CASE WHEN cantidad - ? < 0 THEN 0 ELSE cantidad - ? END WHERE id = ?',
          [cant, cant, varId],
        );
      }
    });

    await cargarMateriales();
  }
}
