import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Забони UI: ru (пешфарз) | tj | en.
/// Интихоби корбар дар users/{uid}.uiLang нигоҳ дошта мешавад (қ. AuthProvider.saveLanguage).
class LocaleProvider extends ChangeNotifier {
  String _code = 'ru';

  String get code => _code;

  void setLanguage(String langCode) {
    if (!kLanguages.contains(langCode) || langCode == _code) return;
    _code = langCode;
    notifyListeners();
  }
}
