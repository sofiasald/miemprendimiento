//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finanzas_provider.dart';
//import '../../providers/inventario_provider.dart';

/// Pantalla de Ajustes y Respaldo de Datos.
/// Implementa la arquitectura offline mediante exportación e importación en formato JSON.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  // Registro dinámico de la última copia de seguridad (inicia sin copias previas)
  String _ultimaCopia = 'Sin copias registradas';

  // Controla el estado de carga durante los procesos pesados de base de datos
  bool _estaProcesando = false;

  // Constantes de color del sistema de diseño Atelier
  static const Color kRosaPrincipal = Color(0xFFE85E98);
  static const Color kFondoGris = Color(0xFFF8F9FA);
  static const Color kBordeGris = Color(0xFFE0E0E0);
  static const Color kTextoOscuro = Color(0xFF212121);
  static const Color kTextoGris = Color(0xFF757575);

  /// LÓGICA DE EXPORTACIÓN (SQLite -> JSON -> Compartir)
  Future<void> _ejecutarExportacion() async {
    setState(() => _estaProcesando = true);

    // Simulación del volcado asíncrono de tablas a JSON
    await Future.delayed(const Duration(milliseconds: 1400));

    final ahora = DateTime.now();
    final horaFormateada =
        '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year}, ${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}hs';

    if (!mounted) return;
    setState(() {
      _estaProcesando = false;
      _ultimaCopia = horaFormateada;
    });

    // Muestra el modal gráfico de Exportación Exitosa diseñado en Figma
    _mostrarModalExito(
      titulo: 'Exportación Exitosa',
      descripcion: 'El archivo JSON se generó y guardó correctamente.',
    );
  }

  /// LÓGICA DE IMPORTACIÓN (Seleccionar JSON -> Confirmar -> Restaurar)
  Future<void> _iniciarProcesoRestauracion() async {
    // 1. Despliega el diálogo modal de advertencia preventiva de Figma
    final bool? confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.black87, size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '¿Restaurar copia de seguridad?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTextoOscuro,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Se reemplazarán todos los productos, materiales y finanzas actuales con los datos del archivo JSON seleccionado.',
          style: TextStyle(fontSize: 13, color: kTextoGris, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: kTextoGris, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Restaurar',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    // 2. Si la usuaria confirma, se ejecuta la restauración
    if (confirmado == true) {
      setState(() => _estaProcesando = true);

      // Simulación de lectura de archivo y sobreescritura de base SQLite
      await Future.delayed(const Duration(milliseconds: 1600));

      if (!mounted) return;
      setState(() => _estaProcesando = false);

      // Recarga los providers para actualizar inventario y balances
      context.read<FinanzasProvider>().cargarVentas();
      context.read<FinanzasProvider>().cargarGastos();
      context.read<FinanzasProvider>().cargarPedidos();

      _mostrarModalExito(
        titulo: 'Restaurado con éxito',
        descripcion: 'Toda tu información ha sido recuperada.',
      );
    }
  }

  /// Despliega el componente emergente de éxito
  void _mostrarModalExito({required String titulo, required String descripcion}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Círculo rosado con tilde
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFF48FB1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.black87, size: 38),
              ),
              const SizedBox(height: 18),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTextoOscuro,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                descripcion,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: kTextoGris),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si la app está procesando, renderiza la pantalla de carga de Atelier
    if (_estaProcesando) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Atelier',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: kRosaPrincipal,
                  letterSpacing: 1.1,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                color: Color(0xFF757575),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AJUSTES',
          style: TextStyle(
            color: kTextoOscuro,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BANNER: Almacenamiento Local (100% Offline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: kFondoGris,
                border: Border(
                  left: BorderSide(color: Colors.black87, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Almacenamiento Local (100% Offline)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: kTextoOscuro,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Tus datos se guardan únicamente en este teléfono',
                    style: TextStyle(fontSize: 12, color: kTextoGris),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Encabezado de sección
            const Text(
              'COPIA DE SEGURIDAD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kTextoGris,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),

            // TARJETA 1: Exportar Datos JSON
            _tarjetaAccion(
              icono: Icons.upload_file_outlined,
              titulo: 'Exportar Datos',
              descripcion:
                  'Guardar un archivo JSON con todo tu catálogo, finanzas e historial en tu teléfono',
              detalleInferior: 'Última copia: $_ultimaCopia',
              textoBoton: 'Exportar JSON',
              onTap: _ejecutarExportacion,
            ),
            const SizedBox(height: 18),

            // TARJETA 2: Restaurar Datos JSON
            _tarjetaAccion(
              icono: Icons.settings_backup_restore_rounded,
              titulo: 'Restaurar Datos',
              descripcion:
                  'Carga un archivo JSON previo para recuperar toda tu información en este dispositivo.',
              textoBoton: 'Seleccionar Archivo JSON',
              onTap: _iniciarProcesoRestauracion,
            ),
            const SizedBox(height: 36),

            // PIE DE PÁGINA: Información institucional de la App
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'INFORMACIÓN DE LA APP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kTextoGris,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Versión 1.0.0 (Offline SQLite) – Atelier',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextoOscuro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Construye cada tarjeta de acción con borde definido, sombra y botón primario
  Widget _tarjetaAccion({
    required IconData icono,
    required String titulo,
    required String descripcion,
    String? detalleInferior,
    required String textoBoton,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBordeGris.withValues(alpha:0.85)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono en caja oscura estilizada
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: kTextoOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextoGris,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (detalleInferior != null) ...[
            const SizedBox(height: 12),
            Text(
              detalleInferior,
              style: const TextStyle(fontSize: 11, color: kTextoGris),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRosaPrincipal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: onTap,
              child: Text(
                textoBoton,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}