import 'package:flutter_test/flutter_test.dart';
import 'package:report_app/models/report.dart';
import 'package:report_app/providers/auth_provider.dart';
import 'package:report_app/services/csv_export_service.dart';
import 'package:report_app/services/link_guard.dart';
import 'package:report_app/services/password_hasher.dart';

void main() {
  test('รหัสผ่านถูก hash และตรวจสอบได้', () {
    final h = PasswordHasher.hash('secret1');
    expect(h, isNot('secret1'));
    expect(PasswordHasher.verify('secret1', h), isTrue);
    expect(PasswordHasher.verify('wrong', h), isFalse);
  });

  test('validation ชื่อผู้ใช้และรหัสผ่าน', () {
    expect(AuthProvider.validateUsername('ab'), isNotNull);
    expect(AuthProvider.validateUsername('ab cd'), isNotNull);
    expect(AuthProvider.validateUsername('user_01'), isNull);
    expect(AuthProvider.validatePassword('123'), isNotNull);
    expect(AuthProvider.validatePassword('123456'), isNull);
  });

  test('LinkGuard: เรื่องแจ้งปัญหาห้ามมีลิงก์', () {
    expect(LinkGuard.noLinks('ไฟดับห้อง 301 อาคาร SC2'), isNull);
    expect(LinkGuard.noLinks('ปิดน้ำ ส. 25 ต.ค. 2569'), isNull); // จุดในภาษาไทยไม่ใช่ลิงก์
    expect(LinkGuard.noLinks('ดูรูปที่ https://evil.com/x'), isNotNull);
    expect(LinkGuard.noLinks('กดที่ www.free-gift.xyz'), isNotNull);
    expect(LinkGuard.noLinks('รายละเอียด bit.ly/abc123'), isNotNull);
  });

  test('LinkGuard: ประกาศมีลิงก์ได้เฉพาะ nu.ac.th', () {
    expect(LinkGuard.onlyTrustedLinks('ดูที่ https://www.nu.ac.th/news'), isNull);
    expect(LinkGuard.onlyTrustedLinks('ดูที่ nu.ac.th'), isNull);
    expect(LinkGuard.onlyTrustedLinks('ดูที่ https://evil.com'), isNotNull);
    // โดเมนปลอมที่มีคำว่า nu.ac.th อยู่ข้างใน ต้องถูกบล็อก
    expect(LinkGuard.onlyTrustedLinks('https://nu.ac.th.evil.com/login'), isNotNull);
  });

  test('CSV escape เครื่องหมาย , และ "', () {
    final csv = CsvExportService.buildCsv([
      Report(
        id: 1,
        userId: 1,
        categoryId: 1,
        title: 'ไฟดับ, ห้อง "301"',
        description: '-',
        categoryName: 'ไฟฟ้า',
        username: 'user',
        location: 'SC2',
        createdAt: DateTime(2026, 10, 1, 9),
        updatedAt: DateTime(2026, 10, 1, 9),
      ),
    ]);
    final lines = csv.split('\r\n');
    expect(lines, hasLength(2));
    expect(lines[1], contains('"ไฟดับ, ห้อง ""301"""'));
    expect(lines[1], contains('รอดำเนินการ'));
  });
}
