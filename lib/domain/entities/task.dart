class Task {
  final String id;
  final String task;
  final int number;
  final DateTime date;
  final String? description;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.task,
    required this.number,
    required this.date,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      task: map['task'] ?? '',
      number: map['number'] ?? 0,
      date: map['date'] != null ? DateTime.fromMillisecondsSinceEpoch(map['date']) : DateTime.now(),
      description: map['description'],
      createdAt: map['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'number': number,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}