import '../../data/models/task.dart';

abstract class TaskEvent {}

class LoadTasksEvent extends TaskEvent {}

class AddOrUpdateTaskEvent extends TaskEvent {
  final Task task;
  AddOrUpdateTaskEvent(this.task);
}

class DeleteTaskEvent extends TaskEvent {
  final String taskId;
  DeleteTaskEvent(this.taskId);
}

class SearchTasksEvent extends TaskEvent {
  final String query;
  SearchTasksEvent(this.query);
}

class SortTasksEvent extends TaskEvent {
  final SortType sortType;
  SortTasksEvent(this.sortType);
}

enum SortType { date, priority }
