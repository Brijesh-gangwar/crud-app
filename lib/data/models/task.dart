
// import 'package:firebase_database/firebase_database.dart';

// class Task {
//   String? id;
//   final String title;
//   final String description;
//   final String status;
//   final DateTime createdDate;
//   final int priority;

//   Task({
//     this.id,
//     required this.title,
//     required this.description,
//     required this.status,
//     required this.createdDate,
//     required this.priority,
//   });

//   Map<String, dynamic> toJson() => {
//         'title': title,
//         'description': description,
//         'status': status,
//         'createdDate': createdDate.toIso8601String(),
//         'priority': priority,
//       };

//   factory Task.fromSnapshot(DataSnapshot snap) {
//     final data = Map<String, dynamic>.from(snap.value as Map);
//     return Task(
//       id: snap.key,
//       title: data['title'],
//       description: data['description'],
//       status: data['status'],
//       createdDate: DateTime.parse(data['createdDate']),
//       priority: data['priority'],
//     );
//   }
// }


class Task {
  String? id;
  final String title;
  final String description;
  final String status;
  final DateTime createdDate;
  final int priority;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdDate,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status,
    'createdDate': createdDate.toIso8601String(),
    'priority': priority,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    status: json['status'],
    createdDate: DateTime.parse(json['createdDate']),
    priority: json['priority'],
  );


  Task copyWith({
  String? id,
  String? title,
  String? description,
  String? status,
  DateTime? createdDate,
  int? priority,
}) {
  return Task(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    createdDate: createdDate ?? this.createdDate,
    priority: priority ?? this.priority,
  );
}

}