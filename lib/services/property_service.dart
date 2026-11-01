import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/property_model.dart';

class PropertyService {
  final String orgId;
  PropertyService(this.orgId);

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('properties');

  Stream<List<Property>> watchAll() {
    return _col.where('orgId', isEqualTo: orgId).limit(kQueryLimit).snapshots().map((snap) {
      final list = snap.docs.map(Property.fromDoc).toList();
      list.sort((a, b) => a.price.compareTo(b.price));
      return list;
    });
  }

  Future<void> create(Property property) {
    final map = property.toMap();
    map['orgId'] = orgId;
    return _col.add(map);
  }

  Future<void> updateStatus(String id, String status) {
    return _col.doc(id).update({'status': status});
  }

  Future<void> delete(String id) {
    return _col.doc(id).delete();
  }
}
