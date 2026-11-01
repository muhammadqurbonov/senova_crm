import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';
import '../core/errors.dart';
import '../models/user_model.dart';

class EmployeeService {
  final String orgId;
  EmployeeService(this.orgId);

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  Stream<List<AppUser>> watchAll() {
    return _col.where('orgId', isEqualTo: orgId).limit(kQueryLimit).snapshots().map(
          (snap) => snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> updateRole(String uid, UserRole role) {
    return _col.doc(uid).update({'role': role.value});
  }

  /// Ғайрифаъол кардан бо нигоҳ доштани маълумот (нест кардан не).
  Future<void> setActive(String uid, bool active) {
    return _col.doc(uid).update({'active': active});
  }

  Future<void> createEmployee({
    required String name,
    required String login,
    required String realEmail,
    required String password,
    required UserRole role,
  }) async {
    final normalizedLogin = login.trim().toLowerCase();
    final email = realEmail.trim();
    final indexRef = _db.collection('loginIndex').doc(normalizedLogin);

    // Логин дар тамоми платформа ягона аст; кӯшиши сарнавиштани логини ширкати дигарро рад мекунем.
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
      final cred = await secondaryAuth.createUserWithEmailAndPassword(email: email, password: password);
      created = cred.user;
      final uid = created!.uid;

      final batch = _db.batch();
      batch.set(_col.doc(uid), {
        'name': name,
        'email': email,
        'login': normalizedLogin,
        'orgId': orgId,
        'role': role.value,
        'isSuperAdmin': false,
        'language': 'ru',
        'active': true,
      });
      batch.set(indexRef, {'email': email, 'orgId': orgId, 'uid': uid});
      await batch.commit();
      created = null; // муваффақ
    } catch (e) {
      // Агар аккаунти Auth сохта шуда, вале профил навишта нашуд — аккаунти ятимро тоза мекунем.
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

  /// Нест кардани профил + loginIndex. Аккаунти Firebase Auth мемонад, вале бе профил ворид шуда наметавонад.
  Future<void> deleteEmployee({required String uid, required String login}) async {
    final batch = _db.batch();
    batch.delete(_col.doc(uid));
    if (login.isNotEmpty) {
      batch.delete(_db.collection('loginIndex').doc(login.toLowerCase()));
    }
    await batch.commit();
  }
}
