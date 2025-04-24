import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/task.dart';

class TaskModel {
  final String id;
  final String task;
  final int number;
  final DateTime date;

  TaskModel({
    required this.id, 
    required this.task, 
    required this.number, 
    required this.date});

  factory TaskModel.fromFirestore(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      task: data['task'] ?? '',
      number: data['number'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Task toEntity() => Task(id: id, task: task, number: number, date: date);
}