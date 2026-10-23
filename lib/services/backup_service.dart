import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';

class BackupService {
  /// Exporta la totalidad de la base de datos a JSON y abre la hoja para compartir.
  /// Retorna `true` si se completó o guardó, y `false` si la usuaria canceló.
  static Future<bool> exportarDatos() async {
    final db = await DBHelper.instance.database;

    // 1. Lectura integral de todas las tablas del sistema
    final materiales = await db.query('materiales');
    final variantes = await db.query('variantes');
    final productos = await db.query('productos');
    final combos = await db.query('combos');
    final productoMaterial = await db.query('producto_material');
    final comboItem = await db.query('combo_item');
    final ventas = await db.query('ventas');
    final gastos = await db.query('gastos');
    final pedidos = await db.query('pedidos');
    final movimientoStock = await db.query('movimiento_stock');

    final backupData = {
      'app': 'Atelier',
      'version_esquema': 3,
      'fecha_creacion': DateTime.now().toIso8601String(),
      'materiales': materiales,
      'variantes': variantes,
      'productos': productos,
      'combos': combos,
      'producto_material': productoMaterial,
      'combo_item': comboItem,
      'ventas': ventas,
      'gastos': gastos,
      'pedidos': pedidos,
      'movimiento_stock': movimientoStock,
    };

    final jsonString = jsonEncode(backupData);

    final tempDir = await getTemporaryDirectory();
    final fecha = DateTime.now().toString().split(' ')[0];
    final archivo = File('${tempDir.path}/respaldo_atelier_$fecha.json');
    await archivo.writeAsString(jsonString);

    final xFile = XFile(archivo.path, mimeType: 'application/json');
    
    // Sintaxis moderna de SharePlus (elimina la advertencia de deprecación)
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: 'Copia de seguridad Atelier - $fecha',
        subject: 'Respaldo Atelier',
      ),
    );

    if (result.status == ShareResultStatus.dismissed) {
      return false;
    }
    return true;
  }

  /// Abre el explorador de archivos, valida la integridad y restaura la base.
  /// Retorna la cantidad de registros recuperados o `-1` si se canceló la selección.
  static Future<int> importarDatos() async {
    final result = await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    // Cancelación limpia: se quitó 'result == null' porque nunca es nulo
    if (result.isEmpty || result.first.path == null) {
      return -1;
    }

    final path = result.first.path!;
    final file = File(path);

    final contenido = await file.readAsString();

    final dynamic dataDecoded;
    try {
      dataDecoded = jsonDecode(contenido);
    } catch (_) {
      throw Exception('El archivo seleccionado está corrupto o no tiene formato JSON válido.');
    }

    if (dataDecoded is! Map<String, dynamic>) {
      throw Exception('Estructura de respaldo no compatible.');
    }

    final Map<String, dynamic> data = dataDecoded;

    // Validación preventiva de estructura mínima de Atelier
    if (!data.containsKey('materiales') ||
        !data.containsKey('ventas') ||
        !data.containsKey('pedidos')) {
      throw Exception('El archivo no corresponde a una copia de seguridad válida de Atelier.');
    }

    final db = await DBHelper.instance.database;
    int registrosRestaurados = 0;

    await db.transaction((txn) async {
      // 1. Borrado en orden inverso (primero tablas dependientes para cuidar foreign keys)
      await txn.delete('movimiento_stock');
      await txn.delete('combo_item');
      await txn.delete('producto_material');
      await txn.delete('pedidos');
      await txn.delete('gastos');
      await txn.delete('ventas');
      await txn.delete('variantes');
      await txn.delete('combos');
      await txn.delete('productos');
      await txn.delete('materiales');

      // 2. Inserción ordenada (padres primero, luego relaciones e historiales)
      Future<void> insertarLote(String tabla, String clave) async {
        final lista = data[clave] as List<dynamic>? ?? [];
        for (final item in lista) {
          await txn.insert(
            tabla,
            Map<String, dynamic>.from(item as Map),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          registrosRestaurados++;
        }
      }

      await insertarLote('materiales', 'materiales');
      await insertarLote('variantes', 'variantes');
      await insertarLote('productos', 'productos');
      await insertarLote('combos', 'combos');
      await insertarLote('producto_material', 'producto_material');
      await insertarLote('combo_item', 'combo_item');
      await insertarLote('pedidos', 'pedidos');
      await insertarLote('ventas', 'ventas');
      await insertarLote('gastos', 'gastos');
      await insertarLote('movimiento_stock', 'movimiento_stock');
    });

    return registrosRestaurados;
  }
}