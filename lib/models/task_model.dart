import 'package:cloud_firestore/cloud_firestore.dart';

class AppTask {
  final String id;
  final String orgId;
  final String customerId;
  final String customerName;
  final String title;
  final DateTime? dueDate;
  final bool done;
  final String assignedTo;
  final String assignedToName;

  AppTask({
    required this.id,
    required this.orgId,
    required this.customerId,
    required this.customerName,
    required this.title,
    this.dueDate,
    this.done = false,
    required this.assignedTo,
    required this.assignedToName,
  });

  factory AppTask.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppTask(
      id: doc.id,
      orgId: data['orgId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      title: data['title'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      done: data['done'] ?? false,
      assignedTo: data['assignedTo'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
    );
  }
}