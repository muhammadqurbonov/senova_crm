import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pipeline_stage_model.dart';

class PipelineStageService {
  final String orgId;
  PipelineStageService(this.orgId);

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('pipelineStages');

  Stream<List<PipelineStage>> watchAll() {
    return _col.where('orgId', isEqualTo: orgId).snapshots().map((snap) {
      final list = snap.docs.map(PipelineStage.fromDoc).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  /// ID-и ҳуҷҷати stage-и нав. Бо orgId пеш аз калид, то дар байни ширкатҳо бархӯрд нашавад.
  String docIdForKey(String key) => '${orgId}_$key';

  Future<bool> exists(String docId) async {
    final d = await _col.doc(docId).get();
    return d.exists;
  }

  Future<void> save({
    required String docId,
    required String key,
    required String nameTj,
    required String nameRu,
    required String nameEn,
    required int order,
    required String color,
    required String type,
  }) {
    return _col.doc(docId).set({
      'orgId': orgId,
      'key': key,
      'name_tj': nameTj,
      'name_ru': nameRu,
      'name_en': nameEn,
      'order': order,
      'color': color,
      'type': type,
    });
  }

  Future<void> delete(String docId) {
    return _col.doc(docId).delete();
  }
}
