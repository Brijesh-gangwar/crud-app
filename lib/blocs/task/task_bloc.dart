import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../data/local_db/task_local_db.dart';

import '../../data/models/task.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskLocalDb localDb;
  final DatabaseReference taskRef;
  late final StreamSubscription<DatabaseEvent> _firebaseSub;

  TaskBloc({required this.localDb, required User user})
      : taskRef = FirebaseDatabase.instance.ref('users/${user.uid}/tasks'),
        super(const TaskState(isLoading: true)) {
    on<LoadTasksEvent>(_onLoadTasks);
    on<AddOrUpdateTaskEvent>(_onAddOrUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<SearchTasksEvent>(_onSearchTasks);
    on<SortTasksEvent>(_onSortTasks);

    // Listen to Firebase realtime updates
    _firebaseSub = taskRef.onValue.listen(
      _onFirebaseData,
      onError: _onFirebaseError,
    );

    // Initial local load
    add(LoadTasksEvent());
  }

  Future<void> _onLoadTasks(LoadTasksEvent event, Emitter<TaskState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final localTasks = await localDb.getTasks();
      emit(state.copyWith(tasks: localTasks, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to load local tasks: $e'));
    }
  }

  Future<void> _onAddOrUpdateTask(AddOrUpdateTaskEvent event, Emitter<TaskState> emit) async {
    try {
      final task = event.task;
      final taskId = task.id ?? taskRef.push().key!;
      final taskToSave = task.copyWith(id: taskId);

      await taskRef.child(taskId).set(taskToSave.toJson());
      await localDb.insertTask(taskToSave);

      // Update local state instantly
      final updatedTasks = List<Task>.from(state.tasks);
      final index = updatedTasks.indexWhere((t) => t.id == taskToSave.id);
      if (index >= 0) {
        updatedTasks[index] = taskToSave;
      } else {
        updatedTasks.add(taskToSave);
      }

      emit(state.copyWith(tasks: updatedTasks, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to save task: $e'));
    }
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await taskRef.child(event.taskId).remove();
      await localDb.deleteTask(event.taskId);

      final updatedTasks = state.tasks.where((t) => t.id != event.taskId).toList();
      emit(state.copyWith(tasks: updatedTasks, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete task: $e'));
    }
  }

  void _onSearchTasks(SearchTasksEvent event, Emitter<TaskState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onSortTasks(SortTasksEvent event, Emitter<TaskState> emit) {
    emit(state.copyWith(sortType: event.sortType));
  }

  Future<void> _onFirebaseData(DatabaseEvent event) async {
    try {
      final value = event.snapshot.value;
      if (value == null) {
        await localDb.clearAll();
        emit(state.copyWith(tasks: [], isLoading: false, errorMessage: null));
        return;
      }

      final tasksMap = Map<String, dynamic>.from(value as Map);
      final tasks = tasksMap.entries.map((entry) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        return Task(
          id: entry.key,
          title: data['title'] as String? ?? '',
          description: data['description'],
          status: data['status'],
          createdDate:  DateTime.now(),
          priority: data['priority'],
        );
      }).toList();

      // Sync local DB with Firebase data
      await localDb.clearAll();
      for (final task in tasks) {
        await localDb.insertTask(task);
      }

      emit(state.copyWith(tasks: tasks, isLoading: false, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to sync with Firebase: $e', isLoading: false));
    }
  }

  void _onFirebaseError(Object error) {
    addError(error, StackTrace.current);
  }

  @override
  Future<void> close() {
    _firebaseSub.cancel();
    return super.close();
  }
}
