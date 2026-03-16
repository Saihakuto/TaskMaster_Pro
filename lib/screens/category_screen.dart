import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/database_service.dart';
import '../models/task.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _ctrl = TextEditingController();
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

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ ${_selectedIds.length} หมวดหมู่ที่เลือกใช่หรือไม่?'),
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
        await DatabaseService.instance.deleteCategory(id);
      }
      await context.read<TaskProvider>().loadTasks();
      setState(() => _selectedIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบหมวดหมู่ที่เลือกแล้ว ✓'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addCategory() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    await DatabaseService.instance.insertCategory(Category(name: name));
    await context.read<TaskProvider>().loadTasks();
    _ctrl.clear();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เพิ่มหมวดหมู่ "$name" แล้ว ✓'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('เพิ่มหมวดหมู่ใหม่'),
        content: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'ชื่อหมวดหมู่',
            prefixIcon: const Icon(Icons.label_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _addCategory(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            onPressed: _addCategory,
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<TaskProvider>().categories;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelecting
            ? 'เลือก ${_selectedIds.length} รายการ'
            : 'จัดการหมวดหมู่'),
        backgroundColor: _isSelecting
            ? Colors.red.shade400
            : const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          if (_isSelecting) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == categories.length) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds.addAll(categories.map((c) => c.id!));
                  }
                });
              },
              child: Text(
                _selectedIds.length == categories.length
                    ? 'ยกเลิกทั้งหมด'
                    : 'เลือกทั้งหมด',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
              tooltip: 'ลบที่เลือก',
            ),
          ],
          if (_isSelecting)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelSelect,
              tooltip: 'ยกเลิก',
            ),
        ],
      ),
      floatingActionButton: _isSelecting
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มหมวดหมู่'),
            ),
      body: categories.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('ยังไม่มีหมวดหมู่',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                // hint bar
                if (!_isSelecting)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: Colors.grey.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(
                          'กดค้างที่หมวดหมู่เพื่อเลือกลบ',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final isSelected = _selectedIds.contains(cat.id);
                      return GestureDetector(
                        onLongPress: () => _toggleSelect(cat.id!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.red.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.red.shade300
                                  : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isSelecting
                                ? () => _toggleSelect(cat.id!)
                                : null,
                            onLongPress: () => _toggleSelect(cat.id!),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  _isSelecting
                                      ? Checkbox(
                                          value: isSelected,
                                          onChanged: (_) =>
                                              _toggleSelect(cat.id!),
                                          activeColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                        )
                                      : CircleAvatar(
                                          backgroundColor: const Color(
                                                  0xFF6C63FF)
                                              .withOpacity(0.1),
                                          child: const Icon(Icons.label,
                                              color: Color(0xFF6C63FF)),
                                        ),
                                  const SizedBox(width: 12),
                                  Text(
                                    cat.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
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