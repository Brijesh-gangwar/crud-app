
import 'dart:async';
import 'package:crud_app/main.dart';
import 'package:crud_app/screens/login_screen.dart'; 
import 'package:crud_app/screens/task_form_screen.dart';
import 'package:crud_app/widgets/snakbar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/task_local_db.dart';
import '../models/task_model.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum SortType { date, priority }

class _HomeScreenState extends State<HomeScreen> {
  late DatabaseReference taskRef;
  final user = FirebaseAuth.instance.currentUser!;
  final ValueNotifier<List<Task>> tasksNotifier = ValueNotifier([]);
  final localDb = TaskLocalDb.instance;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  bool _isLoading = true;
  SortType _currentSort = SortType.date;

  @override
  void initState() {
    super.initState();
    taskRef = FirebaseDatabase.instance.ref('users/${user.uid}/tasks');
    _loadFromLocal();
    _listenToFirebase();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadFromLocal() async {
    try {
      final localTasks = await localDb.getTasks();
      tasksNotifier.value = localTasks;
    } catch (e) {
      showCustomSnackBar(context: context, message: 'Failed to load local tasks');
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    // Navigate to login screen
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _listenToFirebase() {
    taskRef.onValue.listen((event) async {
      try {
        final value = event.snapshot.value;
        if (value == null) {
          tasksNotifier.value = [];
          await localDb.clearAll();
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        final tasksMap = Map<String, dynamic>.from(value as Map);
        final tasks = tasksMap.entries.map((e) {
          return Task(
            id: e.key,
            title: e.value['title'],
            description: e.value['description'],
            status: e.value['status'],
            createdDate: DateTime.parse(e.value['createdDate']),
            priority: e.value['priority'],
          );
        }).toList();

        tasksNotifier.value = tasks;

        await localDb.clearAll();
        for (var task in tasks) {
          await localDb.insertTask(task);
        }
      } catch (e) {
        showCustomSnackBar(context: context, message: 'Failed to sync with Firebase');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }, onError: (error) {
      showCustomSnackBar(context: context, message: 'Firebase error: $error');
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _addOrEditTask({Task? task}) async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );

    if (result != null) {
      final newTask = result;

      try {
        final taskId = newTask.id ?? taskRef.push().key!;
        final taskToSave = newTask.copyWith(id: taskId);
        await taskRef.child(taskId).set(taskToSave.toJson());
        await localDb.insertTask(taskToSave);

        showCustomSnackBar(
          context: context,
          message: task == null ? 'Task added successfully' : 'Task updated successfully',
        );
      } catch (e) {
        showCustomSnackBar(context: context, message: 'Failed to save task');
      }
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      await taskRef.child(id).remove();
      await localDb.deleteTask(id);
      showCustomSnackBar(context: context, message: 'Task deleted successfully');
    } catch (e) {
      showCustomSnackBar(context: context, message: 'Failed to delete task');
    }
  }

  List<Task> getFilteredTasks() {
    final allTasks = tasksNotifier.value;

    List<Task> filtered = _searchQuery.isEmpty
        ? [...allTasks]
        : allTasks
            .where((task) => task.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    filtered.sort((a, b) {
      if (_currentSort == SortType.priority) {
        return (b.priority ?? 0).compareTo(a.priority ?? 0);
      } else {
        return b.createdDate.compareTo(a.createdDate);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Tasks'),
        actions: [
          IconButton(
            icon: Icon(themeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut, // ← call your signOut method here
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    focusNode: _searchFocusNode,
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search tasks by title...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                _searchFocusNode.unfocus();
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
                        value: _currentSort,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _currentSort = value);
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
                  child: ValueListenableBuilder<List<Task>>(
                    valueListenable: tasksNotifier,
                    builder: (_, __, ___) {
                      final filteredTasks = getFilteredTasks();

                      if (filteredTasks.isEmpty) {
                        return const Center(child: Text('No tasks found.'));
                      }

                      return ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (_, i) {
                          final task = filteredTasks[i];
                          return Dismissible(
                            key: Key(task.id!),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Task?'),
                                  content: const Text('Are you sure you want to delete this task?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Delete')),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => _deleteTask(task.id!),
                            background: Container(
                              color: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.centerRight,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: TaskCard(
                              task: task,
                              onEdit: () => _addOrEditTask(task: task),
                              onDelete: () => _deleteTask(task.id!),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditTask(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
