import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/custom_fields.dart';
import '../../core/widgets/motion.dart';
import '../../models/customer_model.dart';
import '../../models/pipeline_stage_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/org_config_provider.dart';
import '../../services/audit_service.dart';
import '../../services/customer_service.dart';
import '../../services/pipeline_stage_service.dart';
import 'customer_detail_dialog.dart';

class CustomersKanbanScreen extends StatefulWidget {
  const CustomersKanbanScreen({super.key});

  @override
  State<CustomersKanbanScreen> createState() => _CustomersKanbanScreenState();
}

class _CustomersKanbanScreenState extends State<CustomersKanbanScreen> {
  AppUser? _me;
  CustomerService? _customerService;
  Stream<List<PipelineStage>>? _stagesStream;
  Stream<List<Customer>>? _customersStream;
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _onlyMine = false;

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthProvider>().user;
    if (me != null) {
      _me = me;
      _customerService = CustomerService(me.orgId);
      _stagesStream = PipelineStageService(me.orgId).watchAll();
      _customersStream = _customerService!.watchAll();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Customer> _filter(List<Customer> all, AppUser me) {
    final q = _query.trim().toLowerCase();
    return all.where((c) {
      if (_onlyMine && c.managerId != me.uid) return false;
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _claim(Customer c) async {
    final me = _me!;
    try {
      final ok = await _customerService!.claim(customerId: c.id, managerId: me.uid, managerName: me.name);
      if (!mounted) return;
      if (!ok) showSnack(context, context.tr('claim_failed'), error: true);
    } catch (e) {
      if (mounted) showSnack(context, context.tr(errorKeyFor(e)), error: true);
    }
  }

  Future<void> _delete(Customer c) async {
    final me = _me!;
    final label = c.name.isEmpty ? c.phone : c.name;
    if (!await confirmDelete(context, label)) return;
    try {
      await _customerService!.delete(c.id);
      AuditService(me.orgId).log(me, 'customer.delete', targetType: 'customer', targetId: c.id, details: label);
    } catch (e) {
      if (mounted) showSnack(context, context.tr(errorKeyFor(e)), error: true);
    }
  }

  void _showAddCustomerDialog(String stageKey) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cf = CustomFieldsController(context.read<OrgConfigProvider>().config.customerFields, null);
    String? error;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(ctx.tr('new_customer_manual'), style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: ctx.tr('name'))),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: ctx.tr('phone'))),
                CustomFieldsForm(controller: cf),
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
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      if (name.isEmpty && phone.isEmpty) {
                        setLocal(() => error = ctx.tr('err_name_or_phone'));
                        return;
                      }
                      if (!cf.validate()) {
                        setLocal(() => error = ctx.tr('err_custom_fields'));
                        return;
                      }
                      setLocal(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await _customerService!.create(name: name, phone: phone, stageId: stageKey, custom: cf.collect());
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setLocal(() {
                          saving = false;
                          error = ctx.tr(errorKeyFor(e));
                        });
                      }
                    },
              child: Text(ctx.tr('add')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    if (me == null) return const SizedBox();
    final canWrite = Permissions.canWrite(me);
    final canDelete = Permissions.canDelete(me);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<PipelineStage>>(
            stream: _stagesStream,
            builder: (context, stageSnap) {
              final stages = stageSnap.data ?? const <PipelineStage>[];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Expanded(child: Text(context.tr('kanban_title'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600))),
                    if (canWrite)
                      FilledButton.icon(
                        onPressed: stages.isEmpty ? null : () => _showAddCustomerDialog(stages.first.key),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(context.tr('add')),
                      ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: context.tr('search_customers'),
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilterChip(
                  label: Text(context.tr('only_mine')),
                  selected: _onlyMine,
                  onSelected: (v) => setState(() => _onlyMine = v),
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  checkmarkColor: AppColors.primaryLight,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border, width: 0.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PipelineStage>>(
              stream: _stagesStream,
              builder: (context, stageSnap) {
                if (stageSnap.hasError) return ErrorView(error: stageSnap.error);
                if (!stageSnap.hasData) return const LoadingView();
                final stages = stageSnap.data!;
                if (stages.isEmpty) return EmptyView(message: context.tr('no_stages'));
                return StreamBuilder<List<Customer>>(
                  stream: _customersStream,
                  builder: (context, custSnap) {
                    if (custSnap.hasError) return ErrorView(error: custSnap.error);
                    if (!custSnap.hasData) return const LoadingView();
                    final all = _filter(custSnap.data!, me);

                    final placed = <String>{};
                    final columns = <Widget>[];
                    for (final stage in stages) {
                      final list = all.where((c) => stage.matches(c.stageId)).toList();
                      placed.addAll(list.map((c) => c.id));
                      columns.add(_StageColumn(
                        title: stage.name(context.lang),
                        color: AppColors.fromHex(stage.color),
                        customers: list,
                        canClaim: Permissions.canClaimLeads(me),
                        canDelete: canDelete,
                        onClaim: _claim,
                        onDelete: _delete,
                      ));
                    }
                    final orphans = all.where((c) => !placed.contains(c.id)).toList();
                    if (orphans.isNotEmpty) {
                      columns.add(_StageColumn(
                        title: context.tr('no_stage'),
                        color: AppColors.textSecondary,
                        customers: orphans,
                        canClaim: Permissions.canClaimLeads(me),
                        canDelete: canDelete,
                        onClaim: _claim,
                        onDelete: _delete,
                      ));
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: columns),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StageColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<Customer> customers;
  final bool canClaim;
  final bool canDelete;
  final ValueChanged<Customer> onClaim;
  final ValueChanged<Customer> onDelete;

  const _StageColumn({
    required this.title,
    required this.color,
    required this.customers,
    required this.canClaim,
    required this.canDelete,
    required this.onClaim,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text('$title · ${customers.length}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          ...customers.asMap().entries.map((e) => _CustomerCard(
                key: ValueKey(e.value.id),
                index: e.key,
                customer: e.value,
                canClaim: canClaim,
                canDelete: canDelete,
                onClaim: () => onClaim(e.value),
                onDelete: () => onDelete(e.value),
              )),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final int index;
  final Customer customer;
  final bool canClaim;
  final bool canDelete;
  final VoidCallback onClaim;
  final VoidCallback onDelete;

  const _CustomerCard({
    super.key,
    required this.index,
    required this.customer,
    required this.canClaim,
    required this.canDelete,
    required this.onClaim,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: staggerDelay(index, stepMs: 35, maxMs: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: HoverLift(
          radius: 8,
          child: InkWell(
      onTap: () => showDialog(context: context, builder: (_) => CustomerDetailDialog(customer: customer)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border, width: 0.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(customer.name.isEmpty ? customer.phone : customer.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                if (canDelete)
                  InkWell(
                    onTap: onDelete,
                    child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.close, size: 14, color: AppColors.textSecondary)),
                  ),
              ],
            ),
            if (customer.name.isNotEmpty && customer.phone.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(customer.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(_sourceIcon(customer.source), size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(customer.source.value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                const Spacer(),
                if (!customer.isClaimed)
                  (canClaim
                      ? InkWell(onTap: onClaim, child: Text(context.tr('claim'), style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)))
                      : const SizedBox())
                else
                  Flexible(child: Text(customer.managerName ?? '—', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
      ),
    ),
        ),
      ),
    );
  }

  IconData _sourceIcon(LeadSource s) {
    switch (s) {
      case LeadSource.whatsapp:
        return Icons.chat_bubble_outline;
      case LeadSource.instagram:
        return Icons.camera_alt_outlined;
      case LeadSource.telegram:
        return Icons.send_outlined;
      case LeadSource.facebook:
        return Icons.public;
      case LeadSource.manual:
        return Icons.edit_outlined;
    }
  }
}
