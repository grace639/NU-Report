// ผู้รับผิดชอบ: สมาชิกคนที่ 1 (ฐานข้อมูล)
// ข้อความตอบกลับ/บันทึกการเปลี่ยนสถานะของ report

class ReportComment {
  final int? id;
  final int reportId;
  final int userId;
  final String message;
  final DateTime createdAt;
  final String? username; // จากการ JOIN

  ReportComment({
    this.id,
    required this.reportId,
    required this.userId,
    required this.message,
    DateTime? createdAt,
    this.username,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ReportComment.fromMap(Map<String, Object?> map) => ReportComment(
        id: map['id'] as int,
        reportId: map['report_id'] as int,
        userId: map['user_id'] as int,
        message: map['message'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        username: map['username'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'report_id': reportId,
        'user_id': userId,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };
}

class ReportCategory {
  final int id;
  final String name;
  ReportCategory(this.id, this.name);

  factory ReportCategory.fromMap(Map<String, Object?> map) =>
      ReportCategory(map['id'] as int, map['name'] as String);
}
