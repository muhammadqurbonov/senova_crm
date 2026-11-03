import '../core/constants.dart';

enum UserRole { admin, manager, viewer }

extension UserRoleX on UserRole {
  String get value => name;

  /// Номаълум/холӣ => viewer (ҳуқуқи камтарин), то хатои маълумот ҳуқуқи иловагӣ надиҳад.
  static UserRole fromString(String? value) {
    for (final r in UserRole.values) {
      if (r.name == value) return r;
    }
    return UserRole.viewer;
  }
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String login;
  final String orgId;
  final UserRole role;
  final bool isSuperAdmin;
  final String language;

  /// Забони UI, ки худи корбар интихоб кардааст (null => забони пешфарз: русӣ).
  final String? uiLang;
  final bool active;
  final String? fcmToken;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.login = '',
    required this.orgId,
    required this.role,
    this.isSuperAdmin = false,
    this.language = 'ru',
    this.uiLang,
    this.active = true,
    this.fcmToken,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      login: map['login'] ?? '',
      orgId: map['orgId'] ?? '',
      role: UserRoleX.fromString(map['role'] ?? 'manager'),
      isSuperAdmin: map['isSuperAdmin'] ?? false,
      language: map['language'] ?? 'ru',
      uiLang: map['uiLang'] as String?,
      active: map['active'] ?? true,
      fcmToken: map['fcmToken'],
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isDemo => isDemoOrg(orgId);

  /// Корбари демо: танҳо дидан, ба Firestore ворид намешавад.
  factory AppUser.demo(String industry) => AppUser(uid: 'demo', name: 'Demo', email: '', orgId: '$kDemoPrefix$industry', role: UserRole.viewer);
}
