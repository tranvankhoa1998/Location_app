  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:location_trackingv2/data/models/task_model.dart';

  class TaskFirestoreDataSource {
    final _tasksCollection = FirebaseFirestore.instance.collection('tasks');

    // GetTasks là Stream
    Stream<List<TaskModel>> getTasks() {
      return _tasksCollection.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return TaskModel(
            id: doc.id,
            task: data['task'] ?? '',
            number: data['number'] ?? 0,
            date: (data['date'] as Timestamp).toDate(),
            description: data['description'],
          );
        }).toList();
      });
    }

    // AddTask vẫn là Futures
    Future<void> addTask({
      required String title,
      required DateTime date,
      String? description,
      int number = 0,
    }) async {
      final snapshot = await _tasksCollection.get();
      final currentNumber = snapshot.docs.length;
      await _tasksCollection.add({
        'task': title,  
        'date': date,
        'description': description,
        'number': currentNumber + 1,
      });
    }

    Future<void> updateTask({
      required String id,
      String? title,
      DateTime? date,
      String? description,
      int? number,
    }) async {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['task'] = title;
      if (date != null) updateData['date'] = date;
      if (description != null) updateData['description'] = description;
      if (number != null) updateData['number'] = number;

      await _tasksCollection.doc(id).update(updateData);
    }

    Future<void> deleteTask(String id) async {
      await _tasksCollection.doc(id).delete();
    }
  }