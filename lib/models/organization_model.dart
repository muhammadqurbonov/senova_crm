import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class Organization {
  final String id;
  final String name;
  final String plan;
  final String status;
  final DateTime createdAt;

  Organization({
    required this.id,
    required this.name,
    this.plan = 'free',
    this.status = OrgStatus.active,
    required this.createdAt,
  });

  bool get isSuspended => status == OrgStatus.suspended;

  factory Organization.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Organization(
      id: doc.id,
      name: data['name'] ?? '',
      plan: data['plan'] ?? 'free',
      status: data['status'] ?? OrgStatus.active,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
