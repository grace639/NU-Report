// ผู้รับผิดชอบ: สมาชิกคนที่ 4 (สรุปผล) — R5
// สรุปจำนวนเรื่องตามสถานะ (กราฟวงกลม) และตามหมวดหมู่ (กราฟแท่ง) รายเดือน
// พร้อมปุ่มส่งออก CSV

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db/report_dao.dart';
import '../../models/report.dart';
import '../../services/csv_export_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feedback.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dao = ReportDao();
  final _csv = CsvExportService();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<(Map<String, int>, Map<String, int>)> _future;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Map<String, int>, Map<String, int>)> _load() async {
    final from = _month;
    final to = DateTime(_month.year, _month.month + 1);
    final byStatus = await _dao.countByStatus(from: from, to: to);
    final byCategory = await _dao.countByCategory(from: from, to: to);
    return (byStatus, byCategory);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _future = _load();
    });
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await _csv.exportMonth(_month);
    } catch (e) {
      if (mounted) showError(context, 'ส่งออกไม่สำเร็จ: $e', onRetry: _export);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = _load());
        await _future;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Text(DateFormat('MMMM yyyy').format(_month),
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
          ]),
          FutureBuilder(
            future: _future,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                    padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) return Text('โหลดไม่สำเร็จ: ${snap.error}');
              final (byStatus, byCategory) = snap.data!;
              final total = byStatus.values.fold(0, (a, b) => a + b);
              if (total == 0) {
                return const Padding(
                    padding: EdgeInsets.all(40), child: Center(child: Text('ไม่มีข้อมูลในเดือนนี้')));
              }
              return Column(children: [
                _card('ทั้งหมด $total เรื่อง · แยกตามสถานะ', _pie(byStatus, total)),
                _card('แยกตามหมวดหมู่', _bar(byCategory)),
              ]);
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _exporting ? null : _export,
            icon: const Icon(Icons.download),
            label: Text(_exporting ? 'กำลังสร้างไฟล์...' : 'ส่งออก CSV เดือนนี้'),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, Widget child) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            child,
          ]),
        ),
      );

  Widget _pie(Map<String, int> data, int total) {
    return Row(children: [
      SizedBox(
        width: 140,
        height: 140,
        child: PieChart(PieChartData(
          centerSpaceRadius: 30,
          sections: [
            for (final e in data.entries)
              PieChartSectionData(
                value: e.value.toDouble(),
                color: AppColors.status(e.key),
                title: '${(e.value * 100 / total).round()}%',
                radius: 40,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        )),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final e in data.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 12, height: 12, color: AppColors.status(e.key)),
                const SizedBox(width: 8),
                Expanded(child: Text(ReportStatus.label(e.key))),
                Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
        ]),
      ),
    ]);
  }

  Widget _bar(Map<String, int> data) {
    final entries = data.entries.toList();
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 200,
      child: BarChart(BarChartData(
        maxY: maxY + 1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(entries[v.toInt()].key, style: const TextStyle(fontSize: 10)),
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: entries[i].value.toDouble(),
                color: i.isEven ? AppColors.orange : AppColors.grey,
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      )),
    );
  }
}
