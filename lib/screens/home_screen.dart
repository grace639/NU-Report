// ผู้รับผิดชอบ: สมาชิกคนที่ 2 (หน้าจอ)
// หน้าแรกหลังล็อกอิน
// - ผู้ใช้: "เรื่องของฉัน" (R1 R2 R4) + "ประชาสัมพันธ์"
// - แอดมิน: "เรื่องทั้งหมด" (R3) + "ประชาสัมพันธ์" + "สรุปผล" (R5)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'admin/dashboard_screen.dart';
import 'announcements_screen.dart';
import 'create_report_screen.dart';
import 'report_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    // (หน้าจอ, ไอคอน, ชื่อแท็บ)
    final tabs = isAdmin
        ? const [
            (ReportListScreen(adminMode: true), Icons.list_alt, 'เรื่องทั้งหมด'),
            (AnnouncementsScreen(), Icons.campaign, 'ประชาสัมพันธ์'),
            (DashboardScreen(), Icons.bar_chart, 'สรุปผล'),
          ]
        : const [
            (ReportListScreen(adminMode: false), Icons.assignment, 'เรื่องของฉัน'),
            (AnnouncementsScreen(), Icons.campaign, 'ประชาสัมพันธ์'),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'NU Report · แอดมิน' : 'NU Report'),
        actions: [
          Center(child: Text(auth.currentUser?.username ?? '')),
          IconButton(
            tooltip: 'ออกจากระบบ',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      // สร้างเฉพาะแท็บที่เลือก: สลับแท็บแล้วหน้านั้นโหลดข้อมูลใหม่จาก DB เสมอ
      // (ถ้าใช้ IndexedStack หน้าสรุปผลจะค้างข้อมูลเก่าตั้งแต่ตอนล็อกอิน)
      body: tabs[_tab].$1,
      // ปุ่มแจ้งปัญหาแสดงเฉพาะผู้ใช้ในแท็บ "เรื่องของฉัน"
      floatingActionButton: !isAdmin && _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CreateReportScreen())),
              icon: const Icon(Icons.add),
              label: const Text('แจ้งปัญหา'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          for (final (_, icon, label) in tabs)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }
}
