// ผู้รับผิดชอบ: สมาชิกคนที่ 2 (หน้าจอแจ้งปัญหา + ธีม)
// ธีมสีเทา-แสด ตามสีประจำมหาวิทยาลัยนเรศวร
// รวมสีไว้ที่เดียว หน้าจออื่นเรียกใช้ผ่าน Theme.of(context) ไม่ต้องใส่รหัสสีซ้ำ

import 'package:flutter/material.dart';

import '../models/report.dart';

class AppColors {
  static const orange = Color(0xFFF37021); // แสด
  static const orangeLight = Color(0xFFFFE3D1);
  static const grey = Color(0xFF4D4D4F); // เทาเข้ม
  static const greyLight = Color(0xFFF2F2F2);

  // สีของแต่ละสถานะ ใช้ทั้งในชิป รายการ และกราฟ
  static Color status(String status) => switch (status) {
        ReportStatus.pending => const Color(0xFF9E9E9E),
        ReportStatus.inProgress => orange,
        ReportStatus.resolved => const Color(0xFF2E7D32),
        ReportStatus.rejected => const Color(0xFFC62828),
        _ => grey,
      };
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.orange,
      onPrimary: Colors.white,
      secondary: AppColors.grey,
      surface: Colors.white,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.greyLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.grey,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        errorMaxLines: 2, // ข้อความเตือนยาวให้ขึ้นบรรทัดใหม่ ไม่ถูกตัดเป็น ...
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
