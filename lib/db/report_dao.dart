// ผู้รับผิดชอบ: สมาชิกคนที่ 1 (ฐานข้อมูล)
// คำสั่ง SQL ของตาราง reports: เพิ่ม, ค้นหา/กรอง (R2), เปลี่ยนสถานะ, สถิติ

import 'package:sqflite/sqflite.dart';

import '../models/report.dart';
import '../models/report_comment.dart';
import 'database_helper.dart';

class ReportDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  // JOIN เพื่อได้ชื่อหมวดหมู่และชื่อผู้แจ้งมาพร้อมกันใน query เดียว
  static const _selectWithJoin = '''
    SELECT r.*, c.name AS category_name, u.username AS username
    FROM reports r
    JOIN categories c ON c.id = r.category_id
    JOIN users u ON u.id = r.user_id
  ''';

  Future<List<ReportCategory>> getCategories() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'id');
    return rows.map(ReportCategory.fromMap).toList();
  }

  Future<int> insert(Report report) async {
    final db = await _db;
    return db.insert('reports', report.toMap());
  }

  /// ค้นหา report (R2)
  /// - userId = null หมายถึงดูทุกคน (แอดมิน)
  /// - keyword ค้นทั้งหัวข้อ รายละเอียด และสถานที่
  /// - status / categoryId = null หมายถึงไม่กรอง
  Future<List<Report>> search({
    int? userId,
    String keyword = '',
    String? status,
    int? categoryId,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    if (userId != null) {
      where.add('r.user_id = ?');
      args.add(userId);
    }
    if (keyword.trim().isNotEmpty) {
      where.add('(r.title LIKE ? OR r.description LIKE ? OR r.location LIKE ?)');
      final like = '%${keyword.trim()}%';
      args.addAll([like, like, like]);
    }
    if (status != null) {
      where.add('r.status = ?');
      args.add(status);
    }
    if (categoryId != null) {
      where.add('r.category_id = ?');
      args.add(categoryId);
    }

    final sql = StringBuffer(_selectWithJoin);
    if (where.isNotEmpty) sql.write(' WHERE ${where.join(' AND ')}');
    sql.write(' ORDER BY r.updated_at DESC');

    final rows = await db.rawQuery(sql.toString(), args);
    return rows.map(Report.fromMap).toList();
  }

  Future<Report?> findById(int id) async {
    final db = await _db;
    final rows = await db.rawQuery('$_selectWithJoin WHERE r.id = ?', [id]);
    return rows.isEmpty ? null : Report.fromMap(rows.first);
  }

  /// แอดมินเปลี่ยนสถานะ (R3) — ใช้ transaction ให้ "อัปเดตสถานะ" กับ "บันทึกข้อความ"
  /// สำเร็จพร้อมกันหรือล้มเหลวพร้อมกัน ไม่มีกรณีสำเร็จครึ่งเดียว
  Future<void> updateStatus({
    required int reportId,
    required String status,
    required int adminId,
    String? note,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'reports',
        {
          'status': status,
          'seen_by_owner': 0, // ให้ผู้แจ้งเห็นว่ามีอัปเดตใหม่ (R4)
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [reportId],
      );
      final msg = 'เปลี่ยนสถานะเป็น "${ReportStatus.label(status)}"'
          '${note != null && note.trim().isNotEmpty ? '\n${note.trim()}' : ''}';
      await txn.insert(
        'comments',
        ReportComment(reportId: reportId, userId: adminId, message: msg).toMap(),
      );
    });
  }

  /// R4: จำนวน report ของผู้ใช้ที่มีอัปเดตแต่ยังไม่ได้เปิดดู
  Future<int> countUnseen(int userId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM reports WHERE user_id = ? AND seen_by_owner = 0',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markSeen(int reportId) async {
    final db = await _db;
    await db.update('reports', {'seen_by_owner': 1}, where: 'id = ?', whereArgs: [reportId]);
  }

  /// R5: นับจำนวนตามสถานะ เช่น {pending: 3, resolved: 1}
  Future<Map<String, int>> countByStatus({DateTime? from, DateTime? to}) =>
      _countGroup('status', from: from, to: to);

  /// R5: นับจำนวนตามหมวดหมู่ เช่น {ไฟฟ้า: 2, ประปา: 1}
  Future<Map<String, int>> countByCategory({DateTime? from, DateTime? to}) =>
      _countGroup('c.name', from: from, to: to);

  Future<Map<String, int>> _countGroup(String column, {DateTime? from, DateTime? to}) async {
    final db = await _db;
    final (where, args) = _dateRange(from, to);
    final rows = await db.rawQuery('''
      SELECT $column AS k, COUNT(*) AS n
      FROM reports r JOIN categories c ON c.id = r.category_id
      $where GROUP BY $column ORDER BY n DESC''', args);
    return {for (final row in rows) row['k'] as String: row['n'] as int};
  }

  /// R5: รายการทั้งหมดในช่วงวันที่ สำหรับส่งออก CSV
  Future<List<Report>> listInRange(DateTime from, DateTime to) async {
    final db = await _db;
    final (where, args) = _dateRange(from, to);
    final rows = await db.rawQuery('$_selectWithJoin $where ORDER BY r.created_at', args);
    return rows.map(Report.fromMap).toList();
  }

  // เก็บวันที่เป็น ISO-8601 จึงเปรียบเทียบแบบ string ได้ตรงลำดับเวลา
  (String, List<Object?>) _dateRange(DateTime? from, DateTime? to) {
    if (from == null || to == null) return ('', []);
    return (
      'WHERE r.created_at >= ? AND r.created_at < ?',
      [from.toIso8601String(), to.toIso8601String()],
    );
  }
}
