import '../../data/models/task.dart';
import 'task_event.dart';

class TaskState {
  final List<Task> tasks;
  final bool isLoading;
  final String searchQuery;
  final SortType sortType;
  final String? errorMessage;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.sortType = SortType.date,
    this.errorMessage,
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? searchQuery,
    SortType? sortType,
    String? errorMessage,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      sortType: sortType ?? this.sortType,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  List<Task> get filteredTasks {
    // Filter tasks based on search query
    final filtered = searchQuery.isEmpty
        ? List<Task>.from(tasks)
        : tasks.where((task) =>
            task.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    // Sort filtered tasks
    filtered.sort((a, b) {
      if (sortType == SortType.priority) {
        // Null-aware priority with default 0
        return (b.priority ?? 0).compareTo(a.priority ?? 0);
      } else {
        // Sort by createdDate descending
        return b.createdDate.compareTo(a.createdDate);
      }
    });

    return filtered;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskState &&
          runtimeType == other.runtimeType &&
          tasks == other.tasks &&
          isLoading == other.isLoading &&
          searchQuery == other.searchQuery &&
          sortType == other.sortType &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      tasks.hashCode ^
      isLoading.hashCode ^
      searchQuery.hashCode ^
      sortType.hashCode ^
      (errorMessage?.hashCode ?? 0);
}
