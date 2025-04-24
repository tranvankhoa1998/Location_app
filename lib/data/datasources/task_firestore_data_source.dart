import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskFirestoreDataSource {
  final CollectionReference tasks = FirebaseFirestore.instance.collection('task');

  Stream<List<TaskModel>> getTasks() {
  return tasks.snapshots().map((snapshot) {
    print('Firestore snapshot: ${snapshot.docs.length} documents');
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      print('Doc data: $data');
      return TaskModel.fromFirestore(doc.id, data);
    }).toList();
  });
}

  Future<void> addTask(String task) async {
    await tasks.add({
      'task': task,
      'date': Timestamp.fromDate(DateTime.now()),
      'number': 10,
    });
  }

  Future<void> updateTask(String id, int number) async {
    await tasks.doc(id).update({'number': number});
  }

  Future<void> deleteTask(String id) async {
    await tasks.doc(id).delete();
  }
}