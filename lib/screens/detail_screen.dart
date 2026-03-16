import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'add_edit_screen.dart';

class DetailScreen extends StatelessWidget {
  final Task task;
  const DetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();
    final categoryName = provider.getCategoryName(task.categoryId);

    Color statusColor;
    String statusLabel;
    switch (task.status) {
      case 'completed': statusColor = Colors.green; statusLabel = 'เสร็จแล้ว'; break;
      case 'in_progress': statusColor = Colors.orange; statusLabel = 'กำลังทำ'; break;
      default: statusColor = Colors.blueGrey; statusLabel = 'รอดำเนินการ';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดงาน'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => AddEditScreen(task: task))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('ยืนยันการลบ'),
                  content: Text('ต้องการลบ "${task.title}" ใช่หรือไม่?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('ลบ', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await provider.deleteTask(task.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ลบ "${task.title}" แล้ว'), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            _InfoRow(icon: Icons.folder_outlined, label: 'หมวดหมู่', value: categoryName),
            const Divider(),
            _InfoRow(icon: Icons.calendar_today, label: 'วันครบกำหนด', value: DateFormat('d MMMM yyyy').format(task.dueDate)),
            const Divider(),
            _InfoRow(icon: Icons.access_time, label: 'วันที่สร้าง', value: DateFormat('d MMM yyyy HH:mm').format(task.createdAt)),
            const Divider(),
            const SizedBox(height: 16),
            const Text('รายละเอียด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(task.description.isEmpty ? 'ไม่มีรายละเอียด' : task.description,
                  style: const TextStyle(fontSize: 15, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      );
}