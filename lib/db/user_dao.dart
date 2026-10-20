// ผู้รับผิดชอบ: สมาชิกคนที่ 1 (ฐานข้อมูล)
// คำสั่ง SQL ของตาราง users

import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import 'database_helper.dart';

class UsernameTakenException implements Exception {}

class UserDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<AppUser?> findByUsername(String username) async {
    final db = await _db;
    // ใช้ ? (parameter binding) ไม่ต่อ string เอง ป้องกัน SQL injection
    final rows = await db.query('users', where: 'username = ?', whereArgs: [username], limit: 1);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser?> findById(int id) async {
    final db = await _db;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser> insert(AppUser user) async {
    final db = await _db;
    try {
      final id = await db.insert('users', user.toMap());
      return AppUser.fromMap({...user.toMap(), 'id': id});
    } on DatabaseException catch (e) {
      // username ซ้ำจะชน UNIQUE constraint
      if (e.isUniqueConstraintError()) throw UsernameTakenException();
      rethrow;
    }
  }
}
