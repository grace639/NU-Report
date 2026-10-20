// ผู้รับผิดชอบ: สมาชิกคนที่ 3 (ระบบสมาชิก)
// แปลงรหัสผ่านเป็น SHA-256 ก่อนเก็บลงฐานข้อมูล
// ถ้าไฟล์ฐานข้อมูลหลุด ก็อ่านรหัสผ่านจริงไม่ได้

import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  // salt คงที่ของแอป ช่วยให้ hash ไม่ตรงกับตาราง hash สำเร็จรูปทั่วไป
  static const _salt = 'mad-report-app';

  static String hash(String password) =>
      sha256.convert(utf8.encode('$_salt:$password')).toString();

  static bool verify(String password, String hashed) => hash(password) == hashed;
}
