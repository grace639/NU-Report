// ผู้รับผิดชอบ: สมาชิกคนที่ 2 (ประชาสัมพันธ์)
// หน้าข่าวประชาสัมพันธ์
// - ทุกคน: อ่านประกาศ (ปักหมุดอยู่บนสุด)
// - แอดมิน: เพิ่มประกาศ, ปักหมุด/เลิกปักหมุด, ลบ

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/announcement_dao.dart';
import '../models/announcement.dart';
import '../providers/auth_provider.dart';
import '../services/link_guard.dart';
import '../theme/app_theme.dart';
import '../widgets/feedback.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _dao = AnnouncementDao();
  late Future<List<Announcement>> _future;

  @override
  void initState() {
    super.initState();
    _future = _dao.listAll();
  }

  Future<void> _reload() async {
    setState(() => _future = _dao.listAll());
    await _future;
  }

  // ครอบงานแก้ไขข้อมูล: สำเร็จ -> โหลดใหม่, ล้มเหลว -> แจ้ง error
  Future<void> _run(Future<void> Function() task, String successMsg) async {
    try {
      await task();
      if (!mounted) return;
      showSuccess(context, successMsg);
      _reload();
    } catch (e) {
      if (mounted) showError(context, 'ทำรายการไม่สำเร็จ: $e');
    }
  }

  Future<void> _create() async {
    final result = await showDialog<(String, String, bool)>(
      context: context,
      builder: (_) => const _AnnouncementDialog(),
    );
    if (result == null || !mounted) return;
    final (title, body, pinned) = result;
    final adminId = context.read<AuthProvider>().currentUser!.id!;
    await _run(
      () => _dao.insert(Announcement(adminId: adminId, title: title, body: body, pinned: pinned)),
      'เผยแพร่ประกาศแล้ว',
    );
  }

  Future<void> _confirmDelete(Announcement a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบประกาศ?'),
        content: Text('"${a.title}" จะถูกลบถาวร'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) await _run(() => _dao.delete(a.id!), 'ลบประกาศแล้ว');
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'announce', // กัน hero ชนกับ FAB ของหน้าอื่น
              onPressed: _create,
              icon: const Icon(Icons.campaign),
              label: const Text('ประกาศใหม่'),
            )
          : null,
      body: FutureBuilder(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('โหลดไม่สำเร็จ: ${snap.error}'),
                OutlinedButton(onPressed: _reload, child: const Text('ลองใหม่')),
              ]),
            );
          }
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('ยังไม่มีประกาศ'));
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: items.length,
              itemBuilder: (_, i) => _card(items[i], isAdmin),
            ),
          );
        },
      ),
    );
  }

  Widget _card(Announcement a, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: a.pinned ? const BorderSide(color: AppColors.orange, width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (a.pinned) ...[
                const Icon(Icons.push_pin, size: 18, color: AppColors.orange),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(a.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              if (isAdmin)
                PopupMenuButton<String>(
                  onSelected: (v) => v == 'pin'
                      ? _run(() => _dao.setPinned(a.id!, !a.pinned),
                          a.pinned ? 'เลิกปักหมุดแล้ว' : 'ปักหมุดแล้ว')
                      : _confirmDelete(a),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'pin', child: Text(a.pinned ? 'เลิกปักหมุด' : 'ปักหมุด')),
                    const PopupMenuItem(value: 'delete', child: Text('ลบ')),
                  ],
                )
              else
                const SizedBox(height: 40),
            ]),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(a.body),
            ),
            const SizedBox(height: 8),
            Text(
              '${a.adminName ?? 'เจ้าหน้าที่'} · ${DateFormat('d MMM yyyy HH:mm').format(a.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ฟอร์มสร้างประกาศ คืนค่า (หัวข้อ, เนื้อหา, ปักหมุด)
class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog();

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _pinned = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ประกาศใหม่'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _title,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'หัวข้อ *'),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'กรุณากรอกหัวข้อ'
                  : LinkGuard.onlyTrustedLinks(v),
            ),
            TextFormField(
              controller: _body,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'เนื้อหา *',
                alignLabelWithHint: true,
                helperText: 'ใส่ลิงก์ได้เฉพาะเว็บ nu.ac.th',
              ),
              // แอดมินใส่ลิงก์ได้ แต่ต้องเป็นเว็บของมหาวิทยาลัยเท่านั้น (LinkGuard)
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'กรุณากรอกเนื้อหา'
                  : LinkGuard.onlyTrustedLinks(v),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _pinned,
              onChanged: (v) => setState(() => _pinned = v!),
              title: const Text('ปักหมุดไว้บนสุด'),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(80, 40)),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, (_title.text.trim(), _body.text.trim(), _pinned));
          },
          child: const Text('เผยแพร่'),
        ),
      ],
    );
  }
}
