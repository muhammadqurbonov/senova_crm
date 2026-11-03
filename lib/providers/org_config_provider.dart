import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/org_config.dart';
import '../models/organization_model.dart';
import '../models/user_model.dart';
import '../services/organization_service.dart';

/// Танзимоти ширкати корбари ҷорӣ (соҳа, модулҳо, майдонҳо, интегратсияҳо). Ба AppLang ва навигатсия таъсир мерасонад.
class OrgConfigProvider extends ChangeNotifier {
  Organization? _org;
  OrgConfig _config = const OrgConfig();
  String? _boundKey;
  StreamSubscription<Organization?>? _sub;
  bool _disposed = false;

  Organization? get org => _org;
  OrgConfig get config => _config;

  /// Идемпотент: танҳо ҳангоми тағйири ширкат аз нав обуна мешавад.
  void bind(AppUser? user) {
    final key = user == null ? null : user.orgId;
    if (key == _boundKey) return;
    _boundKey = key;
    _sub?.cancel();
    _sub = null;
    _org = null;
    _config = const OrgConfig();

    if (user != null && user.orgId.isNotEmpty) {
      if (user.isDemo) {
        _config = OrgConfig(industry: demoIndustryOf(user.orgId));
        _org = Organization(id: user.orgId, name: 'Demo', createdAt: DateTime.now(), config: _config);
      } else {
        _sub = OrganizationService().watchOne(user.orgId).listen((o) {
          _org = o;
          _config = o?.config ?? const OrgConfig();
          _notify();
        }, onError: (_) {});
      }
    }
    scheduleMicrotask(_notify);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
