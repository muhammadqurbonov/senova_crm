import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/deal_model.dart';

class DealService {
  final String orgId;
  DealService(this.orgId);

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('deals');

  Stream<List<Deal>> watchAll() {
    return _col.where('orgId', isEqualTo: orgId).limit(kQueryLimit).snapshots().map((snap) {
      final list = snap.docs.map(Deal.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<Deal>> watchByCustomer(String customerId) {
    return _col
        .where('orgId', isEqualTo: orgId)
        .where('customerId', isEqualTo: customerId)
        .limit(kQueryLimit)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Deal.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> create({
    required String customerId,
    required String propertyId,
    required double amount,
    required String paymentType,
    String paymentNote = '',
  }) {
    return _col.add({
      'orgId': orgId,
      'customerId': customerId,
      'propertyId': propertyId,
      'amount': amount,
      'paymentType': paymentType,
      'paymentNote': paymentNote,
      'status': DealStatus.open,
      'createdAt': FieldValue.serverTimestamp(),
      'closedAt': null,
    });
  }

  /// true => сделка пӯшида шуд. false => сделка аллакай пӯшида/рад шуда буд (идемпотентӣ).
  Future<bool> closeDeal({required String dealId, required String customerId}) {
    return _finish(dealId, customerId, DealStatus.closed, StageKeys.won);
  }

  Future<bool> rejectDeal({required String dealId, required String customerId}) {
    return _finish(dealId, customerId, DealStatus.rejected, StageKeys.lost);
  }

  /// Транзаксия: статуси сделка ва stage-и мизоҷ якҷоя тағйир меёбад; такрори амал таъсир намекунад.
  Future<bool> _finish(String dealId, String customerId, String newStatus, String stageKey) {
    return _db.runTransaction<bool>((tx) async {
      final dealRef = _col.doc(dealId);
      final snap = await tx.get(dealRef);
      if (!snap.exists) return false;
      final data = snap.data()!;
      if (data['orgId'] != orgId || data['customerId'] != customerId) return false;
      if (data['status'] != DealStatus.open) return false;
      tx.update(dealRef, {'status': newStatus, 'closedAt': FieldValue.serverTimestamp()});
      tx.update(_db.collection('customers').doc(customerId), {
        'stageId': stageKey,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<void> delete(String dealId) {
    return _col.doc(dealId).delete();
  }
}
