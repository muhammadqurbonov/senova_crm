import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/industries.dart';
import '../../core/industries_data.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../models/org_config.dart';
import '../../models/organization_model.dart';
import '../../models/user_model.dart';
import '../../services/audit_service.dart';
import '../../services/organization_service.dart';

/// Super Admin: танзими пурраи ширкат — соҳа, тариф, модулҳо, номҳо, майдонҳои иловагӣ, мессенҷерҳо.
class OrgEditorDialog extends StatefulWidget {
  final Organization org;
  final AppUser me;
  const OrgEditorDialog({super.key, required this.org, required this.me});

  @override
  State<OrgEditorDialog> createState() => _OrgEditorDialogState();
}

class _OrgEditorDialogState extends State<OrgEditorDialog> {
  late String _industry;
  late String _plan;
  late Set<String> _modules;
  late List<CustomFieldDef> _customerFields;
  late List<CustomFieldDef> _itemFields;
  late final TextEditingController _lblCustomers;
  late final TextEditingController _lblItems;
  late final TextEditingController _lblDeals;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.org.config;
    _industry = kIndustries.containsKey(c.industry) ? c.industry : 'generic';
    _plan = kPlans.contains(widget.org.plan) ? widget.org.plan : 'free';
    _modules = {...c.modules};
    _customerFields = [...c.customerFields];
    _itemFields = [...c.itemFields];
    _lblCustomers = TextEditingController(text: c.labels['customers'] ?? '');
    _lblItems = TextEditingController(text: c.labels['items'] ?? '');
    _lblDeals = TextEditingController(text: c.labels['deals'] ?? '');
  }

  @override
  void dispose() {
    _lblCustomers.dispose();
    _lblItems.dispose();
    _lblDeals.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final labels = <String, String>{
        if (_lblCustomers.text.trim().isNotEmpty) 'customers': _lblCustomers.text.trim(),
        if (_lblItems.text.trim().isNotEmpty) 'items': _lblItems.text.trim(),
        if (_lblDeals.text.trim().isNotEmpty) 'deals': _lblDeals.text.trim(),
      };
      final cfg = OrgConfig(
        industry: _industry,
        modules: OrgConfig.allModules.where(_modules.contains).toList(),
        labels: labels,
        customerFields: _customerFields,
        itemFields: _itemFields,
      );
      await OrganizationService().updateConfig(widget.org.id, {...cfg.toUpdate(), 'plan': _plan});
      AuditService(widget.org.id).log(widget.me, 'org.config', targetType: 'organization', targetId: widget.org.id, details: '${widget.org.name}: $_industry/$_plan');
      if (!mounted) return;
      showSnack(context, context.tr('org_saved'));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.tr(errorKeyFor(e));
        });
      }
    }
  }

  void _addField(bool customer) {
    final labelCtrl = TextEditingController();
    final optCtrl = TextEditingController();
    String type = 'text';
    bool required = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(ctx.tr('add_field'), style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: labelCtrl, decoration: InputDecoration(labelText: ctx.tr('field_label'))),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(labelText: ctx.tr('field_type')),
                  items: [for (final t in CustomFieldDef.types) DropdownMenuItem(value: t, child: Text(ctx.tr('type_$t')))],
                  onChanged: (v) => setLocal(() => type = v ?? 'text'),
                ),
                if (type == 'select') ...[
                  const SizedBox(height: 10),
                  TextField(controller: optCtrl, decoration: InputDecoration(labelText: ctx.tr('field_options'))),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: Text(ctx.tr('field_required'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                  Switch(value: required, onChanged: (v) => setLocal(() => required = v)),
                ]),
                if (error != null) Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('cancel'))),
            FilledButton(
              onPressed: () {
                final options = [for (final o in optCtrl.text.split(',')) if (o.trim().isNotEmpty) o.trim()];
                if (labelCtrl.text.trim().isEmpty || (type == 'select' && options.isEmpty)) {
                  setLocal(() => error = ctx.tr('err_field_label'));
                  return;
                }
                final def = CustomFieldDef(
                  id: 'f_${DateTime.now().millisecondsSinceEpoch}',
                  label: labelCtrl.text.trim(),
                  type: type,
                  options: type == 'select' ? options : const [],
                  required: required,
                );
                setState(() => customer ? _customerFields.add(def) : _itemFields.add(def));
                Navigator.pop(ctx);
              },
              child: Text(ctx.tr('add')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldsSection(String titleKey, List<CustomFieldDef> list, bool customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(context.tr(titleKey), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
          TextButton.icon(onPressed: () => _addField(customer), icon: const Icon(Icons.add, size: 16), label: Text(context.tr('add_field'))),
        ]),
        if (list.isEmpty) Text(context.tr('no_fields'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        for (final f in list)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(child: Text('${f.label} · ${context.tr('type_${f.type}')}${f.required ? ' *' : ''}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5))),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                onPressed: () => setState(() => list.remove(f)),
              ),
            ]),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('${context.tr('edit_org')}: ${widget.org.name}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 17)),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _industry,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                decoration: InputDecoration(labelText: context.tr('industry')),
                items: [for (final id in kIndustryOrder) DropdownMenuItem(value: id, child: Text(presetOf(id).name(lang)))],
                onChanged: (v) => setState(() => _industry = v ?? _industry),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _plan,
                dropdownColor: AppColors.surface,
                decoration: InputDecoration(labelText: context.tr('plan_label')),
                items: [for (final p in kPlans) DropdownMenuItem(value: p, child: Text(p))],
                onChanged: (v) => setState(() => _plan = v ?? _plan),
              ),
              const SizedBox(height: 14),
              Text(context.tr('modules'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              for (final m in OrgConfig.allModules)
                Row(children: [
                  Expanded(child: Text(context.tr('module_$m'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                  Switch(value: _modules.contains(m), onChanged: (v) => setState(() => v ? _modules.add(m) : _modules.remove(m))),
                ]),
              const SizedBox(height: 10),
              Text(context.tr('custom_names'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(controller: _lblCustomers, decoration: InputDecoration(labelText: context.tr('custom_name_customers'))),
              const SizedBox(height: 8),
              TextField(controller: _lblItems, decoration: InputDecoration(labelText: context.tr('custom_name_items'))),
              const SizedBox(height: 8),
              TextField(controller: _lblDeals, decoration: InputDecoration(labelText: context.tr('custom_name_deals'))),
              const SizedBox(height: 16),
              _fieldsSection('fields_customer', _customerFields, true),
              const SizedBox(height: 8),
              _fieldsSection('fields_item', _itemFields, false),
              const Divider(color: AppColors.border, height: 28),
              Text(context.tr('integrations'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(context.tr('int_note_server'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
              const SizedBox(height: 8),
              for (final ch in kChannels) _ChannelCard(orgId: widget.org.id, channel: ch, status: widget.org.config.integrations[ch]),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: Text(context.tr('cancel'))),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary)) : Text(context.tr('save')),
        ),
      ],
    );
  }
}

/// Пайвасти як канал: токен ба Cloud Function фиристода мешавад (дар Firestore-и клиент нигоҳ дошта намешавад).
class _ChannelCard extends StatefulWidget {
  final String orgId;
  final String channel;
  final Map<String, dynamic>? status;
  const _ChannelCard({required this.orgId, required this.channel, required this.status});

  @override
  State<_ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<_ChannelCard> {
  final _id = TextEditingController();
  final _token = TextEditingController();
  bool _busy = false;
  String? _msg;
  bool _ok = false;

  @override
  void dispose() {
    _id.dispose();
    _token.dispose();
    super.dispose();
  }

  String get _idLabelKey {
    switch (widget.channel) {
      case 'whatsapp':
        return 'int_wa_phone_id';
      case 'instagram':
        return 'int_ig_id';
      default:
        return 'int_fb_page_id';
    }
  }

  Future<void> _connect() async {
    final token = _token.text.trim();
    final ext = _id.text.trim();
    final tg = widget.channel == 'telegram';
    if (token.isEmpty || (!tg && ext.isEmpty)) {
      setState(() {
        _ok = false;
        _msg = context.tr('err_fill_fields');
      });
      return;
    }
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final fn = FirebaseFunctions.instance.httpsCallable(tg ? 'connectTelegram' : 'connectMeta');
      await fn.call(tg
          ? {'orgId': widget.orgId, 'botToken': token}
          : {'orgId': widget.orgId, 'channel': widget.channel, 'externalId': ext, 'accessToken': token});
      _token.clear();
      _id.clear();
      if (mounted) {
        setState(() {
          _busy = false;
          _ok = true;
          _msg = context.tr('int_connected_ok');
        });
      }
    } on FirebaseFunctionsException catch (e) {
      final unavailable = e.code == 'not-found' || e.code == 'unavailable' || e.code == 'internal';
      if (mounted) {
        setState(() {
          _busy = false;
          _ok = false;
          _msg = unavailable ? context.tr('err_functions_unavailable') : (e.message ?? context.tr('err_generic'));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _ok = false;
          _msg = context.tr('err_generic');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = widget.status?['status'] == 'connected';
    final label = '${widget.status?['label'] ?? ''}';
    final tg = widget.channel == 'telegram';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: connected ? AppColors.accent : AppColors.border, width: 0.6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(context.tr('int_${widget.channel}'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
            Text(connected ? '${context.tr('int_status_connected')}${label.isEmpty ? '' : ' · $label'}' : context.tr('int_status_not_connected'),
                style: TextStyle(color: connected ? AppColors.accent : AppColors.textSecondary, fontSize: 11.5)),
          ]),
          const SizedBox(height: 8),
          if (!tg) ...[
            TextField(controller: _id, decoration: InputDecoration(labelText: context.tr(_idLabelKey), isDense: true)),
            const SizedBox(height: 8),
          ],
          TextField(controller: _token, obscureText: true, decoration: InputDecoration(labelText: context.tr(tg ? 'int_telegram_token' : 'int_access_token'), isDense: true)),
          const SizedBox(height: 8),
          Row(children: [
            FilledButton(onPressed: _busy ? null : _connect, child: _busy ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary)) : Text(context.tr('int_connect'))),
            const SizedBox(width: 10),
            if (_msg != null) Expanded(child: Text(_msg!, style: TextStyle(color: _ok ? AppColors.accent : AppColors.danger, fontSize: 11.5))),
          ]),
        ],
      ),
    );
  }
}
