import 'package:firebase_auth/firebase_auth.dart';

/// Хатои бизнес/аутентификатсия. [code] — калиди тарҷума (err_*).
class AuthFailure implements Exception {
  final String code;
  const AuthFailure(this.code);

  @override
  String toString() => 'AuthFailure($code)';
}

/// Хатои ихтиёриро ба калиди тарҷума табдил медиҳад (бе ошкор кардани тафсилоти дохилӣ).
String errorKeyFor(Object? e) {
  if (e is AuthFailure) return e.code;
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
      case 'invalid-email':
        return 'err_invalid_credentials';
      case 'email-already-in-use':
        return 'err_email_in_use';
      case 'weak-password':
        return 'err_weak_password';
      case 'too-many-requests':
        return 'err_too_many_requests';
      case 'network-request-failed':
        return 'err_network';
      case 'user-disabled':
        return 'err_account_disabled';
    }
    return 'err_generic';
  }
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') return 'err_permission_denied';
    if (e.code == 'unavailable') return 'err_network';
  }
  return 'err_generic';
}
