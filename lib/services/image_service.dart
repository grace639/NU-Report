// ผู้รับผิดชอบ: สมาชิกคนที่ 2 (หน้าจอแจ้งปัญหา)
// ถ่ายรูป/เลือกรูป แล้ว copy มาเก็บในโฟลเดอร์ของแอป
//
// ทำไมต้อง copy: image_picker คืน path ในโฟลเดอร์ cache ซึ่งระบบลบทิ้งได้ทุกเมื่อ
// ถ้าเก็บ path นั้นลง DB ตรงๆ วันหลังรูปอาจหายไป

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageService {
  final _picker = ImagePicker();

  /// คืน path ของรูปที่เก็บถาวรแล้ว หรือ null ถ้าผู้ใช้กดยกเลิก
  Future<String?> pick({required bool fromCamera}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280, // ย่อรูปให้ไฟล์ไม่ใหญ่เกินไป
      imageQuality: 80,
    );
    if (picked == null) return null;
    // เว็บไม่มีโฟลเดอร์ให้ copy ใช้ blob URL ของเบราว์เซอร์ไปเลย (เฉพาะตอนทดสอบบนเว็บ)
    if (kIsWeb) return picked.path;

    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'report_images'));
    await imagesDir.create(recursive: true);

    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final saved = await File(picked.path).copy(p.join(imagesDir.path, fileName));
    return saved.path;
  }
}
