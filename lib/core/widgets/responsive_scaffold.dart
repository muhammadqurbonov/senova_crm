import 'package:flutter/material.dart';
import '../l10n/app_lang.dart';
import '../theme/app_colors.dart';
import 'common.dart';

class NavItem {
  final IconData icon;
  final String labelKey;
  const NavItem({required this.icon, required this.labelKey});
}

const navItems = [
  NavItem(icon: Icons.dashboard_outlined, labelKey: 'nav_dashboard'),
  NavItem(icon: Icons.people_outline, labelKey: 'nav_customers'),
  NavItem(icon: Icons.apartment_outlined, labelKey: 'nav_properties'),
  NavItem(icon: Icons.handshake_outlined, labelKey: 'nav_deals'),
  NavItem(icon: Icons.check_circle_outline, labelKey: 'nav_tasks'),
];

const settingsNavItem = NavItem(icon: Icons.settings_outlined, labelKey: 'nav_settings');

/// Layout-и ягона: экрани васеъ (веб/планшет) — sidebar; экрани танг (мобилӣ) — bottom navigation.
class ResponsiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget child;
  final String userName;
  final bool showSettings;
  final bool settingsSelected;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogout;

  const ResponsiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.child,
    required this.userName,
    required this.showSettings,
    required this.settingsSelected,
    required this.onSettingsTap,
    required this.onLogout,
  });

  static const _wideBreakpoint = 800.0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _wideBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              selectedIndex: selectedIndex,
              onSelect: onSelect,
              userName: userName,
              showSettings: showSettings,
              settingsSelected: settingsSelected,
              onSettingsTap: onSettingsTap,
              onLogout: onLogout,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    final destinations = <NavItem>[...navItems, if (showSettings) settingsNavItem];
    final settingsIndex = navItems.length;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        titleSpacing: 16,
        title: Row(
          children: [
            const BrandMark(size: 26),
            const SizedBox(width: 8),
            const Text('Senova CRM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          const LanguageMenu(),
          IconButton(
            tooltip: context.tr('logout'),
            icon: const Icon(Icons.logout, size: 20, color: AppColors.textSecondary),
            onPressed: onLogout,
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        selectedIndex: settingsSelected ? settingsIndex : selectedIndex,
        onDestinationSelected: (i) {
          if (showSettings && i == settingsIndex) {
            onSettingsTap();
          } else {
            onSelect(i);
          }
        },
        destinations: destinations
            .map((e) => NavigationDestination(
                  icon: Icon(e.icon, color: AppColors.textSecondary),
                  selectedIcon: Icon(e.icon, color: AppColors.primaryLight),
                  label: context.tr(e.labelKey),
                ))
            .toList(),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String userName;
  final bool showSettings;
  final bool settingsSelected;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.userName,
    required this.showSettings,
    required this.settingsSelected,
    required this.onSettingsTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                BrandMark(size: 30),
                SizedBox(width: 10),
                Text('Senova CRM', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          for (int i = 0; i < navItems.length; i++)
            _SidebarTile(item: navItems[i], selected: !settingsSelected && i == selectedIndex, onTap: () => onSelect(i)),
          if (showSettings) ...[
            const Divider(color: AppColors.border, height: 32, indent: 20, endIndent: 20),
            _SidebarTile(item: settingsNavItem, selected: settingsSelected, onTap: onSettingsTap),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            child: Row(
              children: [
                const CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 16, color: AppColors.textOnPrimary)),
                const SizedBox(width: 10),
                Expanded(child: Text(userName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                const LanguageMenu(),
                IconButton(
                  tooltip: context.tr('logout'),
                  icon: const Icon(Icons.logout, size: 19, color: AppColors.textSecondary),
                  onPressed: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 19, color: selected ? AppColors.primaryLight : AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(context.tr(item.labelKey), style: TextStyle(color: selected ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}
