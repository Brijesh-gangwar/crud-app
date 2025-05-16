
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../blocs/task/task_bloc.dart';
import '../../blocs/task/task_event.dart';
import '../../blocs/task/task_state.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../data/local_db/task_local_db.dart';
import '../../data/models/task.dart';

import '../../main.dart';
import '../screens/task_form_screen.dart';
import '../widgets/custom_snack_bar.dart';
import '../widgets/task_card.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final localDb = TaskLocalDb.instance;

    return BlocProvider(
      create:
          (_) => TaskBloc(localDb: localDb, user: user)..add(LoadTasksEvent()),
      child: const HomeScreenView(),
    );
  }
}

class HomeScreenView extends StatefulWidget {
  const HomeScreenView({super.key});

  @override
  State<HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<HomeScreenView> {
  final TextEditingController _searchController = TextEditingController();
  SortType _currentSort = SortType.date;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    _searchController.addListener(() {
      context.read<TaskBloc>().add(SearchTasksEvent(_searchController.text));
    });
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();

    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SplashWrapper()),
        (route) => false,
      );
    }
  }

  Future<void> _addOrEditTask([Task? task]) async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder:
            (_) => BlocProvider.value(
              value: context.read<TaskBloc>(),
              child: TaskFormScreen(task: task),
            ),
      ),
    );

    if (result != null) {
      context.read<TaskBloc>().add(AddOrUpdateTaskEvent(result));
    }
    if (result == null) {
      showCustomSnackBar(context: context, message: 'Task not saved');
    } else {
      showCustomSnackBar(context: context, message: 'Task saved successfully');
    }
  }

  Future<void> _deleteTask(String id) async {
    context.read<TaskBloc>().add(DeleteTaskEvent(id));
    showCustomSnackBar(context: context, message: 'Task deleted successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Tasks'),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeBloc>().state.mode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeBloc>().add(ToggleThemeEvent());
            },
          ),

          SizedBox(width: 4),
          IconButton(icon: const Icon(Icons.logout), onPressed: signOut),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : BlocConsumer<TaskBloc, TaskState>(
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    showCustomSnackBar(
                      context: context,
                      message: state.errorMessage!,
                    );
                  }
                },
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = state.filteredTasks;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search tasks by title...',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Icons.cancel),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<TaskBloc>().add(
                                          SearchTasksEvent(''),
                                        );
                                        FocusScope.of(context).unfocus();
                                      },
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            const Text('Sort by:'),
                            const SizedBox(width: 10),
                            DropdownButton<SortType>(
                              value: state.sortType,
                              onChanged: (value) {
                                if (value != null) {
                                  context.read<TaskBloc>().add(
                                    SortTasksEvent(value),
                                  );
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: SortType.date,
                                  child: Text('Date'),
                                ),
                                DropdownMenuItem(
                                  value: SortType.priority,
                                  child: Text('Priority'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            tasks.isEmpty
                                ? const Center(child: Text('No tasks found.'))
                                : ListView.builder(
                                  itemCount: tasks.length,
                                  itemBuilder: (_, i) {
                                    final task = tasks[i];
                                    return Dismissible(
                                      key: Key(task.id!),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (_) async {
                                        return await showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'Delete Task?',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to delete this task?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.of(
                                                          context,
                                                        ).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.of(
                                                          context,
                                                        ).pop(true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                      onDismissed: (_) => _deleteTask(task.id!),
                                      background: Container(
                                        color: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        alignment: Alignment.centerRight,
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      child: TaskCard(
                                        task: task,
                                        onEdit: () => _addOrEditTask(task),
                                        onDelete: () => _deleteTask(task.id!),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditTask(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
