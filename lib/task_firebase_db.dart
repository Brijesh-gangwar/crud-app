import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'data/models/task.dart';

class TaskFirebaseDb {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  // Automatically get the current user's UID
  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return user.uid;
  }

  // Insert task
  Future<void> insertTask(Task task) async {
    final taskPath = dbRef.child('users').child(_userId).child('tasks').child(task.id!);
    await taskPath.set(task.toJson());
  }

  // Update task
  Future<void> updateTask(Task task) async {
    final taskPath = dbRef.child('users').child(_userId).child('tasks').child(task.id!);
    await taskPath.update(task.toJson());
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    final taskPath = dbRef.child('users').child(_userId).child('tasks').child(taskId);
    await taskPath.remove();
  }

  // Get all tasks
  Future<List<Task>> getTasks() async {
    final snapshot = await dbRef.child('users').child(_userId).child('tasks').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.entries.map((entry) {
        final taskData = Map<String, dynamic>.from(entry.value);
        return Task.fromJson(taskData);
      }).toList();
    }
    return [];
  }
}
