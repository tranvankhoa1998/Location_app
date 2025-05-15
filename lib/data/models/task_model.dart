import '../../domain/entities/task.dart';

class TaskModel {
  final String id;
  final String task;
  final int number;
  final DateTime date;
  final String? description;
  final Map<String, dynamic>? metadata;

  TaskModel({
    required this.id,
    required this.task,
    required this.number,
    required this.date,
    this.description,
    this.metadata,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    DateTime dateTime;
    
    if (json['date'] is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(json['date']);
    } else if (json['date'] is DateTime) {
      dateTime = json['date'];
    } else {
      dateTime = DateTime.now();
    }
    
    Map<String, dynamic>? metadata;
    if (json['metadata'] != null && json['metadata'] is Map) {
      metadata = Map<String, dynamic>.from(json['metadata'] as Map);
    }
    
    return TaskModel(
      id: json['id'] ?? '',
      task: json['task'] ?? '',
      number: json['number'] ?? 0,
      date: dateTime,
      description: json['description'],
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'number': number,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      if (metadata != null) 'metadata': metadata,
    };
  }

  Task toEntity() {
    return Task(
      id: id,
      task: task,
      number: number,
      date: date,
      description: description,
      metadata: metadata,
    );
  }
}