import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Category> _categories = [];
  List<ProgressStatus> _progressStatuses = [];
  List<StatusConfig> _statusConfigs = [];
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _sortBy = 'due_date';

  List<Task> get tasks => _filteredTasks();
  List<Category> get categories => _categories;
  List<ProgressStatus> get progressStatuses => _progressStatuses;
  List<StatusConfig> get statusConfigs => _statusConfigs;
  String get filterStatus => _filterStatus;
  String get sortBy => _sortBy;

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.status == 'completed').length;
  int get pendingCount => _tasks.where((t) => t.status == 'pending').length;
  int get inProgressCount => _tasks.where((t) => t.status == 'in_progress').length;

  // ✅ ดึง label จาก statusConfigs
  String getStatusLabel(String key) {
    try {
      return _statusConfigs.firstWhere((s) => s.keyName == key).label;
    } catch (_) {
      switch (key) {
        case 'completed': return 'เสร็จแล้ว';
        case 'in_progress': return 'กำลังทำ';
        default: return 'รอดำเนินการ';
      }
    }
  }

  // ✅ ดึง color จาก statusConfigs
  Color getStatusColor(String key) {
    try {
      return _statusConfigs.firstWhere((s) => s.keyName == key).color;
    } catch (_) {
      switch (key) {
        case 'completed': return Colors.green;
        case 'in_progress': return Colors.orange;
        default: return Colors.blueGrey;
      }
    }
  }

  // ✅ ดึง icon จาก key
  IconData getStatusIcon(String key) {
    switch (key) {
      case 'completed': return Icons.check_circle_outline;
      case 'in_progress': return Icons.autorenew;
      default: return Icons.radio_button_unchecked;
    }
  }

  List<Task> _filteredTasks() {
    List<Task> result = List.from(_tasks);
    if (_searchQuery.isNotEmpty) {
      result = result.where((t) =>
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_filterStatus != 'all') {
      result = result.where((t) => t.status == _filterStatus).toList();
    }
    result.sort((a, b) {
      if (_sortBy == 'title') return a.title.compareTo(b.title);
      if (_sortBy == 'created_at') return b.createdAt.compareTo(a.createdAt);
      return a.dueDate.compareTo(b.dueDate);
    });
    return result;
  }

  Future<void> loadTasks() async {
    _tasks = await DatabaseService.instance.getAllTasks();
    _categories = await DatabaseService.instance.getAllCategories();
    _progressStatuses = await DatabaseService.instance.getAllProgressStatuses();
    _statusConfigs = await DatabaseService.instance.getAllStatusConfigs();
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await DatabaseService.instance.insertTask(task);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await DatabaseService.instance.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await DatabaseService.instance.deleteTask(id);
    await loadTasks();
  }

  Future<void> addProgressStatus(ProgressStatus ps) async {
    await DatabaseService.instance.insertProgressStatus(ps);
    await loadTasks();
  }

  Future<void> updateProgressStatus(ProgressStatus ps) async {
    await DatabaseService.instance.updateProgressStatus(ps);
    await loadTasks();
  }

  Future<void> deleteProgressStatus(int id) async {
    await DatabaseService.instance.deleteProgressStatus(id);
    await loadTasks();
  }

  // ✅ Status Config CRUD
  Future<void> addStatusConfig(StatusConfig sc) async {
    await DatabaseService.instance.insertStatusConfig(sc);
    await loadTasks();
  }

  Future<void> updateStatusConfig(StatusConfig sc) async {
    await DatabaseService.instance.updateStatusConfig(sc);
    await loadTasks();
  }

  Future<void> deleteStatusConfig(int id) async {
    await DatabaseService.instance.deleteStatusConfig(id);
    await loadTasks();
  }

  void setSearch(String query) { _searchQuery = query; notifyListeners(); }
  void setFilter(String status) { _filterStatus = status; notifyListeners(); }
  void setSortBy(String sort) { _sortBy = sort; notifyListeners(); }

  String getCategoryName(int categoryId) {
    try { return _categories.firstWhere((c) => c.id == categoryId).name; }
    catch (_) { return 'ไม่ระบุ'; }
  }

  Map<String, int> get countByCategory {
    final map = <String, int>{};
    for (final cat in _categories) {
      map[cat.name] = _tasks.where((t) => t.categoryId == cat.id).length;
    }
    return map;
  }
}