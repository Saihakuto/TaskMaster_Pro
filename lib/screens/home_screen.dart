import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/task_provider.dart';
import 'list_screen.dart';
import 'add_edit_screen.dart';
import 'category_screen.dart';
import 'progress_status_screen.dart'; // ✅ เพิ่ม

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskMaster Pro',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedIndex == 1) ...[
            // ✅ ปุ่มจัดการ Progress
            IconButton(
              icon: const Icon(Icons.percent),
              tooltip: 'จัดการป้าย Progress',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProgressStatusScreen())),
            ),
            // ปุ่มจัดการหมวดหมู่
            IconButton(
              icon: const Icon(Icons.label_outline),
              tooltip: 'จัดการหมวดหมู่',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CategoryScreen())),
            ),
            // ปุ่มเรียงตาม
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: provider.setSortBy,
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'due_date', child: Text('เรียงตามวันครบกำหนด')),
                const PopupMenuItem(value: 'created_at', child: Text('เรียงตามวันสร้าง')),
                const PopupMenuItem(value: 'title', child: Text('เรียงตามชื่อ')),
              ],
            ),
          ],
        ],
      ),
      body: _selectedIndex == 0 ? _buildDashboard(provider) : const ListScreen(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddEditScreen())),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มงาน'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'รายการข้อมูล',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(TaskProvider provider) {
    final byCategory = provider.countByCategory;
    final total = provider.totalCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SummaryCard(label: 'ทั้งหมด', count: provider.totalCount, color: const Color(0xFF6C63FF), icon: Icons.task_alt),
              const SizedBox(width: 10),
              _SummaryCard(label: 'เสร็จแล้ว', count: provider.completedCount, color: Colors.green, icon: Icons.check_circle),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryCard(label: 'กำลังทำ', count: provider.inProgressCount, color: Colors.orange, icon: Icons.autorenew),
              const SizedBox(width: 10),
              _SummaryCard(label: 'รอดำเนินการ', count: provider.pendingCount, color: Colors.blueGrey, icon: Icons.radio_button_unchecked),
            ],
          ),
          const SizedBox(height: 24),
          const Text('สัดส่วนสถานะงาน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: total == 0
                ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey))))
                : Row(
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(140, 140),
                              painter: _DonutChartPainter(
                                sections: [
                                  _ChartSection(value: provider.completedCount.toDouble(), color: Colors.green),
                                  _ChartSection(value: provider.inProgressCount.toDouble(), color: Colors.orange),
                                  _ChartSection(value: provider.pendingCount.toDouble(), color: Colors.blueGrey.shade300),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${total == 0 ? 0 : (provider.completedCount / total * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                                const Text('เสร็จแล้ว', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DonutLegend(color: Colors.green, label: 'เสร็จแล้ว', count: provider.completedCount, total: total),
                            const SizedBox(height: 12),
                            _DonutLegend(color: Colors.orange, label: 'กำลังทำ', count: provider.inProgressCount, total: total),
                            const SizedBox(height: 12),
                            _DonutLegend(color: Colors.blueGrey, label: 'รอดำเนินการ', count: provider.pendingCount, total: total),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          const Text('งานตามหมวดหมู่', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: byCategory.isEmpty
                ? const Center(child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey)))
                : Column(
                    children: byCategory.entries.map((e) {
                      final ratio = total == 0 ? 0.0 : e.value / total;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  const Icon(Icons.label, size: 14, color: Color(0xFF6C63FF)),
                                  const SizedBox(width: 6),
                                  Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                ]),
                                Text('${e.value} งาน  (${total == 0 ? 0 : (e.value / total * 100).toStringAsFixed(0)}%)',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Stack(children: [
                              Container(height: 10, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
                              FractionallySizedBox(
                                widthFactor: ratio,
                                child: Container(height: 10, decoration: BoxDecoration(color: const Color(0xFF6C63FF), borderRadius: BorderRadius.circular(8))),
                              ),
                            ]),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 24),
          _OverdueSection(provider: provider),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ChartSection {
  final double value;
  final Color color;
  const _ChartSection({required this.value, required this.color});
}

class _DonutChartPainter extends CustomPainter {
  final List<_ChartSection> sections;
  const _DonutChartPainter({required this.sections});

  @override
  void paint(Canvas canvas, Size size) {
    final total = sections.fold(0.0, (sum, s) => sum + s.value);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 22.0;
    double startAngle = -math.pi / 2;
    for (final section in sections) {
      if (section.value == 0) continue;
      final sweepAngle = (section.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = section.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle, sweepAngle - 0.03, false, paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  const _DonutLegend({required this.color, required this.label, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count / total * 100).toStringAsFixed(0);
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text('$count  ($pct%)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _SummaryCard({required this.label, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count.toString(), style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverdueSection extends StatelessWidget {
  final TaskProvider provider;
  const _OverdueSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final overdue = provider.tasks.where((t) =>
        t.status != 'completed' && t.dueDate.isBefore(DateTime.now())).toList();
    if (overdue.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text('เกินกำหนด (${overdue.length} งาน)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        ...overdue.map((t) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.red, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  Text('${DateTime.now().difference(t.dueDate).inDays} วันที่แล้ว',
                      style: const TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
            )),
      ],
    );
  }
}