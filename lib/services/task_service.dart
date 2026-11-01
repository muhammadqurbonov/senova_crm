import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/task_model.dart';

class TaskService {
  final String orgId;
  TaskService(this.orgId);

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('tasks');

  static int _byDueDate(AppTask a, AppTask b) {
    if (a.dueDate == null && b.dueDate == null) return 0;
    if (a.dueDate == null) return 1;
    if (b.dueDate == null) return -1;
    return a.dueDate!.compareTo(b.dueDate!);
  }

  Stream<List<AppTask>> watchByUser(String uid) {
    return _col
        .where('orgId', isEqualTo: orgId)
        .where('assignedTo', isEqualTo: uid)
        .limit(kQueryLimit)
        .snapshots()
        .map((snap) {
      final tasks = snap.docs.map(AppTask.fromDoc).toList();
      tasks.sort(_byDueDate);
      return tasks;
    });
  }

  /// Ҳамаи супоришҳои ширкат (барои dashboard).
  Stream<List<AppTask>> watchAll() {
    return _col.where('orgId', isEqualTo: orgId).limit(kQueryLimit).snapshots().map((snap) {
      final tasks = snap.docs.map(AppTask.fromDoc).toList();
      tasks.sort(_byDueDate);
      return tasks;
    });
  }

  Future<void> create({
    required String customerId,
    required String customerName,
    required String title,
    DateTime? dueDate,
    required String assignedTo,
    required String assignedToName,
  }) {
    return _col.add({
      'orgId': orgId,
      'customerId': customerId,
      'customerName': customerName,
      'title': title,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'done': false,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleDone(String id, bool done) {
    return _col.doc(id).update({'done': done});
  }

  Future<void> delete(String id) {
    return _col.doc(id).delete();
  }
}
