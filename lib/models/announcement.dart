// ผู้รับผิดชอบ: สมาชิกคนที่ 2 (ประชาสัมพันธ์)
// ข่าว/ประกาศจากเจ้าหน้าที่ 1 แถวในตาราง announcements

class Announcement {
  final int? id;
  final int adminId;
  final String title;
  final String body;
  final bool pinned; // ปักหมุด = แสดงบนสุดเสมอ
  final DateTime createdAt;
  final String? adminName; // จากการ JOIN

  Announcement({
    this.id,
    required this.adminId,
    required this.title,
    required this.body,
    this.pinned = false,
    DateTime? createdAt,
    this.adminName,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Announcement.fromMap(Map<String, Object?> map) => Announcement(
        id: map['id'] as int,
        adminId: map['admin_id'] as int,
        title: map['title'] as String,
        body: map['body'] as String,
        pinned: (map['pinned'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        adminName: map['admin_name'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'admin_id': adminId,
        'title': title,
        'body': body,
        'pinned': pinned ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };
}
