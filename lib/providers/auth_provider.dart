// ผู้รับผิดชอบ: สมาชิกคนที่ 3 (ระบบสมาชิก + จัดการเรื่องของแอดมิน)
// เก็บสถานะ "ใครล็อกอินอยู่" ให้ทุกหน้าจอใช้ร่วมกันผ่าน Provider
// เมื่อ login/logout จะเรียก notifyListeners() ให้หน้าจอที่ฟังอยู่ build ใหม่

import 'package:flutter/foundation.dart';

import '../db/user_dao.dart';
import '../models/app_user.dart';
import '../services/password_hasher.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthProvider extends ChangeNotifier {
  final UserDao _userDao;
  AuthProvider({UserDao? userDao}) : _userDao = userDao ?? UserDao();

  AppUser? _currentUser;
  bool _loading = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get loading => _loading;

  Future<void> login(String username, String password) async {
    await _run(() async {
      final user = await _userDao.findByUsername(username.trim());
      // ไม่บอกว่าผิดที่ชื่อหรือรหัส เพื่อไม่ให้เดาได้ว่ามีชื่อนี้ในระบบ
      if (user == null || !PasswordHasher.verify(password, user.passwordHash)) {
        throw AuthException('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
      }
      _currentUser = user;
    });
  }

  Future<void> register(String username, String password) async {
    await _run(() async {
      try {
        _currentUser = await _userDao.insert(AppUser(
          username: username.trim(),
          passwordHash: PasswordHasher.hash(password),
        ));
      } on UsernameTakenException {
        throw AuthException('ชื่อผู้ใช้นี้ถูกใช้แล้ว');
      }
    });
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // ครอบงาน async: เปิด/ปิดสถานะ loading ให้ปุ่มแสดงวงกลมหมุนและกดซ้ำไม่ได้
  Future<void> _run(Future<void> Function() task) async {
    _loading = true;
    notifyListeners();
    try {
      await task();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ---------- validation ของฟอร์ม (ใช้ใน TextFormField.validator) ----------
  static String? validateUsername(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'กรุณากรอกชื่อผู้ใช้';
    if (s.length < 3) return 'อย่างน้อย 3 ตัวอักษร';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(s)) return 'ใช้ได้เฉพาะ a-z, 0-9 และ _';
    return null;
  }

  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (v.length < 6) return 'อย่างน้อย 6 ตัวอักษร';
    return null;
  }
}
