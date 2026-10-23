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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
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
        pedidoId TEXT,
        cliente TEXT,
        nombreItem TEXT,
        variante TEXT,
        cantidad INTEGER DEFAULT 1,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        tipo TEXT DEFAULT 'directa',
        visible INTEGER DEFAULT 1,
        fotoPath TEXT
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
        materialId TEXT,
        materialNombre TEXT,
        varianteId TEXT,
        varianteNombre TEXT,
        cantidad REAL DEFAULT 0,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        visible INTEGER DEFAULT 1,
        fotoPath TEXT,
        FOREIGN KEY (materialId) REFERENCES materiales (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pedidos (
        id TEXT PRIMARY KEY,
        productoId TEXT,
        comboId TEXT,
        cliente TEXT NOT NULL,
        nombreItem TEXT,
        variante TEXT DEFAULT 'Estándar',
        cantidad INTEGER DEFAULT 1,
        monto REAL DEFAULT 0,
        fechaEntrega TEXT NOT NULL,
        fechaRegistro TEXT,
        fechaEntregaReal TEXT,
        observaciones TEXT,
        estado TEXT DEFAULT 'pendiente',
        visible INTEGER DEFAULT 1,
        fotoPath TEXT,
        FOREIGN KEY (productoId) REFERENCES productos (id),
        FOREIGN KEY (comboId) REFERENCES combos (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _asegurarColumnas(db);
    }
  }

  Future<void> _onOpen(Database db) async {
    await _asegurarColumnas(db);
  }

  Future<void> _asegurarColumnas(Database db) async {
    // Gastos
    await _agregarColumnaSiNoExiste(db, 'gastos', 'materialNombre', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'gastos', 'varianteId', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'gastos', 'varianteNombre', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'gastos', 'cantidad', 'REAL DEFAULT 0');

    // Ventas
    await _agregarColumnaSiNoExiste(db, 'ventas', 'nombreItem', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'ventas', 'tipo', 'TEXT DEFAULT "directa"');
    await _agregarColumnaSiNoExiste(db, 'ventas', 'pedidoId', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'ventas', 'cliente', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'ventas', 'variante', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'ventas', 'cantidad', 'INTEGER DEFAULT 1');

    // Pedidos
    await _agregarColumnaSiNoExiste(db, 'pedidos', 'nombreItem', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'pedidos', 'variante', 'TEXT DEFAULT "Estándar"');
    await _agregarColumnaSiNoExiste(db, 'pedidos', 'cantidad', 'INTEGER DEFAULT 1');
    await _agregarColumnaSiNoExiste(db, 'pedidos', 'monto', 'REAL DEFAULT 0');
    await _agregarColumnaSiNoExiste(db, 'pedidos', 'fechaRegistro', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'pedidos', 'fechaEntregaReal', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'pedidos', 'observaciones', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'pedidos', 'estado', 'TEXT DEFAULT "pendiente"');

    // Fotos / Comprobantes adjuntos
    await _agregarColumnaSiNoExiste(db, 'pedidos', 'fotoPath', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'ventas', 'fotoPath', 'TEXT');
    await _agregarColumnaSiNoExiste(db, 'gastos', 'fotoPath', 'TEXT');
  }

  Future<void> _agregarColumnaSiNoExiste(
    Database db,
    String tabla,
    String columna,
    String tipoDefinicion,
  ) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($tabla)');
      final existe = info.any((row) => row['name'] == columna);
      if (!existe) {
        await db.execute('ALTER TABLE $tabla ADD COLUMN $columna $tipoDefinicion');
      }
    } catch (_) {
      // Ignorar si la tabla aún no existe o ya posee la columna
    }
  }
}
