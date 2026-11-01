import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType { full, installment }

class Deal {
  final String id;
  final String orgId;
  final String customerId;
  final String propertyId;
  final double amount;
  final PaymentType paymentType;
  final String paymentNote;
  final String status;
  final DateTime createdAt;
  final DateTime? closedAt;

  Deal({
    required this.id,
    required this.orgId,
    required this.customerId,
    required this.propertyId,
    required this.amount,
    this.paymentType = PaymentType.full,
    this.paymentNote = '',
    this.status = 'open',
    required this.createdAt,
    this.closedAt,
  });

  factory Deal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Deal(
      id: doc.id,
      orgId: data['orgId'] ?? '',
      customerId: data['customerId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentType: data['paymentType'] == 'installment' ? PaymentType.installment : PaymentType.full,
      paymentNote: data['paymentNote'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orgId': orgId,
      'customerId': customerId,
      'propertyId': propertyId,
      'amount': amount,
      'paymentType': paymentType == PaymentType.installment ? 'installment' : 'full',
      'paymentNote': paymentNote,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
    };
  }
}