import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'selector_articulo_acordeon.dart'; // Para reutilizar AtelierColors

/// Selector de fotos para Pedidos, Ventas y Gastos.
/// Permite tomar foto o elegir de la galería, guarda una copia fija
/// en el almacenamiento local y devuelve la ruta permanente (fotoPath).
class SelectorFoto extends StatefulWidget {
  final String? rutaInicial;
  final ValueChanged<String?> onFotoCambiada;

  const SelectorFoto({
    super.key,
    this.rutaInicial,
    required this.onFotoCambiada,
  });

  @override
  State<SelectorFoto> createState() => _SelectorFotoState();
}

class _SelectorFotoState extends State<SelectorFoto> {
  String? _rutaActual;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _rutaActual = widget.rutaInicial;
  }

  // Detecta cuando el formulario padre limpia la foto 
  @override
  void didUpdateWidget(covariant SelectorFoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rutaInicial != oldWidget.rutaInicial) {
      setState(() {
        _rutaActual = widget.rutaInicial;
      });
    }
  }

  Future<void> _elegirOrigen() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AtelierColors.rosa),
                title: const Text('Tomar foto con la cámara', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _procesarImagen(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AtelierColors.rosa),
                title: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _procesarImagen(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _procesarImagen(ImageSource source) async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Optimiza el peso en memoria y disco
      );
      if (imagen == null) return;

      // 1. Obtener la carpeta de documentos privados de la app
      final appDir = await getApplicationDocumentsDirectory();
      final nombreArchivo = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final rutaDestino = '${appDir.path}/$nombreArchivo';

      // 2. Guardar una copia permanente
      final File imagenGuardada = await File(imagen.path).copy(rutaDestino);

      setState(() {
        _rutaActual = imagenGuardada.path;
      });
      widget.onFotoCambiada(_rutaActual);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar la imagen seleccionada.')),
        );
      }
    }
  }

  void _eliminarFoto() {
    setState(() {
      _rutaActual = null;
    });
    widget.onFotoCambiada(null);
  }

  @override
  Widget build(BuildContext context) {
    if (_rutaActual != null && File(_rutaActual!).existsSync()) {
      return Container(
        height: 72,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AtelierColors.grisBorde),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(_rutaActual!),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Foto adjuntada',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AtelierColors.negroSuave),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Se mostrará en la cabecera del ticket',
                    style: TextStyle(fontSize: 11, color: AtelierColors.grisTexto),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.black45, size: 20),
              onPressed: _eliminarFoto,
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _elegirOrigen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AtelierColors.grisBorde),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_a_photo_outlined, size: 18, color: AtelierColors.rosa),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Adjuntar foto/imagen (Opcional)',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AtelierColors.rosa,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}