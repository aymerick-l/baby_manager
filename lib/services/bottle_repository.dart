import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/bottle.dart';

class BottleRepository {
  /// Returns the SQLite database.
  Future<Database> get _db => DatabaseHelper.database;

  /// Creates a new bottle.
  Future<void> create(Bottle bottle) async {
    final db = await _db;

    await db.insert(
      'bottles',
      bottle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Returns all bottles.
  ///
  /// Most recent feeding first.
  Future<List<Bottle>> getAll() async {
    final db = await _db;

    final rows = await db.query(
      'bottles',
      orderBy: 'feeding_started_at DESC',
    );

    return rows.map(Bottle.fromMap).toList();
  }

  /// Returns a bottle by its ID.
  Future<Bottle?> getById(String id) async {
    final db = await _db;

    final rows = await db.query(
      'bottles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Bottle.fromMap(rows.first);
  }

  /// Returns all bottles belonging to a child.
  ///
  /// Most recent feeding first.
  Future<List<Bottle>> getByChildId(String childId) async {
    final db = await _db;

    final rows = await db.query(
      'bottles',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'feeding_started_at DESC',
    );

    return rows.map(Bottle.fromMap).toList();
  }

  /// Updates an existing bottle.
  Future<void> update(Bottle bottle) async {
    final db = await _db;

    final updatedBottle = bottle.copyWith(
      updatedAt: DateTime.now(),
    );

    final count = await db.update(
      'bottles',
      updatedBottle.toMap(),
      where: 'id = ?',
      whereArgs: [bottle.id],
    );

    if (count == 0) {
      throw StateError(
        'Bottle with id "${bottle.id}" does not exist.',
      );
    }
  }

  /// Deletes a bottle by its ID.
  Future<void> delete(String id) async {
    final db = await _db;

    await db.delete(
      'bottles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all bottles.
  Future<void> deleteAll() async {
    final db = await _db;

    await db.delete('bottles');
  }

  /// Deletes all bottles belonging to a child.
  Future<void> deleteByChildId(String childId) async {
    final db = await _db;

    await db.delete(
      'bottles',
      where: 'child_id = ?',
      whereArgs: [childId],
    );
  }

  /// Returns the number of bottles.
  Future<int> count() async {
    final db = await _db;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM bottles',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns the number of bottles for a child.
  Future<int> countByChildId(String childId) async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM bottles
      WHERE child_id = ?
      ''',
      [childId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}