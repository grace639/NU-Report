import 'package:flutter_test/flutter_test.dart';
import 'package:report_app/models/report.dart';
import 'package:report_app/providers/auth_provider.dart';
import 'package:report_app/services/csv_export_service.dart';
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
