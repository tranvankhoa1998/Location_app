class Task {
  final String id;
  final String task;
  final int number;
  final DateTime date;
  final String? description;

  Task({
    required this.id,
    required this.task,
    required this.number,
    required this.date,
    this.description,
  });
}