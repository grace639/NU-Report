// ผู้รับผิดชอบ: สมาชิกคนที่ 4 (สรุปผล) — R5
// สร้างไฟล์ CSV ของรายการแจ้งปัญหาในเดือนที่เลือก แล้วเปิดเมนูแชร์ของเครื่อง

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/report_dao.dart';
import '../models/report.dart';

class CsvExportService {
  final ReportDao _dao;
  CsvExportService({ReportDao? dao}) : _dao = dao ?? ReportDao();

  /// สร้างข้อความ CSV (แยกออกมาเป็นฟังก์ชันเพื่อเขียน unit test ได้)
  static String buildCsv(List<Report> reports) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    final lines = <String>[
      'id,วันที่แจ้ง,หัวข้อ,หมวดหมู่,สถานที่,ผู้แจ้ง,สถานะ,อัปเดตล่าสุด',
      for (final r in reports)
        [
          r.id,
          fmt.format(r.createdAt),
          r.title,
          r.categoryName,
          r.location,
          r.username,
          ReportStatus.label(r.status),
          fmt.format(r.updatedAt),
        ].map(_escape).join(','),
    ];
    return lines.join('\r\n');
  }

  // ค่าที่มี , " หรือขึ้นบรรทัดใหม่ ต้องครอบด้วย "..." และเปลี่ยน " เป็น ""
  static String _escape(Object? value) {
    final s = value?.toString() ?? '';
    if (s.contains(RegExp(r'[",\r\n]'))) return '"${s.replaceAll('"', '""')}"';
    return s;
  }

  /// สร้างไฟล์ CSV ของเดือนที่เลือก แล้วเปิดเมนูแชร์ (บนเว็บจะดาวน์โหลดไฟล์แทน)
  Future<void> exportMonth(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);
    final reports = await _dao.listInRange(from, to);

    final fileName = 'report_${DateFormat('yyyy-MM').format(from)}.csv';
    // ใส่ BOM (﻿) นำหน้า ไม่งั้น Excel อ่านภาษาไทยเป็นตัวอักษรเพี้ยน
    final content = '﻿${buildCsv(reports)}';

    final XFile xfile;
    if (kIsWeb) {
      xfile = XFile.fromData(utf8.encode(content), name: fileName, mimeType: 'text/csv');
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);
      xfile = XFile(file.path);
    }
    await SharePlus.instance
        .share(ShareParams(files: [xfile], fileNameOverrides: [fileName], text: 'รายงานแจ้งปัญหา'));
  }
}
