import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/demo/demo_data.dart';
import '../core/constants.dart';
import '../models/customer_model.dart';

class CustomerService {
  final String orgId;
  CustomerService(this.orgId);

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('customers');

  Stream<List<Customer>> watchAll() {
    if (isDemoOrg(orgId)) return Stream.value(DemoData.customers(orgId));
    return _col.where('orgId', isEqualTo: orgId).limit(kQueryLimit).snapshots().map((snap) {
      final list = snap.docs.map(Customer.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Транзаксия: ду менеҷер ҳамзамон гирифта наметавонанд. false => аллакай гирифта шудааст.
  Future<bool> claim({required String customerId, required String managerId, required String managerName}) async {
    return _db.runTransaction<bool>((tx) async {
      final ref = _col.doc(customerId);
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      if (snap.data()?['managerId'] != null) return false;
      tx.update(ref, {'managerId': managerId, 'managerName': managerName, 'updatedAt': FieldValue.serverTimestamp()});
      return true;
    });
  }

  Future<void> updateStage(String customerId, String newStageKey) {
    return _col.doc(customerId).update({'stageId': newStageKey, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> create({
    required String name,
    required String phone,
    required String stageId,
    Map<String, dynamic> custom = const {},
  }) {
    return _col.add({
      'orgId': orgId,
      'name': name,
      'phone': phone,
      'source': 'manual',
      'stageId': stageId,
      'managerId': null,
      'tags': <String>[],
      'custom': custom,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(String customerId, {required String name, required String phone, required Map<String, dynamic> custom}) {
    return _col.doc(customerId).update({'name': name, 'phone': phone, 'custom': custom, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> delete(String customerId) {
    return _col.doc(customerId).delete();
  }
}
