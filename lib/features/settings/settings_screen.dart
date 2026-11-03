import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../models/organization_model.dart';
import '../../models/pipeline_stage_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants.dart';
import '../../services/audit_service.dart';
import '../../core/industries.dart';
import '../../core/industries_data.dart';
import '../../providers/org_config_provider.dart';
import 'org_editor_dialog.dart';
import '../../services/employee_service.dart';
import '../../services/organization_service.dart';
import '../../services/pipeline_stage_service.dart';

final RegExp _loginRe = RegExp(r'^[a-z0-9._-]{3,30}$');
final RegExp _keyRe = RegExp(r'^[a-z0-9_]{2,40}$');
final RegExp _colorRe = RegExp(r'^#[0-9A-Fa-f]{6}$');
const int _minPasswordLength = 8;

bool _validEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    if (me == null) return const SizedBox();

    final entries = <MapEntry<String, Widget>>[
      if (Permissions.canConfigureStages(me)) const MapEntry('tab_stages', _StagesTab()),
      if (Permissions.canManageEmployees(me)) const MapEntry('tab_employees', _EmployeesTab()),
      if (Permissions.canViewAudit(me)) const MapEntry('tab_audit', _AuditTab()),
      if (Permissions.canViewIntegrations(me)) const MapEntry('tab_integrations', _IntegrationsTab()),
      if (Permissions.canManageOrganizations(me)) const MapEntry('tab_organizations', _OrganizationsTab()),
    ];

    if (entries.isEmpty) {
      return SafeArea(child: EmptyView(message: context.tr('no_access'), icon: Icons.lock_outline));
    }

    return SafeArea(
      child: DefaultTabController(
        length: entries.length,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('settings_title'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primaryLight,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [for (final e in entries) Tab(text: context.tr(e.key))],
              ),
              Expanded(child: TabBarView(children: [for (final e in entries) e.value])),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _card({required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border, width: 0.5)),
    child: child,
  );
}

// ───────────────────────────── Stages ─────────────────────────────

class _StagesTab extends StatefulWidget {
  const _StagesTab();

  @override
  State<_StagesTab> createState() => _StagesTabState();
}

class _StagesTabState extends State<_StagesTab> {
  AppUser? _me;
  PipelineStageService? _service;
  Stream<List<PipelineStage>>? _stream;

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthProvider>().user;
    if (me != null) {
      _me = me;
      _service = PipelineStageService(me.orgId);
      _stream = _service!.watchAll();
    }
  }

  Future<void> _delete(PipelineStage s) async {
    final me = _me!;
    if (s.isSystem) {
      showSnack(context, context.tr('err_system_stage'), error: true);
      return;
    }
    if (!await confirmDelete(context, s.name(context.lang))) return;
    try {
      await _service!.delete(s.id);
      AuditService(me.orgId).log(me, 'stage.delete', targetType: 'stage', targetId: s.id, details: s.key);
    } catch (e) {
      if (mounted) showSnack(context, context.tr(errorKeyFor(e)), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_me == null) return const SizedBox();
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _showEditDialog(),
            icon: const Icon(Icons.add, size: 16),
            label: Text(context.tr('new_stage')),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<PipelineStage>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(error: snap.error);
              if (!snap.hasData) return const LoadingView();
              final stages = snap.data!;
              if (stages.isEmpty) return EmptyView(message: context.tr('no_stages'));
              return ListView.builder(
                itemCount: stages.length,
                itemBuilder: (context, i) {
                  final s = stages[i];
                  return _card(
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.fromHex(s.color), shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Text('${s.name(context.lang)} (${s.order}) · ${s.key}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                        IconButton(icon: const Icon(Icons.edit, size: 16, color: AppColors.textSecondary), onPressed: () => _showEditDialog(existing: s)),
                        IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger), onPressed: () => _delete(s)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditDialog({PipelineStage? existing}) {
    final me = _me!;
    final keyCtrl = TextEditingController(text: existing?.key ?? '');
    final nameTjCtrl = TextEditingController(text: existing?.nameTj ?? '');
    final nameRuCtrl = TextEditingController(text: existing?.nameRu ?? '');
    final nameEnCtrl = TextEditingController(text: existing?.nameEn ?? '');
    final orderCtrl = TextEditingController(text: existing?.order.toString() ?? '0');
    final colorCtrl = TextEditingController(text: existing?.color ?? '#2F80ED');
    String type = existing?.type ?? 'open';
    String? error;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(existing == null ? ctx.tr('new_stage') : ctx.tr('edit'), style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: keyCtrl, enabled: existing == null, decoration: InputDecoration(labelText: ctx.tr('stage_key'))),
                const SizedBox(height: 10),
                TextField(controller: nameRuCtrl, decoration: InputDecoration(labelText: ctx.tr('name_ru'))),
                const SizedBox(height: 10),
                TextField(controller: nameTjCtrl, decoration: InputDecoration(labelText: ctx.tr('name_tj'))),
                const SizedBox(height: 10),
                TextField(controller: nameEnCtrl, decoration: InputDecoration(labelText: ctx.tr('name_en'))),
                const SizedBox(height: 10),
                TextField(controller: orderCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: ctx.tr('order'))),
                const SizedBox(height: 10),
                TextField(controller: colorCtrl, decoration: InputDecoration(labelText: ctx.tr('color_hex'))),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(labelText: ctx.tr('stage_type')),
                  items: [
                    DropdownMenuItem(value: 'open', child: Text(ctx.tr('stage_type_open'))),
                    DropdownMenuItem(value: 'won', child: Text(ctx.tr('stage_type_won'))),
                    DropdownMenuItem(value: 'lost', child: Text(ctx.tr('stage_type_lost'))),
                  ],
                  onChanged: (v) => setLocal(() => type = v ?? 'open'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('cancel'))),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final key = keyCtrl.text.trim().toLowerCase();
                      final color = colorCtrl.text.trim();
                      final order = int.tryParse(orderCtrl.text.trim());
                      final hasName = nameTjCtrl.text.trim().isNotEmpty || nameRuCtrl.text.trim().isNotEmpty || nameEnCtrl.text.trim().isNotEmpty;
                      if (existing == null && !_keyRe.hasMatch(key)) {
                        setLocal(() => error = ctx.tr('err_stage_key'));
                        return;
                      }
                      if (!hasName || order == null || !_colorRe.hasMatch(color)) {
                        setLocal(() => error = ctx.tr('err_stage_fields'));
                        return;
                      }
                      setLocal(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        final docId = existing?.id ?? _service!.docIdForKey(key);
                        if (existing == null && await _service!.exists(docId)) {
                          setLocal(() {
                            saving = false;
                            error = ctx.tr('err_stage_exists');
                          });
                          return;
                        }
                        await _service!.save(
                          docId: docId,
                          key: existing?.key ?? key,
                          nameTj: nameTjCtrl.text.trim(),
                          nameRu: nameRuCtrl.text.trim(),
                          nameEn: nameEnCtrl.text.trim(),
                          order: order,
                          color: color,
                          type: type,
                        );
                        AuditService(me.orgId).log(me, existing == null ? 'stage.create' : 'stage.update', targetType: 'stage', targetId: docId, details: existing?.key ?? key);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setLocal(() {
                          saving = false;
                          error = ctx.tr(errorKeyFor(e));
                        });
                      }
                    },
              child: Text(ctx.tr('save')),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Employees ─────────────────────────────

class _EmployeesTab extends StatefulWidget {
  const _EmployeesTab();

  @override
  State<_EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<_EmployeesTab> {
  AppUser? _me;
  EmployeeService? _service;
  Stream<List<AppUser>>? _stream;

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthProvider>().user;
    if (me != null) {
      _me = me;
      _service = EmployeeService(me.orgId);
      _stream = _service!.watchAll();
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showSnack(context, context.tr(errorKeyFor(e)), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    if (me == null) return const SizedBox();
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _showAddEmployeeDialog,
            icon: const Icon(Icons.add, size: 16),
            label: Text(context.tr('new_employee')),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(error: snap.error);
              if (!snap.hasData) return const LoadingView();
              final users = snap.data!;
              if (users.isEmpty) return EmptyView(message: context.tr('no_employees'));
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final u = users[i];
                  final isMe = u.uid == me.uid;
                  return _card(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        SizedBox(
                          width: 220,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.name.isEmpty ? u.login : u.name, style: TextStyle(color: u.active ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13)),
                              Text('${context.tr('login')}: ${u.login} · ${u.email}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        DropdownButton<UserRole>(
                          value: u.role,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          underline: const SizedBox(),
                          items: [
                            for (final r in UserRole.values) DropdownMenuItem(value: r, child: Text(context.tr('role_${r.value}'))),
                          ],
                          onChanged: isMe
                              ? null
                              : (v) {
                                  if (v == null || v == u.role) return;
                                  _run(() async {
                                    await _service!.updateRole(u.uid, v);
                                    AuditService(me.orgId).log(me, 'employee.role', targetType: 'user', targetId: u.uid, details: '${u.role.value} -> ${v.value}');
                                  });
                                },
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(context.tr('active'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            Switch(
                              value: u.active,
                              onChanged: isMe
                                  ? null
                                  : (v) => _run(() async {
                                        await _service!.setActive(u.uid, v);
                                        AuditService(me.orgId).log(me, v ? 'employee.activate' : 'employee.deactivate', targetType: 'user', targetId: u.uid);
                                      }),
                            ),
                          ],
                        ),
                        if (!isMe)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                            onPressed: () async {
                              final label = u.name.isEmpty ? u.login : u.name;
                              if (!await confirmDelete(context, label)) return;
                              await _run(() async {
                                await _service!.deleteEmployee(uid: u.uid, login: u.login);
                                AuditService(me.orgId).log(me, 'employee.delete', targetType: 'user', targetId: u.uid, details: label);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddEmployeeDialog() {
    final me = _me!;
    final nameCtrl = TextEditingController();
    final loginCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    UserRole role = UserRole.manager;
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(ctx.tr('new_employee'), style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: ctx.tr('name'))),
                const SizedBox(height: 10),
                TextField(controller: loginCtrl, decoration: InputDecoration(labelText: ctx.tr('login'), helperText: ctx.tr('login_hint'))),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: ctx.tr('employee_email'))),
                const SizedBox(height: 10),
                TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: ctx.tr('password_min', {'n': '$_minPasswordLength'}))),
                const SizedBox(height: 10),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(labelText: ctx.tr('role')),
                  items: [
                    for (final r in UserRole.values) DropdownMenuItem(value: r, child: Text(ctx.tr('role_${r.value}'))),
                  ],
                  onChanged: (v) => setLocal(() => role = v ?? UserRole.manager),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('cancel'))),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      final login = loginCtrl.text.trim().toLowerCase();
                      if (nameCtrl.text.trim().isEmpty || !_loginRe.hasMatch(login) || !_validEmail(emailCtrl.text) || passCtrl.text.length < _minPasswordLength) {
                        setLocal(() => error = ctx.tr('err_fill_fields'));
                        return;
                      }
                      setLocal(() {
                        loading = true;
                        error = null;
                      });
                      try {
                        await _service!.createEmployee(name: nameCtrl.text.trim(), login: login, realEmail: emailCtrl.text.trim(), password: passCtrl.text, role: role);
                        AuditService(me.orgId).log(me, 'employee.create', targetType: 'user', details: '$login (${role.value})');
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setLocal(() {
                          loading = false;
                          error = ctx.tr(errorKeyFor(e));
                        });
                      }
                    },
              child: loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary)) : Text(ctx.tr('create')),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Audit ─────────────────────────────

class _AuditTab extends StatefulWidget {
  const _AuditTab();

  @override
  State<_AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<_AuditTab> {
  Stream<List<AuditEntry>>? _stream;

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthProvider>().user;
    if (me != null) _stream = AuditService(me.orgId).watchRecent();
  }

  @override
  Widget build(BuildContext context) {
    if (_stream == null) return const SizedBox();
    return StreamBuilder<List<AuditEntry>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) return ErrorView(error: snap.error);
        if (!snap.hasData) return const LoadingView();
        final items = snap.data!;
        if (items.isEmpty) return EmptyView(message: context.tr('no_audit'), icon: Icons.history);
        return ListView.builder(
          padding: const EdgeInsets.only(top: 12),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final a = items[i];
            return _card(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('audit.${a.action}'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        if (a.details.isNotEmpty) Text(a.details, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        Text(a.actorName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(formatDateTime(a.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ───────────────────────────── Organizations (Super Admin) ─────────────────────────────

class _OrganizationsTab extends StatefulWidget {
  const _OrganizationsTab();

  @override
  State<_OrganizationsTab> createState() => _OrganizationsTabState();
}

class _OrganizationsTabState extends State<_OrganizationsTab> {
  AppUser? _me;
  final _service = OrganizationService();
  Stream<List<Organization>>? _stream;

  @override
  void initState() {
    super.initState();
    _me = context.read<AuthProvider>().user;
    _stream = _service.watchAll();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showSnack(context, context.tr(errorKeyFor(e)), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    if (me == null) return const SizedBox();
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _showAddOrgDialog,
            icon: const Icon(Icons.add, size: 16),
            label: Text(context.tr('new_org')),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Organization>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(error: snap.error);
              if (!snap.hasData) return const LoadingView();
              final orgs = snap.data!;
              if (orgs.isEmpty) return EmptyView(message: context.tr('no_orgs'));
              return ListView.builder(
                itemCount: orgs.length,
                itemBuilder: (context, i) {
                  final o = orgs[i];
                  final color = o.isSuspended ? AppColors.warning : AppColors.success;
                  return _card(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                              Text('${context.tr('plan')}: ${o.plan} · ${formatDate(o.createdAt)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(context.tr(o.isSuspended ? 'org_status_suspended' : 'org_status_active'), style: TextStyle(color: color, fontSize: 11)),
                        ),
                        IconButton(
                          tooltip: context.tr('edit_org'),
                          icon: const Icon(Icons.tune, size: 18, color: AppColors.primaryLight),
                          onPressed: () => showDialog(context: context, builder: (_) => OrgEditorDialog(org: o, me: me)),
                        ),
                        TextButton(
                          onPressed: () => _run(() async {
                            final next = o.isSuspended ? OrgStatus.active : OrgStatus.suspended;
                            await _service.setStatus(o.id, next);
                            AuditService(o.id).log(me, next == OrgStatus.suspended ? 'org.suspend' : 'org.activate', targetType: 'organization', targetId: o.id, details: o.name);
                          }),
                          child: Text(context.tr(o.isSuspended ? 'activate' : 'suspend')),
                        ),
                        if (o.isSuspended)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                            onPressed: () async {
                              if (!await confirmDelete(context, o.name)) return;
                              await _run(() async {
                                await _service.deleteOrganization(o.id);
                                AuditService(me.orgId).log(me, 'org.delete', targetType: 'organization', targetId: o.id, details: o.name);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddOrgDialog() {
    final me = _me!;
    final orgNameCtrl = TextEditingController();
    final adminNameCtrl = TextEditingController();
    final loginCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String industry = 'real_estate';
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(ctx.tr('new_org'), style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: orgNameCtrl, decoration: InputDecoration(labelText: ctx.tr('org_name'))),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: industry,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(labelText: ctx.tr('industry')),
                  items: [for (final id in kIndustryOrder) DropdownMenuItem(value: id, child: Text(presetOf(id).name(ctx.lang)))],
                  onChanged: (v) => setLocal(() => industry = v ?? industry),
                ),
                const Divider(color: AppColors.border, height: 24),
                Align(alignment: Alignment.centerLeft, child: Text(ctx.tr('first_admin'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                const SizedBox(height: 8),
                TextField(controller: adminNameCtrl, decoration: InputDecoration(labelText: ctx.tr('name'))),
                const SizedBox(height: 10),
                TextField(controller: loginCtrl, decoration: InputDecoration(labelText: ctx.tr('login'), helperText: ctx.tr('login_hint'))),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: ctx.tr('real_email'))),
                const SizedBox(height: 10),
                TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: ctx.tr('password_min', {'n': '$_minPasswordLength'}))),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('cancel'))),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      final login = loginCtrl.text.trim().toLowerCase();
                      if (orgNameCtrl.text.trim().isEmpty || adminNameCtrl.text.trim().isEmpty || !_loginRe.hasMatch(login) || !_validEmail(emailCtrl.text) || passCtrl.text.length < _minPasswordLength) {
                        setLocal(() => error = ctx.tr('err_fill_fields'));
                        return;
                      }
                      setLocal(() {
                        loading = true;
                        error = null;
                      });
                      try {
                        final orgId = await _service.createOrganization(
                          orgName: orgNameCtrl.text.trim(),
                          adminName: adminNameCtrl.text.trim(),
                          adminLogin: login,
                          adminEmail: emailCtrl.text.trim(),
                          adminPassword: passCtrl.text,
                          industry: industry,
                        );
                        AuditService(orgId).log(me, 'org.create', targetType: 'organization', targetId: orgId, details: orgNameCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setLocal(() {
                          loading = false;
                          error = ctx.tr(errorKeyFor(e));
                        });
                      }
                    },
              child: loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary)) : Text(ctx.tr('create')),
            ),
          ],
        ),
      ),
    );
  }
}


// ───────────────────────────── Integrations (admin, read-only) ─────────────────────────────

class _IntegrationsTab extends StatelessWidget {
  const _IntegrationsTab();

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<OrgConfigProvider>().config;
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: [
        Text(context.tr('int_admin_hint'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 12),
        for (final ch in kChannels)
          _card(
            child: Row(
              children: [
                Expanded(child: Text(context.tr('int_$ch'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                Builder(builder: (context) {
                  final st = cfg.integrations[ch];
                  final ok = st?['status'] == 'connected';
                  return Text(
                    ok ? '${context.tr('int_status_connected')}${st?['label'] == null ? '' : ' · ${st?['label']}'}' : context.tr('int_status_not_connected'),
                    style: TextStyle(color: ok ? AppColors.accent : AppColors.textSecondary, fontSize: 12),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
