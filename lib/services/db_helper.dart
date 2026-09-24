import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('emprendimiento.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Usuarios y acceso
    await db.execute('''
      CREATE TABLE usuarios (
        id TEXT PRIMARY KEY,
        usuario TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL
      )
    ''');

    // Inventario base
    await db.execute('''
      CREATE TABLE materiales (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        unidad TEXT NOT NULL,
        cantidad REAL DEFAULT 0,
        stockMinimo REAL DEFAULT 0,
        visible INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE variantes (
        id TEXT PRIMARY KEY,
        materialId TEXT NOT NULL,
        nombre TEXT NOT NULL,
        cantidad REAL DEFAULT 0,
        stockMinimo REAL DEFAULT 0,
        visible INTEGER DEFAULT 1,
        FOREIGN KEY (materialId) REFERENCES materiales (id)
      )
    ''');

    // Productos y combos
    await db.execute('''
      CREATE TABLE productos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        descripcion TEXT,
        visible INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE combos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        descripcion TEXT,
        visible INTEGER DEFAULT 1
      )
    ''');

    // Tablas intermedias (Relaciones)
    await db.execute('''
      CREATE TABLE producto_material (
        productoId TEXT NOT NULL,
        materialId TEXT NOT NULL,
        cantidad REAL,
        FOREIGN KEY (productoId) REFERENCES productos (id),
        FOREIGN KEY (materialId) REFERENCES materiales (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE combo_item (
        comboId TEXT NOT NULL,
        productoId TEXT,
        materialId TEXT,
        cantidad REAL,
        FOREIGN KEY (comboId) REFERENCES combos (id),
        FOREIGN KEY (productoId) REFERENCES productos (id),
        FOREIGN KEY (materialId) REFERENCES materiales (id)
      )
    ''');

    // Historial financiero y de stock
    await db.execute('''
      CREATE TABLE ventas (
        id TEXT PRIMARY KEY,
        productoId TEXT,
        comboId TEXT,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        visible INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE movimiento_stock (
        id TEXT PRIMARY KEY,
        ventaId TEXT NOT NULL,
        materialId TEXT NOT NULL,
        cantidad REAL NOT NULL,
        FOREIGN KEY (ventaId) REFERENCES ventas (id),
        FOREIGN KEY (materialId) REFERENCES materiales (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE gastos (
        id TEXT PRIMARY KEY,
        materialId TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        visible INTEGER DEFAULT 1,
        FOREIGN KEY (materialId) REFERENCES materiales (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pedidos (
        id TEXT PRIMARY KEY,
        productoId TEXT,
        comboId TEXT,
        cliente TEXT NOT NULL,
        fechaEntrega TEXT NOT NULL,
        visible INTEGER DEFAULT 1,
        FOREIGN KEY (productoId) REFERENCES productos (id),
        FOREIGN KEY (comboId) REFERENCES combos (id)
      )
    ''');
  }
}
