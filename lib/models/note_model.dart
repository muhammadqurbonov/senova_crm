import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String orgId;
  final String customerId;
  final String type;
  final String text;
  final String authorName;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.orgId,
    required this.customerId,
    required this.type,
    required this.text,
    required this.authorName,
    required this.createdAt,
  });

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Note(
      id: doc.id,
      orgId: data['orgId'] ?? '',
      customerId: data['customerId'] ?? '',
      type: data['type'] ?? 'note',
      text: data['text'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}