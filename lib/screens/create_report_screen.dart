// ผู้รับผิดชอบ: สมาชิกคนที่ 2 (หน้าจอแจ้งปัญหา) — R1
// ฟอร์มแจ้งปัญหา: หัวข้อ หมวดหมู่ สถานที่ รายละเอียด รูปภาพ

import '../widgets/report_image.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/report.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/feedback.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _imageService = ImageService();

  int? _categoryId;
  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    context.read<ReportProvider>().loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    try {
      final path = await _imageService.pick(fromCamera: fromCamera);
      if (path != null) setState(() => _imagePath = path);
    } catch (e) {
      // เช่น ผู้ใช้ไม่อนุญาตกล้อง หรือ emulator ไม่มีกล้อง
      if (mounted) showError(context, 'เปิดกล้อง/คลังรูปไม่ได้: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('ถ่ายรูป'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('เลือกจากคลังรูป'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(false);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().currentUser!;
    setState(() => _saving = true);
    try {
      await context.read<ReportProvider>().add(Report(
            userId: user.id!,
            categoryId: _categoryId!,
            title: _title.text.trim(),
            description: _description.text.trim(),
            location: _location.text.trim(),
            imagePath: _imagePath,
          ));
      if (!mounted) return;
      showSuccess(context, 'ส่งเรื่องเรียบร้อย');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, 'บันทึกไม่สำเร็จ: $e', onRetry: _submit);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ReportProvider>().categories;
    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งปัญหา')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _imageBox(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'หัวข้อ *'),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'กรุณากรอกหัวข้อ' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'หมวดหมู่ *'),
              items: [for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? 'กรุณาเลือกหมวดหมู่' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'สถานที่ *',
                hintText: 'เช่น อาคาร SC2 ชั้น 3 ห้อง 301',
                prefixIcon: Icon(Icons.place),
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'กรุณาระบุสถานที่' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'รายละเอียด *', alignLabelWithHint: true),
              validator: (v) =>
                  (v?.trim().length ?? 0) < 10 ? 'อธิบายอย่างน้อย 10 ตัวอักษร' : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(_saving ? 'กำลังบันทึก...' : 'ส่งเรื่อง'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageBox() {
    return InkWell(
      onTap: _showImageSourceSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.orangeLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.orange),
        ),
        clipBehavior: Clip.antiAlias,
        child: _imagePath == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: AppColors.orange),
                  SizedBox(height: 8),
                  Text('แตะเพื่อแนบรูป (ไม่บังคับ)'),
                ],
              )
            : Stack(fit: StackFit.expand, children: [
                ReportImage(_imagePath!),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _imagePath = null),
                  ),
                ),
              ]),
      ),
    );
  }
}
