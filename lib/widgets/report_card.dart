// ผู้รับผิดชอบ: สมาชิกคนที่ 2
// การ์ดแสดง report 1 รายการ ใช้ในหน้ารายการของผู้ใช้และแอดมิน

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/report.dart';
import '../theme/app_theme.dart';
import 'report_image.dart';
import 'status_chip.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final bool showOwner;
  final VoidCallback onTap;

  const ReportCard({super.key, required this.report, required this.onTap, this.showOwner = false});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy HH:mm').format(report.updatedAt);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(10),
        leading: _thumbnail(),
        title: Row(
          children: [
            Expanded(
              child: Text(report.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            // จุดสีแสด = มีอัปเดตที่ยังไม่ได้เปิดดู (R4)
            if (!report.seenByOwner && !showOwner)
              const Icon(Icons.circle, size: 10, color: AppColors.orange),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${report.categoryName ?? ''} · $date${showOwner ? ' · ${report.username}' : ''}'),
            const SizedBox(height: 6),
            StatusChip(report.status),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final path = report.imagePath;
    if (ReportImage.exists(path)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ReportImage(path!, width: 56, height: 56),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.report_outlined, color: AppColors.orange),
    );
  }
}
