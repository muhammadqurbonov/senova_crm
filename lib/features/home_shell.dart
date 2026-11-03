import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/l10n/app_lang.dart';
import '../core/permissions.dart';
import '../core/theme/app_colors.dart';
import '../core/industries.dart';
import '../core/industries_data.dart';
import '../core/widgets/common.dart';
import '../core/widgets/responsive_scaffold.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/customers/customers_kanban_screen.dart';
import '../features/properties/properties_screen.dart';
import '../features/deals/deals_screen.dart';
import '../features/tasks/tasks_screen.dart';
import '../features/settings/settings_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/org_config_provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    // Забони интихобкардаи корбар (агар бошад); вагарна пешфарз — русӣ.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lang = context.read<AuthProvider>().user?.uiLang;
      if (lang != null) context.read<LocaleProvider>().setLanguage(lang);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox();
    final cfgProvider = context.watch<OrgConfigProvider>();
    final cfg = cfgProvider.config;

    // Навигатсия аз рӯи модулҳои фаъоли ширкат сохта мешавад.
    final entries = <MapEntry<NavItem, Widget>>[
      const MapEntry(NavItem(icon: Icons.dashboard_outlined, labelKey: 'nav_dashboard'), DashboardScreen()),
      const MapEntry(NavItem(icon: Icons.people_outline, labelKey: 'nav_customers'), CustomersKanbanScreen()),
      if (cfg.hasModule('items')) MapEntry(NavItem(icon: presetOf(cfg.industry).icon, labelKey: 'nav_properties'), const PropertiesScreen()),
      if (cfg.hasModule('deals')) const MapEntry(NavItem(icon: Icons.handshake_outlined, labelKey: 'nav_deals'), DealsScreen()),
      if (cfg.hasModule('tasks')) const MapEntry(NavItem(icon: Icons.check_circle_outline, labelKey: 'nav_tasks'), TasksScreen()),
    ];
    final idx = _index >= entries.length ? 0 : _index;
    final screen = _showSettings ? const SettingsScreen() : entries[idx].value;

    Widget body = Column(
      children: [
        if (user.isDemo) _DemoBanner(industry: cfg.industry),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.015, 0), end: Offset.zero).animate(anim), child: child),
            ),
            child: KeyedSubtree(key: ValueKey('${_showSettings ? 's' : idx}-${cfg.industry}'), child: screen),
          ),
        ),
      ],
    );

    final shell = ResponsiveScaffold(
      items: [for (final e in entries) e.key],
      selectedIndex: idx,
      onSelect: (i) => setState(() {
        _index = i;
        _showSettings = false;
      }),
      onSettingsTap: () => setState(() => _showSettings = true),
      onLogout: () => context.read<AuthProvider>().logout(),
      userName: user.isDemo ? context.tr('demo_title') : user.name,
      showSettings: Permissions.canAccessSettings(user),
      settingsSelected: _showSettings,
      child: body,
    );

    final org = cfgProvider.org;
    if (!user.isSuperAdmin && org != null && org.isSuspended) {
      return _SuspendedView(orgName: org.name);
    }
    return shell;
  }
}

class _DemoBanner extends StatelessWidget {
  final String industry;
  const _DemoBanner({required this.industry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: SafeArea(
        bottom: false,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            const Icon(Icons.visibility_outlined, size: 16, color: Colors.white),
            Text(context.tr('demo_banner'), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500)),
            PopupMenuButton<String>(
              tooltip: context.tr('demo_switch'),
              color: AppColors.surface,
              onSelected: (id) => context.read<AuthProvider>().enterDemo(id),
              itemBuilder: (_) => [
                for (final id in kIndustryOrder)
                  PopupMenuItem<String>(
                    value: id,
                    child: Row(children: [
                      Icon(presetOf(id).icon, size: 18, color: AppColors.primaryLight),
                      const SizedBox(width: 10),
                      Text(presetOf(id).name(context.lang), style: const TextStyle(color: AppColors.textPrimary)),
                    ]),
                  ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(presetOf(industry).icon, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('${presetOf(industry).name(context.lang)} ▾', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ),
            InkWell(
              onTap: () => context.read<AuthProvider>().logout(),
              child: Text(context.tr('demo_exit'), style: const TextStyle(color: Colors.white, fontSize: 12, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuspendedView extends StatelessWidget {
  final String orgName;
  const _SuspendedView({required this.orgName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 48),
                const SizedBox(height: 20),
                const Icon(Icons.pause_circle_outline, size: 40, color: AppColors.warning),
                const SizedBox(height: 12),
                Text(context.tr('org_suspended_title'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(context.tr('org_suspended_body', {'name': orgName}), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                OutlinedButton(onPressed: () => context.read<AuthProvider>().logout(), child: Text(context.tr('logout'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
