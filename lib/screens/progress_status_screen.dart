import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class ProgressStatusScreen extends StatefulWidget {
  const ProgressStatusScreen({super.key});
  @override
  State<ProgressStatusScreen> createState() => _ProgressStatusScreenState();
}

class _ProgressStatusScreenState extends State<ProgressStatusScreen> {
  final Set<int> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  // สีให้เลือก
  static const List<Color> _colorOptions = [
    Color(0xFF607D8B), // blueGrey
    Color(0xFFFF9800), // orange
    Color(0xFF4CAF50), // green
    Color(0xFF2196F3), // blue
    Color(0xFFE91E63), // pink
    Color(0xFF9C27B0), // purple
    Color(0xFFFF5722), // deepOrange
    Color(0xFF009688), // teal
    Color(0xFF6C63FF), // indigo
    Color(0xFFF44336), // red
  ];

  // 3 key หลักที่ลบไม่ได้
  static const _coreKeys = ['pending', 'in_progress', 'completed'];

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

  Future<void> _deleteSelected(List<StatusConfig> statuses) async {
    final provider = context.read<TaskProvider>();
    // กรองออกเฉพาะที่ไม่ใช่ core
    final deletable = _selectedIds.where((id) {
      final sc = statuses.firstWhere((s) => s.id == id);
      return !_coreKeys.contains(sc.keyName);
    }).toList();

    if (deletable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถลบสถานะหลักได้ (pending/in_progress/completed)'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _selectedIds.clear());
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ ${deletable.length} สถานะที่เลือกใช่หรือไม่?'),
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
    if (confirm == true) {
      for (final id in deletable) {
        await provider.deleteStatusConfig(id);
      }
      setState(() => _selectedIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบสถานะแล้ว ✓'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showAddEditDialog({StatusConfig? existing}) {
    final nameCtrl = TextEditingController(text: existing?.label ?? '');
    final keyCtrl = TextEditingController(text: existing?.keyName ?? '');
    int selectedColor = existing?.colorValue ?? _colorOptions[0].value;
    final isCore = existing != null && _coreKeys.contains(existing.keyName);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'เพิ่มสถานะใหม่' : 'แก้ไขสถานะ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่อแสดงผล
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'ชื่อสถานะ *',
                    hintText: 'เช่น งานด่วน',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                // key (ซ่อนถ้าเป็น core)
                if (!isCore)
                  TextField(
                    controller: keyCtrl,
                    decoration: InputDecoration(
                      labelText: 'Key (ภาษาอังกฤษ ไม่มีช่องว่าง)',
                      hintText: 'เช่น urgent',
                      prefixIcon: const Icon(Icons.key),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                if (!isCore) const SizedBox(height: 12),
                // เลือกสี
                const Text('เลือกสี', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorOptions.map((c) {
                    final isSelected = c.value == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c.value),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Preview
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(selectedColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(selectedColor).withOpacity(0.4)),
                  ),
                  child: Text(
                    nameCtrl.text.isEmpty ? 'ตัวอย่าง' : nameCtrl.text,
                    style: TextStyle(color: Color(selectedColor), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final label = nameCtrl.text.trim();
                if (label.isEmpty) return;
                final key = isCore
                    ? existing.keyName
                    : (keyCtrl.text.trim().isEmpty
                        ? label.toLowerCase().replaceAll(' ', '_')
                        : keyCtrl.text.trim().replaceAll(' ', '_'));
                final provider = context.read<TaskProvider>();
                final sc = StatusConfig(
                  id: existing?.id,
                  keyName: key,
                  label: label,
                  colorValue: selectedColor,
                );
                if (existing == null) {
                  await provider.addStatusConfig(sc);
                } else {
                  await provider.updateStatusConfig(sc);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(existing == null ? 'เพิ่มสถานะ "$label" แล้ว ✓' : 'แก้ไขสถานะ "$label" แล้ว ✓'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(existing == null ? 'เพิ่ม' : 'บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = context.watch<TaskProvider>().statusConfigs;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelecting ? 'เลือก ${_selectedIds.length} รายการ' : 'จัดการสถานะ'),
        backgroundColor: _isSelecting ? Colors.red.shade400 : const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          if (_isSelecting) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == statuses.length) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds.addAll(statuses.map((s) => s.id!));
                  }
                });
              },
              child: Text(
                _selectedIds.length == statuses.length ? 'ยกเลิกทั้งหมด' : 'เลือกทั้งหมด',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteSelected(statuses)),
            IconButton(icon: const Icon(Icons.close), onPressed: _cancelSelect),
          ],
        ],
      ),
      floatingActionButton: _isSelecting
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มสถานะ'),
            ),
      body: statuses.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('ยังไม่มีสถานะ', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.grey.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text(
                        _isSelecting ? 'กดถังขยะเพื่อลบ (สถานะหลักลบไม่ได้)' : 'กดค้างเลือกลบ • กดแก้ไข',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: statuses.length,
                    itemBuilder: (_, i) {
                      final sc = statuses[i];
                      final isSelected = _selectedIds.contains(sc.id);
                      final isCore = _coreKeys.contains(sc.keyName);
                      return GestureDetector(
                        onLongPress: () => _toggleSelect(sc.id!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.red.withOpacity(0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.red.shade300 : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isSelecting
                                ? () => _toggleSelect(sc.id!)
                                : () => _showAddEditDialog(existing: sc),
                            onLongPress: () => _toggleSelect(sc.id!),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  _isSelecting
                                      ? Checkbox(
                                          value: isSelected,
                                          onChanged: (_) => _toggleSelect(sc.id!),
                                          activeColor: Colors.red,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        )
                                      : CircleAvatar(
                                          backgroundColor: sc.color.withOpacity(0.15),
                                          child: Icon(Icons.label, color: sc.color, size: 20),
                                        ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(sc.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            if (isCore) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text('หลัก', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(sc.keyName, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                  // badge preview
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: sc.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: sc.color.withOpacity(0.4)),
                                    ),
                                    child: Text(sc.label, style: TextStyle(fontSize: 11, color: sc.color, fontWeight: FontWeight.w600)),
                                  ),
                                  if (!_isSelecting) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade400),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}