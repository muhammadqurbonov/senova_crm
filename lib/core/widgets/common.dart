import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../errors.dart';
import '../l10n/app_lang.dart';
import '../theme/app_colors.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
  }
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final Object? error;
  const ErrorView({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36, color: AppColors.danger),
            const SizedBox(height: 8),
            Text(context.tr(errorKeyFor(error)), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.55)),
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: error ? AppColors.danger : AppColors.surfaceLight),
  );
}

/// Диалоги умумии тасдиқи нест кардан.
Future<bool> confirmDelete(BuildContext context, String itemName) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(ctx.tr('delete_title'), style: const TextStyle(color: AppColors.textPrimary)),
      content: Text(ctx.tr('delete_body', {'name': itemName}), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.tr('delete')),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Интихоби забон (ru / tj / en). Забон дар профили корбар нигоҳ дошта мешавад.
class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});

  static const _labels = {'ru': 'Русский', 'tj': 'Тоҷикӣ', 'en': 'English'};

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LocaleProvider>().code;
    return PopupMenuButton<String>(
      tooltip: context.tr('language'),
      color: AppColors.surface,
      icon: const Icon(Icons.language, size: 20, color: AppColors.textSecondary),
      onSelected: (code) {
        context.read<LocaleProvider>().setLanguage(code);
        context.read<AuthProvider>().saveLanguage(code);
      },
      itemBuilder: (_) => [
        for (final entry in _labels.entries)
          PopupMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              style: TextStyle(
                color: entry.key == current ? AppColors.primaryLight : AppColors.textPrimary,
                fontWeight: entry.key == current ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}
