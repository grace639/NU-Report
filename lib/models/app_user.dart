// ผู้รับผิดชอบ: สมาชิกคนที่ 1 (ฐานข้อมูล)
// Model ของผู้ใช้ 1 แถวในตาราง users

class AppUser {
  final int? id;
  final String username;
  final String passwordHash; // เก็บเฉพาะค่า hash ไม่เก็บรหัสผ่านจริง
  final String role; // 'user' หรือ 'admin'
  final DateTime createdAt;

  AppUser({
    this.id,
    required this.username,
    required this.passwordHash,
    this.role = 'user',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == 'admin';

  // แปลงแถวจาก SQLite (Map) เป็น object
  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
        id: map['id'] as int,
        username: map['username'] as String,
        passwordHash: map['password_hash'] as String,
        role: map['role'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  // แปลง object เป็น Map เพื่อ insert ลง SQLite
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'password_hash': passwordHash,
        'role': role,
        'created_at': createdAt.toIso8601String(),
      };
}
