import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/org_config.dart';
import '../channels.dart';
import '../l10n/app_lang.dart';
import '../theme/app_colors.dart';
import 'common.dart';

String channelName(BuildContext context, ChannelType t) => t.nameKey != null ? context.tr(t.nameKey!) : t.name;

Future<void> openLink(BuildContext context, String? url) async {
  final uri = url == null ? null : Uri.tryParse(url);
  var ok = false;
  if (uri != null) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
  }
  if (!ok && context.mounted) showSnack(context, context.tr('err_open_link'), error: true);
}

/// Сатри як контакти ширкат: нишон, ном, арзиш ва тугмаи кушодан.
class ChannelRow extends StatelessWidget {
  final ChannelContact contact;
  final Widget? trailing;
  const ChannelRow({super.key, required this.contact, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = channelTypeOf(contact.type);
    final url = channelUrl(contact.type, contact.value);
    final title = contact.label.isNotEmpty ? contact.label : channelName(context, t);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Row(
        children: [
          CircleAvatar(radius: 15, backgroundColor: t.color.withValues(alpha: 0.18), child: Icon(t.icon, size: 16, color: t.color)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                Text(contact.value, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('open_link'),
            icon: Icon(Icons.open_in_new, size: 17, color: url == null ? AppColors.border : AppColors.primaryLight),
            onPressed: url == null ? null : () => openLink(context, url),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Тугмаҳои зуд барои тамос бо мизоҷ: занг + мессенҷерҳое, ки ширкат дорад (пешфарз: WhatsApp, Telegram).
class QuickContactBar extends StatelessWidget {
  final String phone;
  final List<ChannelContact> companyChannels;
  const QuickContactBar({super.key, required this.phone, required this.companyChannels});

  @override
  Widget build(BuildContext context) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7) return const SizedBox.shrink();

    final enabled = companyChannels.isEmpty ? {'whatsapp', 'telegram'} : companyChannels.map((c) => c.type).toSet();
    final types = <ChannelType>[
      channelTypeOf('phone'),
      for (final t in kContactTypes)
        if (t.phoneCapable && enabled.contains(t.id)) t,
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(context.tr('quick_contact'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          for (final t in types)
            Tooltip(
              message: channelName(context, t),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => openLink(context, channelUrl(t.id, phone)),
                child: CircleAvatar(radius: 15, backgroundColor: t.color.withValues(alpha: 0.18), child: Icon(t.icon, size: 16, color: t.color)),
              ),
            ),
        ],
      ),
    );
  }
}
