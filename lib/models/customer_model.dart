import 'package:cloud_firestore/cloud_firestore.dart';

enum LeadSource { whatsapp, instagram, telegram, facebook, manual }

extension LeadSourceX on LeadSource {
  String get value => name;
  static LeadSource fromString(String? value) {
    return LeadSource.values.firstWhere((e) => e.name == value, orElse: () => LeadSource.manual);
  }
}

class Customer {
  final String id;
  final String orgId;
  final String name;
  final String phone;
  final LeadSource source;
  final String stageId;
  final String? managerId;
  final String? managerName;
  final List<String> tags;
  final Map<String, dynamic> custom;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.orgId,
    required this.name,
    required this.phone,
    required this.source,
    required this.stageId,
    this.managerId,
    this.managerName,
    this.tags = const [],
    this.custom = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isClaimed => managerId != null;

  factory Customer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Customer(
      id: doc.id,
      orgId: data['orgId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      source: LeadSourceX.fromString(data['source']),
      stageId: data['stageId'] ?? '',
      managerId: data['managerId'],
      managerName: data['managerName'],
      tags: List<String>.from(data['tags'] ?? []),
      custom: Map<String, dynamic>.from(data['custom'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orgId': orgId,
      'name': name,
      'phone': phone,
      'source': source.value,
      'stageId': stageId,
      'managerId': managerId,
      'managerName': managerName,
      'tags': tags,
      'custom': custom,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}