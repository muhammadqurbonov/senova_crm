import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuditEntry {
  final String id;
  final String actorName;
  final String action;
  final String targetType;
  final String targetId;
  final String details;
  final DateTime createdAt;

  AuditEntry({
    required this.id,
    required this.actorName,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.details,
    required this.createdAt,
  });

  factory AuditEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return AuditEntry(
      id: doc.id,
      actorName: d['actorName'] ?? '',
      action: d['action'] ?? '',
      targetType: d['targetType'] ?? '',
      targetId: d['targetId'] ?? '',
      details: d['details'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Журнали амалҳои муҳим. Навиштан танҳо create (бе тағйир/нест кардан) — қ. firestore.rules.
/// Диққат: ин журнал аз клиент навишта мешавад; барои журнали комилан бебаҳс (tamper-proof)
/// навиштан бояд аз Cloud Functions гузарад (қ. docs/ROADMAP.md).
class AuditService {
  final String orgId;
  AuditService(this.orgId);

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('auditLogs');

  Future<void> log(
    AppUser actor,
    String action, {
    String targetType = '',
    String targetId = '',
    String details = '',
  }) async {
    try {
      await _col.add({
        'orgId': orgId,
        'actorUid': actor.uid,
        'actorName': actor.name.isEmpty ? actor.login : actor.name,
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'details': details.length > 300 ? details.substring(0, 300) : details,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Хатои журнал набояд амали асосиро вайрон кунад.
    }
  }

  Stream<List<AuditEntry>> watchRecent({int limit = 100}) {
    return _col
        .where('orgId', isEqualTo: orgId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(AuditEntry.fromDoc).toList());
  }
}
