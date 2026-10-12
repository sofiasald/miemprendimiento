import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'db_helper.dart';

class BackupService {
  /// Exporta las tablas a un archivo JSON y abre la hoja nativa para compartir o guardar
  static Future<void> exportarDatos() async {
    final db = await DBHelper.instance.database;

    final materiales = await db.query('materiales');
    final productos = await db.query('productos');
    final ventas = await db.query('ventas');
    final gastos = await db.query('gastos');
    final pedidos = await db.query('pedidos');

    final backupData = {
      'version': 1,
      'fecha_creacion': DateTime.now().toIso8601String(),
      'materiales': materiales,
      'productos': productos,
      'ventas': ventas,
      'gastos': gastos,
      'pedidos': pedidos,
    };

    final jsonString = jsonEncode(backupData);

    final tempDir = await getTemporaryDirectory();
    final fecha = DateTime.now().toString().split(' ')[0];
    final archivo = File('${tempDir.path}/respaldo_atelier_$fecha.json');
    await archivo.writeAsString(jsonString);

    final xFile = XFile(archivo.path, mimeType: 'application/json');
    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [xFile],
      text: 'Copia de seguridad Atelier - $fecha',
      subject: 'Respaldo Atelier',
    );
  }

  /// Abre el explorador de archivos, valida el JSON y restaura la base de datos
  static Future<int> importarDatos() async {
    final result = await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    // Se valida directamente si la lista vino vacía o el archivo no tiene ruta
    if (result.isEmpty || result.first.path == null) {
      throw Exception('Operación cancelada: no se seleccionó ningún archivo');
    }

    final path = result.first.path!;
    final file = File(path);
    final contenido = await file.readAsString();

    final Map<String, dynamic> data = jsonDecode(contenido);

    if (!data.containsKey('materiales') || !data.containsKey('ventas')) {
      throw Exception('El archivo no contiene un formato de respaldo válido para Atelier');
    }

    final db = await DBHelper.instance.database;
    int registrosRestaurados = 0;

    await db.transaction((txn) async {
      await txn.delete('pedidos');
      await txn.delete('gastos');
      await txn.delete('ventas');
      await txn.delete('productos');
      await txn.delete('materiales');

      final materiales = data['materiales'] as List<dynamic>? ?? [];
      for (final m in materiales) {
        await txn.insert('materiales', Map<String, dynamic>.from(m));
        registrosRestaurados++;
      }

      final productos = data['productos'] as List<dynamic>? ?? [];
      for (final p in productos) {
        await txn.insert('productos', Map<String, dynamic>.from(p));
        registrosRestaurados++;
      }

      final ventas = data['ventas'] as List<dynamic>? ?? [];
      for (final v in ventas) {
        await txn.insert('ventas', Map<String, dynamic>.from(v));
        registrosRestaurados++;
      }

      final gastos = data['gastos'] as List<dynamic>? ?? [];
      for (final g in gastos) {
        await txn.insert('gastos', Map<String, dynamic>.from(g));
        registrosRestaurados++;
      }

      final pedidos = data['pedidos'] as List<dynamic>? ?? [];
      for (final ped in pedidos) {
        await txn.insert('pedidos', Map<String, dynamic>.from(ped));
        registrosRestaurados++;
      }
    });

    return registrosRestaurados;
  }
}