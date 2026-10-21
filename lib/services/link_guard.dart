// ผู้รับผิดชอบ: สมาชิกคนที่ 1
// ป้องกันลิงก์แปลกปลอม (ตามที่ผู้ใช้ขอในการพบครั้งที่ 1)
//
// กติกา:
// - เรื่องแจ้งปัญหา (ผู้ใช้ทั่วไปเขียน): ห้ามมีลิงก์เลย กันคนแนบลิงก์หลอกลวงให้เจ้าหน้าที่กด
// - ประกาศ (แอดมินเขียน): มีลิงก์ได้เฉพาะโดเมนของมหาวิทยาลัย nu.ac.th

class LinkGuard {
  // จับได้ 3 แบบ:
  //   1. มี http:// หรือ https://       เช่น https://evil.com/login
  //   2. ขึ้นต้นด้วย www.               เช่น www.evil.com
  //   3. ชื่อโดเมนลอยๆ ที่ลงท้ายด้วยนามสกุลเว็บ เช่น bit.ly/abc, free-gift.xyz
  // ใช้ [a-z0-9] จึงไม่ชนกับข้อความไทยที่มีจุด เช่น "ส. 25 ต.ค."
  static final _urlPattern = RegExp(
    r'(https?://[^\s]+)'
    r'|(www\.[^\s]+)'
    r'|(\b[a-z0-9-]+(\.[a-z0-9-]+)*\.(com|net|org|info|biz|xyz|top|site|online|shop|click|link|app|io|co|me|ly|gl|cc|tk|ml|ga|cf|gq|th)\b(/[^\s]*)?)',
    caseSensitive: false,
  );

  static const trustedDomain = 'nu.ac.th';

  /// คืนรายการลิงก์ทั้งหมดที่พบในข้อความ
  static List<String> findLinks(String text) =>
      _urlPattern.allMatches(text).map((m) => m.group(0)!).toList();

  /// ดึงชื่อโดเมนจากลิงก์ เช่น "https://www.nu.ac.th/news?id=1" -> "www.nu.ac.th"
  static String hostOf(String link) {
    var s = link.toLowerCase().replaceFirst(RegExp(r'^https?://'), '');
    s = s.split(RegExp(r'[/?#:]')).first;
    return s;
  }

  /// เป็นโดเมนของมหาวิทยาลัยหรือไม่ (nu.ac.th หรือโดเมนย่อย เช่น www.nu.ac.th)
  /// เช็กด้วย endsWith('.nu.ac.th') ไม่ใช่ contains('nu.ac.th')
  /// เพราะเว็บปลอมอย่าง nu.ac.th.evil.com ก็มีคำว่า nu.ac.th อยู่ข้างใน
  static bool isTrusted(String link) {
    final host = hostOf(link);
    return host == trustedDomain || host.endsWith('.$trustedDomain');
  }

  /// validator สำหรับช่องในฟอร์มแจ้งปัญหา: ห้ามมีลิงก์ทุกชนิด
  static String? noLinks(String? value) {
    if (value == null || findLinks(value).isEmpty) return null;
    return 'ห้ามใส่ลิงก์ (ป้องกันลิงก์หลอกลวง)';
  }

  /// validator สำหรับประกาศ: อนุญาตเฉพาะลิงก์ nu.ac.th
  static String? onlyTrustedLinks(String? value) {
    if (value == null) return null;
    final bad = findLinks(value).where((l) => !isTrusted(l)).toList();
    if (bad.isEmpty) return null;
    return 'ลิงก์ที่ไม่ใช่ $trustedDomain ไม่อนุญาต: ${bad.first}';
  }
}
