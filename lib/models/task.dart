import 'package:flutter/material.dart';

class Task {
  final int? id;
  final String title;
  final String description;
  final int categoryId;
  final DateTime dueDate;
  final String status;
  final int progress;
  final DateTime createdAt;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.dueDate,
    this.status = 'pending',
    this.progress = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'due_date': dueDate.toIso8601String(),
        'status': status,
        'progress': progress,
        'created_at': createdAt.toIso8601String(),
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        categoryId: map['category_id'],
        dueDate: DateTime.parse(map['due_date']),
        status: map['status'],
        progress: map['progress'] ?? 0,
        createdAt: DateTime.parse(map['created_at']),
      );

  Task copyWith({
    int? id, String? title, String? description,
    int? categoryId, DateTime? dueDate,
    String? status, int? progress, DateTime? createdAt,
  }) => Task(
        id: id ?? this.id, title: title ?? this.title,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        createdAt: createdAt ?? this.createdAt,
      );
}

class Category {
  final int? id;
  final String name;
  Category({this.id, required this.name});
  Map<String, dynamic> toMap() => {'id': id, 'name': name};
  factory Category.fromMap(Map<String, dynamic> map) =>
      Category(id: map['id'], name: map['name']);
}

class ProgressStatus {
  final int? id;
  final String name;
  final int percentage;
  ProgressStatus({this.id, required this.name, required this.percentage});
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'percentage': percentage};
  factory ProgressStatus.fromMap(Map<String, dynamic> map) =>
      ProgressStatus(id: map['id'], name: map['name'], percentage: map['percentage']);
}

// ✅ StatusConfig model ใหม่
class StatusConfig {
  final int? id;
  final String keyName; // pending, in_progress, completed, หรือ custom
  final String label;
  final int colorValue;

  StatusConfig({
    this.id,
    required this.keyName,
    required this.label,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() => {
        'id': id,
        'key_name': keyName,
        'label': label,
        'color_value': colorValue,
      };

  factory StatusConfig.fromMap(Map<String, dynamic> map) => StatusConfig(
        id: map['id'],
        keyName: map['key_name'],
        label: map['label'],
        colorValue: map['color_value'],
      );
}