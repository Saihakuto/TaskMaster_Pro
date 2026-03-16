import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class AddEditScreen extends StatefulWidget {
  final Task? task;
  const AddEditScreen({super.key, this.task});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _progressCtrl;
  late DateTime _dueDate;
  late String _status;
  late int _progress;
  int? _categoryId;
  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _status = widget.task?.status ?? 'pending';
    _progress = widget.task?.progress ?? 0;
    _progressCtrl = TextEditingController(text: _progress.toString());
    _categoryId = widget.task?.categoryId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TaskProvider>();
    final task = Task(
      id: widget.task?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      categoryId: _categoryId!,
      dueDate: _dueDate,
      status: _status,
      progress: _progress,
      createdAt: widget.task?.createdAt,
    );
    if (_isEditing) {
      await provider.updateTask(task);
    } else {
      await provider.addTask(task);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'แก้ไขงานสำเร็จ ✓' : 'เพิ่มงานสำเร็จ ✓'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Color get _progressColor {
    if (_progress >= 100) return Colors.green;
    if (_progress >= 50) return Colors.orange;
    return const Color(0xFF6C63FF);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.read<TaskProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขงาน' : 'เพิ่มงานใหม่'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text('ชื่องาน *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: _inputDecoration('กรอกชื่องาน', Icons.title),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่องาน' : null,
              ),
              const SizedBox(height: 16),

              // Description
              const Text('รายละเอียด', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: _inputDecoration('รายละเอียดงาน (ไม่บังคับ)', Icons.description),
              ),
              const SizedBox(height: 16),

              // Category
              const Text('หมวดหมู่ *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: _inputDecoration('เลือกหมวดหมู่', Icons.folder_outlined),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'กรุณาเลือกหมวดหมู่' : null,
              ),
              const SizedBox(height: 16),

              // Due Date
              const Text('วันครบกำหนด *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 12),
                      Text(DateFormat('d MMMM yyyy').format(_dueDate)),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status
              const Text('สถานะ *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: _inputDecoration('เลือกสถานะ', Icons.flag_outlined),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('รอดำเนินการ')),
                  DropdownMenuItem(value: 'in_progress', child: Text('กำลังทำ')),
                  DropdownMenuItem(value: 'completed', child: Text('เสร็จแล้ว')),
                ],
                onChanged: (v) => setState(() {
                  _status = v!;
                  if (_status == 'completed') {
                    _progress = 100;
                    _progressCtrl.text = '100';
                  }
                  if (_status == 'pending') {
                    _progress = 0;
                    _progressCtrl.text = '0';
                  }
                }),
              ),
              const SizedBox(height: 24),

              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ความคืบหน้า', style: TextStyle(fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _progressColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _progressColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      '$_progress%',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _progressColor,
                          fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _progressCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'กรอก 0 - 100',
                  prefixIcon: const Icon(Icons.percent),
                  suffixText: '%',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (v) {
                  final val = int.tryParse(v) ?? 0;
                  setState(() {
                    _progress = val.clamp(0, 100);
                  });
                },
                validator: (v) {
                  final val = int.tryParse(v ?? '');
                  if (val == null) return 'กรุณากรอกตัวเลข';
                  if (val < 0 || val > 100) return 'กรุณากรอก 0-100';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _save,
                  icon: Icon(_isEditing ? Icons.save : Icons.add),
                  label: Text(
                    _isEditing ? 'บันทึกการแก้ไข' : 'เพิ่มงาน',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      );
}