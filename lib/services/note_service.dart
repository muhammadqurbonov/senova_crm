import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/demo/demo_data.dart';
import '../core/constants.dart';
import '../models/note_model.dart';

class NoteService {
  final String orgId;
  NoteService(this.orgId);

  final _db = FirebaseFirestore.instance;

  Stream<List<Note>> watchByCustomer(String customerId) {
    if (isDemoOrg(orgId)) return Stream.value(DemoData.notes(orgId, customerId));
    return _db
        .collection('notes')
        .where('orgId', isEqualTo: orgId)
        .where('customerId', isEqualTo: customerId)
        .limit(kQueryLimit)
        .snapshots()
        .map((snap) {
      final notes = snap.docs.map(Note.fromDoc).toList();
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    });
  }

  Future<void> add({required String customerId, required String type, required String text, required String authorName}) {
    return _db.collection('notes').add({
      'orgId': orgId,
      'customerId': customerId,
      'type': type,
      'text': text,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
