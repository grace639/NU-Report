// ผู้รับผิดชอบ: สมาชิกคนที่ 4 (การแจ้งอัปเดต + สรุปผล) — R4
// แถบสีแสดบนหน้าแรก บอกจำนวนเรื่องที่แอดมินอัปเดตแล้วแต่ผู้แจ้งยังไม่ได้เปิดดู
// ข้อมูลมาจากคอลัมน์ reports.seen_by_owner:
//   แอดมินเปลี่ยนสถานะ -> 0, ผู้แจ้งเปิดหน้ารายละเอียด -> 1

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class UpdateBanner extends StatelessWidget {
  final int count;
  const UpdateBanner({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    // ไม่มีเรื่องใหม่ = ไม่แสดงอะไรเลย
    if (count == 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'มี $count เรื่องที่มีความคืบหน้าใหม่ (จุดสีแสดในรายการ)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
