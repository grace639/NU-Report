// ผู้รับผิดชอบ: สมาชิกคนที่ 1 (ฐานข้อมูล + ค้นหา) — R2
// รายการ report + ช่องค้นหา + กรองตามสถานะ/หมวดหมู่
// adminMode = true เห็นทุกคน, false เห็นเฉพาะของตัวเอง

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/report.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/report_card.dart';
import '../widgets/update_banner.dart';
import 'report_detail_screen.dart';

class ReportListScreen extends StatefulWidget {
  final bool adminMode;
  const ReportListScreen({super.key, required this.adminMode});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  int? get _userId =>
      widget.adminMode ? null : context.read<AuthProvider>().currentUser!.id;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ReportProvider>();
    provider.clearFilters();
    provider.loadCategories();
    // เรียกหลัง build เฟรมแรก เพราะ load() จะ notifyListeners ระหว่าง build ไม่ได้
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() => context.read<ReportProvider>().load(userId: _userId);

  // debounce: รอให้หยุดพิมพ์ 400ms ค่อยค้น ไม่ query ทุกตัวอักษร
  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<ReportProvider>().keyword = text;
      _reload();
    });
  }

  Future<void> _openDetail(Report r) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => ReportDetailScreen(reportId: r.id!)));
    if (mounted) _reload(); // กลับมาแล้วโหลดใหม่ เผื่อสถานะเปลี่ยน
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    return Column(
      children: [
        if (!widget.adminMode) UpdateBanner(count: provider.unseenCount),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'ค้นหาหัวข้อ รายละเอียด หรือสถานที่',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        _onSearchChanged('');
                      },
                    ),
            ),
          ),
        ),
        _filterBar(provider),
        Expanded(child: _body(provider)),
      ],
    );
  }

  Widget _filterBar(ReportProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final s in [null, ...ReportStatus.all])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(s == null ? 'ทั้งหมด' : ReportStatus.label(s)),
                selected: provider.statusFilter == s,
                selectedColor: AppColors.orangeLight,
                onSelected: (_) {
                  provider.statusFilter = s;
                  _reload();
                },
              ),
            ),
          const SizedBox(width: 6),
          DropdownButton<int?>(
            value: provider.categoryFilter,
            hint: const Text('ทุกหมวด'),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: null, child: Text('ทุกหมวด')),
              for (final c in provider.categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) {
              provider.categoryFilter = v;
              _reload();
            },
          ),
        ],
      ),
    );
  }

  Widget _body(ReportProvider provider) {
    if (provider.loading && provider.reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(provider.error!, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _reload, child: const Text('ลองใหม่')),
        ]),
      );
    }
    if (provider.reports.isEmpty) {
      return const Center(child: Text('ไม่พบรายการ'));
    }
    return RefreshIndicator(
      onRefresh: _reload, // ดึงลงเพื่อโหลดใหม่
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: provider.reports.length,
        itemBuilder: (_, i) => ReportCard(
          report: provider.reports[i],
          showOwner: widget.adminMode,
          onTap: () => _openDetail(provider.reports[i]),
        ),
      ),
    );
  }
}
