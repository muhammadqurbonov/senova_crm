import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';
import '../core/errors.dart';
import '../models/organization_model.dart';
import '../core/industries.dart';

class OrganizationService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Organization>> watchAll() {
    return _db.collection('organizations').snapshots().map(
          (snap) => snap.docs.map(Organization.fromDoc).toList(),
        );
  }

  Stream<Organization?> watchOne(String orgId) {
    return _db.collection('organizations').doc(orgId).snapshots().map(
          (doc) => doc.exists ? Organization.fromDoc(doc) : null,
        );
  }

  /// Ширкат + stage-ҳо + admin + loginIndex дар ЯК batch (ё ҳама, ё ҳеҷ чиз).
  Future<String> createOrganization({
    required String orgName,
    required String adminName,
    required String adminLogin,
    required String adminEmail,
    required String adminPassword,
    String industry = 'real_estate',
  }) async {
    final normalizedLogin = adminLogin.trim().toLowerCase();
    final email = adminEmail.trim();
    final indexRef = _db.collection('loginIndex').doc(normalizedLogin);
    if ((await indexRef.get()).exists) {
      throw const AuthFailure('err_login_taken');
    }

    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    User? created;

    try {
      final cred = await secondaryAuth.createUserWithEmailAndPassword(email: email, password: adminPassword);
      created = cred.user;
      final uid = created!.uid;

      final orgRef = _db.collection('organizations').doc();
      final orgId = orgRef.id;

      final batch = _db.batch();
      batch.set(orgRef, {
        'name': orgName,
        'plan': 'free',
        'status': OrgStatus.active,
        'industry': industry,
        'modules': ['items', 'deals', 'tasks'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (final stage in stagesDataFor(industry, orgId)) {
        final id = stage['id'] as String;
        final data = Map<String, dynamic>.from(stage)..remove('id');
        batch.set(_db.collection('pipelineStages').doc('${orgId}_$id'), data);
      }
      batch.set(_db.collection('users').doc(uid), {
        'name': adminName,
        'email': email,
        'login': normalizedLogin,
        'orgId': orgId,
        'role': 'admin',
        'isSuperAdmin': false,
        'language': 'ru',
        'active': true,
      });
      batch.set(indexRef, {'email': email, 'orgId': orgId, 'uid': uid});
      await batch.commit();
      created = null;
      return orgId;
    } catch (e) {
      if (created != null) {
        try {
          await created.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      try {
        await secondaryAuth.signOut();
      } catch (_) {}
      await secondaryApp.delete();
    }
  }

  /// Танзимоти ширкат (соҳа, модулҳо, номҳо, майдонҳои иловагӣ, тариф). Танҳо Super Admin (rules).
  Future<void> updateConfig(String orgId, Map<String, dynamic> data) {
    return _db.collection('organizations').doc(orgId).update(data);
  }

  /// Боздоштан/фаъол кардани ширкат. Маълумот нест намешавад.
  Future<void> setStatus(String orgId, String status) {
    return _db.collection('organizations').doc(orgId).update({'status': status});
  }

  /// Нест кардани ҳуҷҷати ширкат (танҳо барои ширкати боздошташуда аз UI). Маълумоти вобаста мемонад.
  Future<void> deleteOrganization(String orgId) {
    return _db.collection('organizations').doc(orgId).delete();
  }
}
