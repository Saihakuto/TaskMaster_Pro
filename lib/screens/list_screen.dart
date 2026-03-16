import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final Set<int> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _cancelSelect() => setState(() => _selectedIds.clear());

  Future<void> _deleteSelected(TaskProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ ${_selectedIds.length} รายการที่เลือกใช่หรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบทั้งหมด', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (final id in _selectedIds.toList()) {
        await provider.deleteTask(id);
      }
      setState(() => _selectedIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบรายการที่เลือกแล้ว ✓'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ✅ Bottom Sheet กรองสถานะ
  void _showFilterSheet(TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('กรองตามสถานะ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Divider(),
            _FilterOption(label: 'ทั้งหมด', value: 'all', icon: Icons.list_alt, color: const Color(0xFF6C63FF), provider: provider),
            _FilterOption(label: 'รอดำเนินการ', value: 'pending', icon: Icons.radio_button_unchecked, color: Colors.blueGrey, provider: provider),
            _FilterOption(label: 'กำลังทำ', value: 'in_progress', icon: Icons.autorenew, color: Colors.orange, provider: provider),
            _FilterOption(label: 'เสร็จแล้ว', value: 'completed', icon: Icons.check_circle_outline, color: Colors.green, provider: provider),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = provider.tasks;

    // label สถานะที่เลือกอยู่
    final filterLabels = {
      'all': 'ทั้งหมด',
      'pending': 'รอดำเนินการ',
      'in_progress': 'กำลังทำ',
      'completed': 'เสร็จแล้ว',
    };
    final filterColors = {
      'all': const Color(0xFF6C63FF),
      'pending': Colors.blueGrey,
      'in_progress': Colors.orange,
      'completed': Colors.green,
    };
    final currentColor = filterColors[provider.filterStatus] ?? const Color(0xFF6C63FF);

    return Column(
      children: [
        // bar เลือกหลายอัน
        if (_isSelecting)
          Container(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('เลือก ${_selectedIds.length} รายการ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == tasks.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(tasks.map((t) => t.id!));
                      }
                    });
                  },
                  child: Text(_selectedIds.length == tasks.length ? 'ยกเลิกทั้งหมด' : 'เลือกทั้งหมด'),
                ),
                TextButton(
                    onPressed: _cancelSelect,
                    child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSelected(provider),
                ),
              ],
            ),
          ),

        // Search Bar
        if (!_isSelecting)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: provider.setSearch,
              decoration: InputDecoration(
                hintText: 'ค้นหางาน...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

        // ✅ ปุ่มกรองอันเดียว กดแล้วขึ้น Bottom Sheet
        if (!_isSelecting)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _showFilterSheet(provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: currentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: currentColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list, size: 18, color: currentColor),
                    const SizedBox(width: 8),
                    Text(
                      'สถานะ: ${filterLabels[provider.filterStatus]}',
                      style: TextStyle(color: currentColor, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down, size: 18, color: currentColor),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Task List
        Expanded(
          child: tasks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('ไม่พบรายการงาน', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) {
                    final task = tasks[i];
                    return TaskCard(
                      task: task,
                      categoryName: provider.getCategoryName(task.categoryId),
                      isSelecting: _isSelecting,
                      isSelected: _selectedIds.contains(task.id),
                      onLongPress: () => _toggleSelect(task.id!),
                      onSelect: () => _toggleSelect(task.id!),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => DetailScreen(task: task))),
                      onDelete: () {
                        provider.deleteTask(task.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('ลบ "${task.title}" แล้ว'),
                            backgroundColor: Colors.red.shade400,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onStatusChange: (newStatus) {
                        provider.updateTask(task.copyWith(status: newStatus));
                        final labels = {
                          'pending': 'รอดำเนินการ',
                          'in_progress': 'กำลังทำ',
                          'completed': 'เสร็จแล้ว',
                        };
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('เปลี่ยนเป็น "${labels[newStatus]}" แล้ว ✓'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ✅ ตัวเลือกใน Bottom Sheet
class _FilterOption extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final TaskProvider provider;

  const _FilterOption({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = provider.filterStatus == value;
    return InkWell(
      onTap: () {
        provider.setFilter(value);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : Colors.black87)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}