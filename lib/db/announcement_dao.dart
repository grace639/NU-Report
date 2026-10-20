// ผู้รับผิดชอบ: สมาชิกคนที่ 2 (ประชาสัมพันธ์)
// คำสั่ง SQL ของตาราง announcements

import 'package:sqflite/sqflite.dart';

import '../models/announcement.dart';
import 'database_helper.dart';

class AnnouncementDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  // เรียง: ปักหมุดก่อน (pinned DESC) แล้วใหม่สุดก่อน
  Future<List<Announcement>> listAll() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT a.*, u.username AS admin_name
      FROM announcements a JOIN users u ON u.id = a.admin_id
      ORDER BY a.pinned DESC, a.created_at DESC''');
    return rows.map(Announcement.fromMap).toList();
  }

  Future<void> insert(Announcement a) async {
    final db = await _db;
    await db.insert('announcements', a.toMap());
  }

  Future<void> setPinned(int id, bool pinned) async {
    final db = await _db;
    await db.update('announcements', {'pinned': pinned ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('announcements', where: 'id = ?', whereArgs: [id]);
  }
}
