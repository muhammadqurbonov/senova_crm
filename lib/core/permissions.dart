import '../models/user_model.dart';

/// Ҷои ягонаи санҷиши ҳуқуқҳо дар UI.
/// МУҲИМ: ин танҳо барои намоиши UI аст. Амнияти воқеӣ — Firestore Security Rules (firestore.rules),
/// ки бояд бо ин ҷадвал мутобиқ бошад.
class Permissions {
  Permissions._();

  static bool canWrite(AppUser u) => u.active && (u.role == UserRole.admin || u.role == UserRole.manager);
  static bool canClaimLeads(AppUser u) => canWrite(u);
  static bool canDelete(AppUser u) => u.active && u.role == UserRole.admin;
  static bool canManageEmployees(AppUser u) => u.active && u.role == UserRole.admin;
  static bool canConfigureStages(AppUser u) => u.active && u.role == UserRole.admin;
  static bool canViewAudit(AppUser u) => u.active && u.role == UserRole.admin;
  static bool canManageOrganizations(AppUser u) => u.active && u.isSuperAdmin;

  static bool canAccessSettings(AppUser u) =>
      canConfigureStages(u) || canManageEmployees(u) || canViewAudit(u) || canManageOrganizations(u);
}
