import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/l10n/app_lang.dart';
import '../core/permissions.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/common.dart';
import '../core/widgets/responsive_scaffold.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/customers/customers_kanban_screen.dart';
import '../features/properties/properties_screen.dart';
import '../features/deals/deals_screen.dart';
import '../features/tasks/tasks_screen.dart';
import '../features/settings/settings_screen.dart';
import '../models/organization_model.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/organization_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _showSettings = false;
  Stream<Organization?>? _orgStream;

  static const _screens = [
    DashboardScreen(),
    CustomersKanbanScreen(),
    PropertiesScreen(),
    DealsScreen(),
    TasksScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null && user.orgId.isNotEmpty) {
      _orgStream = OrganizationService().watchOne(user.orgId);
    }
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

    final shell = ResponsiveScaffold(
      selectedIndex: _index,
      onSelect: (i) => setState(() {
        _index = i;
        _showSettings = false;
      }),
      onSettingsTap: () => setState(() => _showSettings = true),
      onLogout: () => context.read<AuthProvider>().logout(),
      userName: user.name,
      showSettings: Permissions.canAccessSettings(user),
      settingsSelected: _showSettings,
      child: _showSettings ? const SettingsScreen() : _screens[_index],
    );

    final stream = _orgStream;
    if (stream == null || user.isSuperAdmin) return shell;

    return StreamBuilder<Organization?>(
      stream: stream,
      builder: (context, snap) {
        final org = snap.data;
        if (org != null && org.isSuspended) {
          return _SuspendedView(orgName: org.name);
        }
        return shell;
      },
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
