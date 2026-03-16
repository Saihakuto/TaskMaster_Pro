import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final String categoryName;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onLongPress;
  final VoidCallback onSelect;
  final Function(String) onStatusChange;

  const TaskCard({
    super.key,
    required this.task,
    required this.categoryName,
    required this.onTap,
    required this.onDelete,
    this.isSelecting = false,
    this.isSelected = false,
    required this.onLongPress,
    required this.onSelect,
    required this.onStatusChange,
  });

  Color _progressColor(int progress) {
    if (progress >= 100) return Colors.green;
    if (progress >= 50) return Colors.orange;
    return const Color(0xFF6C63FF);
  }

  bool get _isOverdue =>
      task.status != 'completed' && task.dueDate.isBefore(DateTime.now());

  void _showStatusSheet(BuildContext context) {
    final provider = context.read<TaskProvider>();
    final configs = provider.statusConfigs;

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
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('เปลี่ยนสถานะงาน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(task.title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            const Divider(height: 1),
            // ✅ แสดงทุก statusConfigs
            ...configs.map((sc) => _StatusOption(
              label: sc.label,
              icon: provider.getStatusIcon(sc.keyName),
              color: sc.color,
              isSelected: task.status == sc.keyName,
              onTap: () {
                Navigator.pop(context);
                onStatusChange(sc.keyName);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final statusColor = provider.getStatusColor(task.status);
    final statusLabel = provider.getStatusLabel(task.status);

    return Dismissible(
      key: Key('task_${task.id}'),
      direction: isSelecting ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
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
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isSelected ? 4 : 2,
        color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.08) : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isSelecting ? onSelect : onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: isSelecting
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => onSelect(),
                          activeColor: const Color(0xFF6C63FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        )
                      : CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.15),
                          child: Icon(provider.getStatusIcon(task.status), color: statusColor, size: 22),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: task.status == 'completed' ? TextDecoration.lineThrough : null,
                          color: task.status == 'completed' ? Colors.grey : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.folder_outlined, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(categoryName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_today, size: 13, color: _isOverdue ? Colors.red : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM yy').format(task.dueDate),
                            style: TextStyle(fontSize: 12, color: _isOverdue ? Colors.red : Colors.grey, fontWeight: _isOverdue ? FontWeight.bold : null),
                          ),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(task.description, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: task.progress / 100,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(_progressColor(task.progress)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${task.progress}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _progressColor(task.progress))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!isSelecting)
                  GestureDetector(
                    onTap: () => _showStatusSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_up, size: 13, color: statusColor),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({required this.label, required this.icon, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.black87)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}