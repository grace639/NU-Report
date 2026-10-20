// ผู้รับผิดชอบ: สมาชิกคนที่ 1 (ฐานข้อมูล)
// Model ของรายการแจ้งปัญหา 1 แถวในตาราง reports

class ReportStatus {
  static const pending = 'pending';
  static const inProgress = 'in_progress';
  static const resolved = 'resolved';
  static const rejected = 'rejected';

  static const all = [pending, inProgress, resolved, rejected];

  static String label(String status) => switch (status) {
        pending => 'รอดำเนินการ',
        inProgress => 'กำลังดำเนินการ',
        resolved => 'แก้ไขแล้ว',
        rejected => 'ไม่รับเรื่อง',
        _ => status,
      };
}

class Report {
  final int? id;
  final int userId;
  final int categoryId;
  final String title;
  final String description;
  final String? imagePath; // path ของรูปที่ copy ไว้ในโฟลเดอร์ของแอป
  final String? location; // สถานที่ที่ผู้ใช้พิมพ์ เช่น "อาคาร SC2 ชั้น 3"
  final String status;
  final bool seenByOwner; // false = แอดมินอัปเดตแล้ว ผู้แจ้งยังไม่ได้เปิดดู (ใช้กับ R4)
  final DateTime createdAt;
  final DateTime updatedAt;

  // ฟิลด์จากการ JOIN (ไม่ได้เก็บในตาราง reports)
  final String? categoryName;
  final String? username;

  Report({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.description,
    this.imagePath,
    this.location,
    this.status = ReportStatus.pending,
    this.seenByOwner = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.categoryName,
    this.username,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Report.fromMap(Map<String, Object?> map) => Report(
        id: map['id'] as int,
        userId: map['user_id'] as int,
        categoryId: map['category_id'] as int,
        title: map['title'] as String,
        description: map['description'] as String,
        imagePath: map['image_path'] as String?,
        location: map['location'] as String?,
        status: map['status'] as String,
        seenByOwner: (map['seen_by_owner'] as int) == 1, // SQLite ไม่มี bool ใช้ 0/1
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        categoryName: map['category_name'] as String?,
        username: map['username'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'image_path': imagePath,
        'location': location,
        'status': status,
        'seen_by_owner': seenByOwner ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
