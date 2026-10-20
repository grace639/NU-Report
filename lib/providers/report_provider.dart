// ผู้รับผิดชอบ: สมาชิกคนที่ 1 (ฐานข้อมูล + ค้นหา)
// แหล่งข้อมูลกลางของรายการ report: หน้าแจ้ง หน้ารายการ หน้ารายละเอียด หน้าแรก
// ใช้ข้อมูลชุดเดียวกัน พอมีการเพิ่ม/เปลี่ยนสถานะ ทุกหน้าจะอัปเดตตามทันที

import 'package:flutter/foundation.dart';

import '../db/report_dao.dart';
import '../models/report.dart';
import '../models/report_comment.dart';

class ReportProvider extends ChangeNotifier {
  final ReportDao _dao;
  ReportProvider({ReportDao? dao}) : _dao = dao ?? ReportDao();

  List<Report> _reports = [];
  List<ReportCategory> _categories = [];
  int _unseenCount = 0;
  bool _loading = false;
  String? _error;

  // ตัวกรองปัจจุบัน (R2)
  String keyword = '';
  String? statusFilter;
  int? categoryFilter;

  List<Report> get reports => _reports;
  List<ReportCategory> get categories => _categories;
  int get unseenCount => _unseenCount;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;
    _categories = await _dao.getCategories();
    notifyListeners();
  }

  /// โหลดรายการตามตัวกรอง — userId = null คือโหมดแอดมิน (เห็นทุกคน)
  Future<void> load({int? userId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _reports = await _dao.search(
        userId: userId,
        keyword: keyword,
        status: statusFilter,
        categoryId: categoryFilter,
      );
      if (userId != null) _unseenCount = await _dao.countUnseen(userId);
    } catch (e) {
      _error = 'โหลดข้อมูลไม่สำเร็จ: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUnseen(int userId) async {
    _unseenCount = await _dao.countUnseen(userId);
    notifyListeners();
  }

  void clearFilters() {
    keyword = '';
    statusFilter = null;
    categoryFilter = null;
  }

  Future<void> add(Report report) async {
    await _dao.insert(report);
    await load(userId: report.userId);
  }
}
