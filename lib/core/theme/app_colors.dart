import 'package:flutter/material.dart';

/// Токенҳои ранги Senova CRM — торик + кабуд (асосӣ) + сабз (акцент).
class AppColors {
  AppColors._();

  // Заминаҳо
  static const Color background = Color(0xFF0A1220);
  static const Color surface = Color(0xFF101B2D);
  static const Color surfaceLight = Color(0xFF16253B);
  static const Color border = Color(0xFF223450);

  // Кабуд (асосӣ)
  static const Color primary = Color(0xFF2F80ED);
  static const Color primaryLight = Color(0xFF63A4FF);
  static const Color primaryDark = Color(0xFF1B5FBF);

  // Сабз (акцент)
  static const Color accent = Color(0xFF22C55E);
  static const Color accentDark = Color(0xFF15803D);

  // Матн
  static const Color textPrimary = Color(0xFFEAF1FB);
  static const Color textSecondary = Color(0xFF8FA3BF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Статус
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF5350);
  static const Color warning = Color(0xFFF5A524);

  // Манбаъҳо
  static const Color whatsapp = Color(0xFF4CAF50);
  static const Color instagram = Color(0xFFC13584);
  static const Color telegram = Color(0xFF2AABEE);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  /// '#RRGGBB' -> Color. Ҳангоми хатои формат — [fallback] (барнома намеафтад).
  static Color fromHex(String hex, {Color fallback = primary}) {
    final h = hex.replaceFirst('#', '').trim();
    if (h.length != 6) return fallback;
    final v = int.tryParse(h, radix: 16);
    if (v == null) return fallback;
    return Color(0xFF000000 | v);
  }
}
