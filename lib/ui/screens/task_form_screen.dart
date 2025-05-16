
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../blocs/task/task_bloc.dart';
import '../../blocs/task/task_event.dart';
import '../../data/models/task.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late String _status;
  late int _priority;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.task?.title ?? '';
    _descCtrl.text = widget.task?.description ?? '';
    _status = widget.task?.status ?? 'Pending';
    _priority = widget.task?.priority ?? 1;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submitTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final task = Task(
        id: widget.task?.id ?? const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        status: _status,
        createdDate: widget.task?.createdDate ?? DateTime.now(),
        priority: _priority,
      );

      context.read<TaskBloc>().add(AddOrUpdateTaskEvent(task));
      Navigator.of(context).pop(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Task' : 'Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Enter title'
                            : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Enter description'
                            : null,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'In Progress',
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem(
                    value: 'Completed',
                    child: Text('Completed'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [

                  DropdownMenuItem(value: 1, child: Text('1 - Very Low')),
                  DropdownMenuItem(value: 2, child: Text('2 - Low')),
                 
                  DropdownMenuItem(value: 3, child: Text('3 - Moderate')), 
                  DropdownMenuItem(value: 4, child: Text('4 - High')), 
                  DropdownMenuItem(value: 5, child: Text('5 - Very High')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _priority = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitTask,
                child: Text(isEditing ? 'Update Task' : 'Add Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
