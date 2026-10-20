// ผู้รับผิดชอบ: สมาชิกคนที่ 1 (ฐานข้อมูล)
// คำสั่ง SQL ของตาราง comments

import 'package:sqflite/sqflite.dart';

import '../models/report_comment.dart';
import 'database_helper.dart';

class CommentDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<List<ReportComment>> listByReport(int reportId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT cm.*, u.username AS username
      FROM comments cm JOIN users u ON u.id = cm.user_id
      WHERE cm.report_id = ?
      ORDER BY cm.created_at''', [reportId]);
    return rows.map(ReportComment.fromMap).toList();
  }

  Future<void> insert(ReportComment comment) async {
    final db = await _db;
    await db.insert('comments', comment.toMap());
  }
}
