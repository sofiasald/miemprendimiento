# Atelier

## Atelier — Del papel a la organización digital, simple y sin internet.

### App de gestión para emprendimientos de accesorios personalizados — Flutter + SQLite, 100% offline.

Aplicación móvil nativa Android (desarrollada en Flutter) pensada para una emprendedora que diseña y vende accesorios personalizados para eventos (vinchas con strass, bandas, tutús, vasos personalizados y escarapelas).

* El objetivo del producto es reemplazar el registro en papel por una herramienta simple que permita saber qué hay en stock, qué pedidos entregar y cuánto se gana realmente por mes.

### Tabla de contenidos
*Problema que resuelve
*Perfil de usuario
*Funcionalidades principales
*Arquitectura del sistema
*Stack tecnológico
*Requerimientos no funcionales
*Instalación y ejecución
*Estructura del proyecto
*Capturas de pantalla
*Roadmap
*Equipo
*Licencia
### Problema que resuelve
"Necesito pasar de las anotaciones en papel a una herramienta simple que me permita saber exactamente qué tengo en stock, qué pedidos entregar y cuánto gano realmente por mes."
## Atelier centraliza inventario, finanzas, pedidos y reportes en una sola app local, sin necesidad de conexión a internet ni cuentas de usuario.
### Arquitectura
La app se divide en dos módulos principales que comparten la misma base de datos local SQLite:

<img width="334" height="263" alt="image" src="https://github.com/user-attachments/assets/cbab6d2a-a164-4f50-8aae-57780b804bbf" />

Interconexión clave: los productos, combos y materiales del módulo de inventario son seleccionables al registrar ventas, gastos o pedidos en finanzas.

### Stack Tecnológico
Framework: Flutter

Lenguaje: Dart

Persistencia: SQLite (local)

Plataforma objetivo: Android (nativa)

Backup: JSON (export/import vía selector de archivos nativo)

Autenticación: Registro / login con huella o usario y contraseña (biometría)

Estado: State management con Flutter (ver pubspec.yaml)

### Licencia
Este proyecto es de uso privado para el emprendimiento.
