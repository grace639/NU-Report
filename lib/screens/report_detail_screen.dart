// ผู้รับผิดชอบ: สมาชิกคนที่ 3 (ระบบสมาชิก + จัดการเรื่องของแอดมิน) — R3
// รายละเอียด report + ประวัติการดำเนินการ
// แอดมิน: เปลี่ยนสถานะพร้อมบันทึกหมายเหตุ
// ผู้แจ้ง: เปิดหน้านี้แล้วนับว่า "อ่านอัปเดตแล้ว" (R4)

import '../widgets/report_image.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/comment_dao.dart';
import '../db/report_dao.dart';
import '../models/report.dart';
import '../models/report_comment.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/feedback.dart';
import '../widgets/status_chip.dart';

class ReportDetailScreen extends StatefulWidget {
  final int reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _reportDao = ReportDao();
  final _commentDao = CommentDao();
  late Future<(Report?, List<ReportComment>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  // โหลด report กับ comment พร้อมกัน (Future.wait ทำงานขนานกัน)
  Future<(Report?, List<ReportComment>)> _load() async {
    // อ่านจาก context ก่อน await เพราะหลัง await หน้าจออาจถูกปิดไปแล้ว
    final auth = context.read<AuthProvider>();
    final reports = context.read<ReportProvider>();
    final results = await Future.wait([
      _reportDao.findById(widget.reportId),
      _commentDao.listByReport(widget.reportId),
    ]);
    final report = results[0] as Report?;
    // เจ้าของเปิดดู -> ล้างสถานะ "มีอัปเดตใหม่"
    if (report != null && !report.seenByOwner && report.userId == auth.currentUser!.id) {
      await _reportDao.markSeen(report.id!);
      await reports.refreshUnseen(report.userId);
    }
    return (report, results[1] as List<ReportComment>);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _openStatusDialog(Report report) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _StatusDialog(current: report.status),
    );
    if (result == null || !mounted) return;
    final (status, note) = result;
    try {
      await _reportDao.updateStatus(
        reportId: report.id!,
        status: status,
        adminId: context.read<AuthProvider>().currentUser!.id!,
        note: note,
      );
      if (!mounted) return;
      showSuccess(context, 'อัปเดตสถานะแล้ว');
      _reload();
    } catch (e) {
      if (mounted) showError(context, 'อัปเดตไม่สำเร็จ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        final report = snap.data?.$1;
        return Scaffold(
          appBar: AppBar(title: const Text('รายละเอียด')),
          floatingActionButton: isAdmin && report != null
              ? FloatingActionButton.extended(
                  onPressed: () => _openStatusDialog(report),
                  icon: const Icon(Icons.edit),
                  label: const Text('เปลี่ยนสถานะ'),
                )
              : null,
          body: switch (snap) {
            AsyncSnapshot(connectionState: ConnectionState.waiting) =>
              const Center(child: CircularProgressIndicator()),
            AsyncSnapshot(hasError: true) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('โหลดไม่สำเร็จ: ${snap.error}'),
                  OutlinedButton(onPressed: _reload, child: const Text('ลองใหม่')),
                ]),
              ),
            _ when report == null => const Center(child: Text('ไม่พบรายการนี้')),
            _ => _content(report, snap.data!.$2),
          },
        );
      },
    );
  }

  Widget _content(Report r, List<ReportComment> comments) {
    final fmt = DateFormat('d MMM yyyy HH:mm');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (ReportImage.exists(r.imagePath))
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ReportImage(r.imagePath!, height: 220),
          ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text(r.title, style: Theme.of(context).textTheme.titleLarge)),
          StatusChip(r.status),
        ]),
        const SizedBox(height: 8),
        _info(Icons.category, r.categoryName ?? '-'),
        _info(Icons.place, r.location ?? '-'),
        _info(Icons.person, r.username ?? '-'),
        _info(Icons.schedule, 'แจ้งเมื่อ ${fmt.format(r.createdAt)}'),
        const Divider(height: 24),
        Text(r.description),
        const Divider(height: 24),
        Text('ความคืบหน้า', style: Theme.of(context).textTheme.titleMedium),
        if (comments.isEmpty)
          const Padding(padding: EdgeInsets.all(8), child: Text('ยังไม่มีการดำเนินการ')),
        for (final c in comments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.orangeLight,
              child: Icon(Icons.history, color: AppColors.orange),
            ),
            title: Text(c.message),
            subtitle: Text('${c.username} · ${fmt.format(c.createdAt)}'),
          ),
      ],
    );
  }

  Widget _info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}

// Dialog ให้แอดมินเลือกสถานะใหม่ + พิมพ์หมายเหตุ คืนค่า (status, note)
class _StatusDialog extends StatefulWidget {
  final String current;
  const _StatusDialog({required this.current});

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  late String _status = widget.current;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final changed = _status != widget.current;
    return AlertDialog(
      title: const Text('เปลี่ยนสถานะ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<String>(
              groupValue: _status,
              onChanged: (v) => setState(() => _status = v!),
              child: Column(children: [
                for (final s in ReportStatus.all)
                  RadioListTile<String>(value: s, title: Text(ReportStatus.label(s))),
              ]),
            ),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'หมายเหตุถึงผู้แจ้ง'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(80, 40)),
          // ต้องเลือกสถานะที่ต่างจากเดิมก่อนจึงกดบันทึกได้
          onPressed: changed ? () => Navigator.pop(context, (_status, _note.text)) : null,
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}
