import 'dart:async';
import 'package:flutter/material.dart';
import '../core/errors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription? _sub;

  AppUser? _user;
  AuthStatus _status = AuthStatus.unknown;
  String? _error; // калиди тарҷума (err_*)
  bool _loading = false;
  bool _loggingIn = false;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get loading => _loading;

  AuthProvider() {
    _sub = _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        if (_user?.isDemo == true) return; // демо ба Firebase вобаста нест
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      // Ҳангоми login() профил худи он ҷо бор мешавад — такрор нахонем.
      if (_loggingIn || _user?.uid == firebaseUser.uid) {
        return;
      }
      try {
        _user = await _authService.currentAppUser();
        _status = _user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
      } catch (e) {
        _user = null;
        _error = errorKeyFor(e);
        _status = AuthStatus.unauthenticated;
        try {
          await _authService.logout();
        } catch (_) {}
      }
      notifyListeners();
    });
  }

  Future<void> login(String username, String password) async {
    _loading = true;
    _loggingIn = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.loginWithUsername(username, password);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _user = null;
      _error = errorKeyFor(e);
      _status = AuthStatus.unauthenticated;
    } finally {
      _loggingIn = false;
      _loading = false;
      notifyListeners();
    }
  }

  /// Ҳолати демо: бе вуруд, танҳо дидан, маълумоти хаёлӣ (аз Firestore хонда намешавад).
  void enterDemo(String industry) {
    _error = null;
    _user = AppUser.demo(industry);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> resetPassword(String login) => _authService.resetPasswordByLogin(login);

  Future<void> logout() async {
    _user = null; // дарҳол: экранҳо ва listener-ҳои ширкати қаблӣ пӯшида мешаванд
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    try {
      await _authService.logout();
    } catch (_) {}
  }

  /// Забони интихобшударо дар профил нигоҳ медорад (агар корбар даромада бошад).
  Future<void> saveLanguage(String code) async {
    final u = _user;
    if (u == null || u.isDemo) return;
    try {
      await _authService.saveLanguage(u.uid, code);
    } catch (_) {
      // Забон дар хотира тағйир ёфт; нигоҳ доштан муваффақ нашуд — муҳим нест.
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
