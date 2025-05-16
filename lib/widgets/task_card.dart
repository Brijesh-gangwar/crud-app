import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return 
        Card(
        
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 9),
        elevation: 3,
        
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              
                children: [
                  // Title
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isLargeScreen ? 20 : 16,
                        ),
                  ),
                  const SizedBox(height: 8),
                    
                  
                  Container(
  constraints: BoxConstraints(maxWidth: isLargeScreen ? 300:240),  // or MediaQuery width fraction
  child: Text(
    "Description: ${task.description}",
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  ),
),
                  const SizedBox(height: 8),
                    
                
                  Text("Created: ${task.createdDate.toLocal().toString().split(' ')[0]}"),
                    const SizedBox(height: 4),
                  // Status and Priority
                  Wrap(
                    spacing: 12,
                    children: [
                      Chip(label: Text("Status: ${task.status}")),
                      Chip(label: Text("Priority: ${task.priority}")),
                    ],
                  ),
                    
                  const SizedBox(height: 4),
                  
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
          tooltip: 'Edit Task',
        ),
                ],
              )
            ],
          ),
        ),
    
      
     
    );
  }
}
