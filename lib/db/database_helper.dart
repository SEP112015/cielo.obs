import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/observacion.dart';
import '../models/perfil.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cielo_obs.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE observacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        fecha_hora TEXT NOT NULL,
        lat REAL,
        lng REAL,
        ubicacion_texto TEXT,
        duracion_seg INTEGER,
        categoria TEXT NOT NULL,
        condiciones_cielo TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        foto_path TEXT,
        audio_path TEXT,
        creado_en TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE perfil (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        apellido TEXT NOT NULL,
        matricula TEXT NOT NULL,
        foto_path TEXT NOT NULL,
        frase TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertObservacion(Observacion observacion) async {
    final db = await database;
    return await db.insert('observacion', observacion.toMap());
  }

  Future<List<Observacion>> getObservaciones() async {
    final db = await database;
    final result = await db.query('observacion', orderBy: 'fecha_hora DESC');
    return result.map((map) => Observacion.fromMap(map)).toList();
  }
  Future<List<Observacion>> getObservacionesFiltradas({
  String? categoria,
  String? lugar,
  String? fecha,
}) async {
  final db = await database;

  final List<String> whereClauses = [];
  final List<dynamic> whereArgs = [];

  if (categoria != null && categoria.isNotEmpty) {
    whereClauses.add('categoria = ?');
    whereArgs.add(categoria);
  }

  if (lugar != null && lugar.isNotEmpty) {
    whereClauses.add('ubicacion_texto LIKE ?');
    whereArgs.add('%$lugar%');
  }

  if (fecha != null && fecha.isNotEmpty) {
    whereClauses.add('fecha_hora LIKE ?');
    whereArgs.add('$fecha%');
  }

  final result = await db.query(
    'observacion',
    where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
    whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    orderBy: 'fecha_hora DESC',
  );

  return result.map((map) => Observacion.fromMap(map)).toList();
}

  Future<Observacion?> getObservacionById(int id) async {
    final db = await database;
    final result = await db.query(
      'observacion',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Observacion.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateObservacion(Observacion observacion) async {
    final db = await database;
    return await db.update(
      'observacion',
      observacion.toMap(),
      where: 'id = ?',
      whereArgs: [observacion.id],
    );
  }

  Future<int> deleteObservacion(int id) async {
    final db = await database;
    return await db.delete(
      'observacion',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllObservaciones() async {
    final db = await database;
    return await db.delete('observacion');
  }

  Future<int> savePerfil(Perfil perfil) async {
    final db = await database;
    return await db.insert(
      'perfil',
      perfil.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Perfil?> getPerfil() async {
    final db = await database;
    final result = await db.query('perfil', limit: 1);

    if (result.isNotEmpty) {
      return Perfil.fromMap(result.first);
    }
    return null;
  }

  Future<int> deletePerfil() async {
    final db = await database;
    return await db.delete('perfil');
  }

  Future<void> borrarTodo() async {
    final db = await database;
    await db.delete('observacion');
    await db.delete('perfil');
  }
}