import 'package:flutter/material.dart';

/// Намуди канали алоқа/мессенҷер. Номи брендҳо тарҷума намешавад; [nameKey] — барои намудҳои умумӣ.
class ChannelType {
  final String id;
  final String name;
  final String? nameKey;
  final IconData icon;
  final Color color;

  /// Метавонад бо рақами телефони мизоҷ кушода шавад (чат).
  final bool phoneCapable;

  const ChannelType(this.id, this.name, this.icon, this.color, {this.nameKey, this.phoneCapable = false});
}

const List<ChannelType> kContactTypes = [
  ChannelType('telegram', 'Telegram', Icons.send, Color(0xFF2AABEE), phoneCapable: true),
  ChannelType('whatsapp', 'WhatsApp', Icons.chat, Color(0xFF25D366), phoneCapable: true),
  ChannelType('instagram', 'Instagram', Icons.camera_alt_outlined, Color(0xFFC13584)),
  ChannelType('facebook', 'Facebook', Icons.public, Color(0xFF1877F2)),
  ChannelType('viber', 'Viber', Icons.phone_in_talk, Color(0xFF7360F2), phoneCapable: true),
  ChannelType('tiktok', 'TikTok', Icons.music_note, Color(0xFFEAF1FB)),
  ChannelType('vk', 'VK', Icons.group_outlined, Color(0xFF4C75A3)),
  ChannelType('youtube', 'YouTube', Icons.smart_display_outlined, Color(0xFFFF0000)),
  ChannelType('website', '', Icons.language, Color(0xFF63A4FF), nameKey: 'ch_website'),
  ChannelType('email', '', Icons.email_outlined, Color(0xFF63A4FF), nameKey: 'ch_email'),
  ChannelType('phone', '', Icons.phone_outlined, Color(0xFF22C55E), nameKey: 'ch_phone'),
  ChannelType('other', '', Icons.link, Color(0xFF8FA3BF), nameKey: 'ch_other'),
];

ChannelType channelTypeOf(String id) {
  for (final t in kContactTypes) {
    if (t.id == id) return t;
  }
  return kContactTypes.last;
}

final RegExp _handleRe = RegExp(r'^[\w.\-/]+$');
final RegExp _phoneLikeRe = RegExp(r'^\+?[\d\s()\-]{7,}$');
final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Логин / рақам / истинодро ба истиноди кушодашаванда табдил медиҳад. Агар дуруст набошад — null.
String? channelUrl(String type, String value) {
  final v = value.trim();
  if (v.isEmpty) return null;

  // Истиноди пурра (бо схема): танҳо схемаҳои бехатар.
  if (v.contains('://') || v.startsWith('mailto:') || v.startsWith('tel:')) {
    final uri = Uri.tryParse(v);
    if (uri == null) return null;
    const ok = {'http', 'https', 'mailto', 'tel', 'tg', 'viber'};
    return ok.contains(uri.scheme.toLowerCase()) ? v : null;
  }

  final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
  final handle = v.replaceFirst(RegExp(r'^@'), '');
  final handleOk = _handleRe.hasMatch(handle);

  switch (type) {
    case 'telegram':
      if (_phoneLikeRe.hasMatch(v)) return digits.length >= 7 ? 'https://t.me/+$digits' : null;
      return handleOk ? 'https://t.me/$handle' : null;
    case 'whatsapp':
      return digits.length >= 7 ? 'https://wa.me/$digits' : null;
    case 'instagram':
      return handleOk ? 'https://instagram.com/$handle' : null;
    case 'facebook':
      return handleOk ? 'https://facebook.com/$handle' : null;
    case 'viber':
      return digits.length >= 7 ? 'viber://chat?number=%2B$digits' : null;
    case 'tiktok':
      return handleOk ? 'https://www.tiktok.com/@$handle' : null;
    case 'vk':
      return handleOk ? 'https://vk.com/$handle' : null;
    case 'youtube':
      if (handle.contains('.')) return handleOk ? 'https://$handle' : null;
      return handleOk ? 'https://www.youtube.com/@$handle' : null;
    case 'email':
      return _emailRe.hasMatch(v) ? 'mailto:$v' : null;
    case 'phone':
      final plus = v.startsWith('+') ? '+' : '';
      return digits.length >= 7 ? 'tel:$plus$digits' : null;
    default: // website, other
      return (v.contains('.') && !v.contains(' ')) ? 'https://$v' : null;
  }
}
