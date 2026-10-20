// ผู้รับผิดชอบ: สมาชิกคนที่ 1 (ฐานข้อมูล)
// เปิดไฟล์ SQLite, สร้างตาราง, ใส่ข้อมูลตั้งต้น
//
// ใช้ Singleton: ทั้งแอปมี Database object เดียว ไม่เปิดไฟล์ซ้ำหลายครั้ง

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../services/password_hasher.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'report_app.db';
  // v1 = users, categories, reports, comments
  // v2 = เพิ่มตาราง announcements (ประชาสัมพันธ์)
  static const _dbVersion = 2;

  Future<Database>? _db;

  // เปิดฐานข้อมูลครั้งแรกที่ถูกเรียก ครั้งต่อไปคืนตัวเดิม (lazy)
  // เก็บเป็น Future ไม่ใช่ Database: ถ้า 2 หน้าจอเรียกพร้อมกันตอนเปิดแอปครั้งแรก
  // ทั้งคู่จะรอ Future ตัวเดียวกัน ไม่เปิดไฟล์ซ้ำ 2 ครั้งระหว่างที่ยังสร้างตารางไม่เสร็จ
  Future<Database> get database => _db ??= _open();

  Future<Database> _open() async {
    // บนเว็บไม่มีไฟล์ SQLite ปกติ ใช้ SQLite แบบ WebAssembly เก็บใน IndexedDB ของเบราว์เซอร์แทน
    // (ใช้ทดสอบบนเว็บเท่านั้น บนมือถือใช้ sqflite ปกติ)
    if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
    final dir = await getDatabasesPath();
    return openDatabase(
      join(dir, _dbName),
      version: _dbVersion,
      // SQLite ปิด foreign key ไว้เป็นค่าเริ่มต้น ต้องเปิดเองทุกครั้งที่เชื่อมต่อ
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate, // เรียกครั้งเดียวตอนไฟล์ยังไม่มี
      // เรียกเมื่อเครื่องมีฐานข้อมูลเวอร์ชันเก่าอยู่แล้ว: เพิ่มเฉพาะส่วนที่ขาด ข้อมูลเดิมไม่หาย
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createAnnouncements(db);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin')),
        created_at TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )''');

    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        category_id INTEGER NOT NULL REFERENCES categories(id),
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        image_path TEXT,
        location TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        seen_by_owner INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_id INTEGER NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES users(id),
        message TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''');

    // index ช่วยให้ค้นหาตามผู้แจ้งและสถานะเร็วขึ้นเมื่อข้อมูลเยอะ
    await db.execute('CREATE INDEX idx_reports_user ON reports(user_id)');
    await db.execute('CREATE INDEX idx_reports_status ON reports(status)');

    await _seed(db);
    // หลัง _seed เพราะประกาศตัวอย่างอ้างถึง admin (id 1) ซึ่งต้องมีอยู่ก่อน (foreign key)
    await _createAnnouncements(db);
  }

  Future<void> _createAnnouncements(Database db) async {
    await db.execute('''
      CREATE TABLE announcements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL REFERENCES users(id),
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        pinned INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )''');
    await db.insert('announcements', {
      'admin_id': 1,
      'title': 'ยินดีต้อนรับสู่ NU Report',
      'body': 'แจ้งปัญหาภายในอาคารได้ตลอด 24 ชม. เจ้าหน้าที่จะอัปเดตสถานะให้ทราบในแอป',
      'pinned': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ข้อมูลตั้งต้นสำหรับทดสอบ (บัญชีทดสอบ ไม่ใช่รหัสผ่านจริงของใคร)
  Future<void> _seed(Database db) async {
    final batch = db.batch();
    for (final name in ['ไฟฟ้า', 'ประปา', 'อาคารสถานที่', 'ความสะอาด', 'อินเทอร์เน็ต', 'อื่นๆ']) {
      batch.insert('categories', {'name': name});
    }
    final now = DateTime.now().toIso8601String();
    batch.insert('users', {
      'username': 'admin',
      'password_hash': PasswordHasher.hash('admin123'),
      'role': 'admin',
      'created_at': now,
    });
    batch.insert('users', {
      'username': 'user',
      'password_hash': PasswordHasher.hash('user123'),
      'role': 'user',
      'created_at': now,
    });
    await batch.commit(noResult: true);

    // ตัวอย่าง report ให้หน้า dashboard มีข้อมูลตั้งแต่เปิดแอป
    final samples = [
      (1, 'ไฟทางเดินดับ', 'ไฟหน้าห้อง 301 ดับมา 3 วัน', 'pending', 2),
      (2, 'ก๊อกน้ำรั่ว', 'ห้องน้ำชาย ชั้น 2 ก๊อกปิดไม่สนิท', 'in_progress', 5),
      (5, 'Wi-Fi หลุดบ่อย', 'NU-WiFi ชั้น 4 หลุดทุก 10 นาที', 'resolved', 9),
      (4, 'ถังขยะเต็ม', 'ถังขยะหน้าโรงอาหารล้น', 'pending', 1),
    ];
    for (final (cat, title, desc, status, daysAgo) in samples) {
      final t = DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String();
      await db.insert('reports', {
        'user_id': 2,
        'category_id': cat,
        'title': title,
        'description': desc,
        'location': 'อาคารตัวอย่าง',
        'status': status,
        'seen_by_owner': 1,
        'created_at': t,
        'updated_at': t,
      });
    }
  }
}
