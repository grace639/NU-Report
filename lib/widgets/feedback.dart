// ผู้รับผิดชอบ: สมาชิกคนที่ 2
// ฟังก์ชันแจ้งผลลัพธ์/ข้อผิดพลาดให้ผู้ใช้ ใช้ร่วมกันทุกหน้าจอ

import 'package:flutter/material.dart';

void showError(BuildContext context, String message, {VoidCallback? onRetry}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      action: onRetry == null
          ? null
          : SnackBarAction(label: 'ลองใหม่', textColor: Colors.white, onPressed: onRetry),
    ));
}

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green.shade700));
}
