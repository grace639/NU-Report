// ผู้รับผิดชอบ: สมาชิกคนที่ 2
// แสดงรูปของ report จาก path ที่เก็บไว้
// มือถือ: path เป็นไฟล์ในเครื่อง -> Image.file
// เว็บ (ใช้ทดสอบ): path เป็น blob URL -> Image.network

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ReportImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final Widget fallback;

  const ReportImage(this.path,
      {super.key, this.width, this.height, this.fallback = const SizedBox.shrink()});

  /// มีรูปให้แสดงหรือไม่ (ไฟล์อาจถูกลบไปแล้ว)
  static bool exists(String? path) {
    if (path == null) return false;
    if (kIsWeb) return true;
    return File(path).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    if (!exists(path)) return fallback;
    return kIsWeb
        ? Image.network(path, width: width, height: height, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback)
        : Image.file(File(path), width: width, height: height, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback);
  }
}
