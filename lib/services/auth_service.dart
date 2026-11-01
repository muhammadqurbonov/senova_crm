import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String?> _emailForLogin(String login) async {
    final normalized = login.trim().toLowerCase();
    if (normalized.isEmpty || normalized.contains('/')) return null;
    final doc = await _db.collection('loginIndex').doc(normalized).get();
    if (!doc.exists) return null;
    return doc.data()?['email'] as String?;
  }

  /// Вуруд бо логини кӯтоҳ. Паёми хатои "логин нест" ва "парол нодуруст" якхела аст
  /// (то username enumeration душвор шавад).
  Future<AppUser> loginWithUsername(String login, String password) async {
    final email = await _emailForLogin(login);
    if (email == null || password.isEmpty) {
      throw const AuthFailure('err_invalid_credentials');
    }
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    try {
      return await _fetchAppUser(cred.user!.uid);
    } catch (e) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<void> logout() => _auth.signOut();

  /// Email-и барқарорсозӣ. Агар логин ёфт нашавад, хомӯшона мегузарад (бе ошкор кардани мавҷудияти логин).
  Future<void> resetPasswordByLogin(String login) async {
    final email = await _emailForLogin(login);
    if (email == null) return;
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<AppUser> _fetchAppUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw const AuthFailure('err_profile_missing');
    }
    final user = AppUser.fromMap(uid, doc.data()!);
    if (!user.active) {
      throw const AuthFailure('err_account_disabled');
    }
    return user;
  }

  Future<AppUser?> currentAppUser() async {
    final u = currentUser;
    if (u == null) return null;
    return _fetchAppUser(u.uid);
  }

  Future<void> saveLanguage(String uid, String code) {
    return _db.collection('users').doc(uid).update({'uiLang': code});
  }
}
