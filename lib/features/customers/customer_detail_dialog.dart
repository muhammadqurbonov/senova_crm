import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/custom_fields.dart';
import '../../models/customer_model.dart';
import '../../models/deal_model.dart';
import '../../models/note_model.dart';
import '../../models/pipeline_stage_model.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/org_config_provider.dart';
import '../../services/audit_service.dart';
import '../../services/customer_service.dart';
import '../../services/deal_service.dart';
import '../../services/note_service.dart';
import '../../services/pipeline_stage_service.dart';
import '../../services/property_service.dart';
import '../../models/org_config.dart';

class CustomerDetailDialog extends StatefulWidget {
  final Customer customer;
  const CustomerDetailDialog({super.key, required this.customer});

  @override
  State<CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<CustomerDetailDialog> {
  final _noteCtrl = TextEditingController();
  late String _currentStageId;
  late Customer _c;

  AppUser? _me;
  NoteService? _noteService;
  DealService? _dealService;
  CustomerService? _customerService;
  Stream<List<PipelineStage>>? _stagesStream;
  Stream<List<Note>>? _notesStream;
  Stream<List<Deal>>? _dealsStream;

  @override
  void initState() {
    super.initState();
    _c = widget.customer;
    _currentStageId = widget.customer.stageId;
    final me = context.read<AuthProvider>().user;
    if (me != null) {
      _me = me;
      _noteService = NoteService(me.orgId);
      _dealService = DealService(me.orgId);
      _customerService = CustomerService(me.orgId);
      _stagesStream = PipelineStageService(me.orgId).watchAll();
      _notesStream = _noteService!.watchByCustomer(widget.customer.id);
      _dealsStream = _dealService!.watchByCustomer(widget.customer.id);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final me = _me;
    if (me == null) return const SizedBox();
    final canWrite = Permissions.canWrite(me);
    final fields = context.watch<OrgConfigProvider>().config.customerFields;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(c.name.isEmpty ? c.phone : c.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600))),
                  if (canWrite)
                    IconButton(
                      tooltip: context.tr('edit_customer'),
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                      onPressed: () => _showEditDialog(c, fields),
                    ),
                  IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                ],
              ),
              _infoRow(context.tr('phone'), c.phone),
              _infoRow(context.tr('source'), c.source.value),
              _infoRow(context.tr('manager'), c.managerName ?? context.tr('not_claimed')),
              for (final f in fields)
                if (c.custom[f.id] != null)
                  _infoRow(f.label, displayCustomValue(f, c.custom[f.id], yes: context.tr('yes'), no: context.tr('no'))),
              const SizedBox(height: 10),
              StreamBuilder<List<PipelineStage>>(
                stream: _stagesStream,
                builder: (context, snap) {
                  final stages = snap.data ?? [];
                  if (stages.isEmpty) return const SizedBox();
                  String? selected;
                  for (final s in stages) {
                    if (s.matches(_currentStageId)) {
                      selected = s.key;
                      break;
                    }
                  }
                  return Row(
                    children: [
                      SizedBox(width: 90, child: Text(context.tr('stage'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selected,
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          underline: const SizedBox(),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          items: stages.map((s) => DropdownMenuItem(value: s.key, child: Text(s.name(context.lang)))).toList(),
                          onChanged: !canWrite
                              ? null
                              : (newKey) async {
                                  if (newKey == null) return;
                                  final previous = _currentStageId;
                                  setState(() => _currentStageId = newKey);
                                  try {
                                    await _customerService!.updateStage(c.id, newKey);
                                  } catch (e) {
                                    if (!mounted) return;
                                    setState(() => _currentStageId = previous);
                                    showSnack(context, context.tr(errorKeyFor(e)), error: true);
                                  }
                                },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppColors.primaryLight,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        tabs: [Tab(text: context.tr('tab_notes')), Tab(text: context.tr('nav_deals'))],
                      ),
                      Expanded(child: TabBarView(children: [_notesTab(c, me, canWrite), _dealsTab(c, me, canWrite)])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Customer c, List<CustomFieldDef> fields) {
    final nameCtrl = TextEditingController(text: c.name);
    final phoneCtrl = TextEditingController(text: c.phone);
    final cf = CustomFieldsController(fields, c.custom);
    String? error;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(ctx.tr('edit_customer'), style: const TextStyle(color: AppColors.textPrimary)),
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
                        final custom = cf.collect();
                        await _customerService!.update(c.id, name: name, phone: phone, custom: custom);
                        if (mounted) {
                          setState(() => _c = Customer(
                                id: c.id,
                                orgId: c.orgId,
                                name: name,
                                phone: phone,
                                source: c.source,
                                stageId: c.stageId,
                                managerId: c.managerId,
                                managerName: c.managerName,
                                tags: c.tags,
                                custom: custom,
                                createdAt: c.createdAt,
                                updatedAt: DateTime.now(),
                              ));
                        }
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _addNote(Customer c, AppUser me) async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await _noteService!.add(customerId: c.id, type: 'note', text: text, authorName: me.name);
      _noteCtrl.clear();
    } catch (e) {
      if (mounted) showSnack(context, context.tr(errorKeyFor(e)), error: true);
    }
  }

  Widget _notesTab(Customer c, AppUser me, bool canWrite) {
    return Column(
      children: [
        if (canWrite)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(hintText: context.tr('write_note')),
                    onSubmitted: (_) => _addNote(c, me),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryLight, size: 20),
                  onPressed: () => _addNote(c, me),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<List<Note>>(
            stream: _notesStream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(error: snap.error);
              if (!snap.hasData) return const LoadingView();
              final notes = snap.data!;
              if (notes.isEmpty) return EmptyView(message: context.tr('no_notes'));
              return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, i) {
                  final n = notes[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('${n.authorName} · ${formatDateTime(n.createdAt)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
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

  Future<void> _finishDeal(Deal d, Customer c, AppUser me, {required bool close}) async {
    try {
      final ok = close
          ? await _dealService!.closeDeal(dealId: d.id, customerId: c.id)
          : await _dealService!.rejectDeal(dealId: d.id, customerId: c.id);
      if (!mounted) return;
      if (!ok) {
        showSnack(context, context.tr('deal_already_finished'), error: true);
        return;
      }
      setState(() => _currentStageId = close ? 'mizoj_shud' : 'rad_kard');
      AuditService(me.orgId).log(me, close ? 'deal.close' : 'deal.reject', targetType: 'deal', targetId: d.id, details: '${d.amount}');
    } catch (e) {
      if (mounted) showSnack(context, context.tr(errorKeyFor(e)), error: true);
    }
  }

  Widget _dealsTab(Customer c, AppUser me, bool canWrite) {
    return Column(
      children: [
        if (canWrite)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showAddDealDialog(c),
              icon: const Icon(Icons.add, size: 16, color: AppColors.primaryLight),
              label: Text(context.tr('new_deal')),
            ),
          )
        else
          const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<List<Deal>>(
            stream: _dealsStream,
            builder: (context, snap) {
              if (snap.hasError) return ErrorView(error: snap.error);
              if (!snap.hasData) return const LoadingView();
              final deals = snap.data!;
              if (deals.isEmpty) return EmptyView(message: context.tr('no_deals'));
              return ListView.builder(
                itemCount: deals.length,
                itemBuilder: (context, i) {
                  final d = deals[i];
                  final isOpen = d.status == 'open';
                  final statusColor = isOpen ? AppColors.textSecondary : (d.status == 'closed' ? AppColors.success : AppColors.danger);
                  final statusKey = isOpen ? 'deal_open' : (d.status == 'closed' ? 'deal_closed_won' : 'deal_rejected');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.money(d.amount), style: const TextStyle(color: AppColors.primaryLight, fontSize: 14, fontWeight: FontWeight.w600)),
                              Text(context.tr(statusKey), style: TextStyle(color: statusColor, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isOpen && canWrite) ...[
                          TextButton(
                            onPressed: () => _finishDeal(d, c, me, close: true),
                            child: Text(context.tr('close_deal'), style: const TextStyle(color: AppColors.success, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () => _finishDeal(d, c, me, close: false),
                            child: Text(context.tr('reject_deal'), style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                          ),
                        ],
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

  void _showAddDealDialog(Customer c) {
    final amountCtrl = TextEditingController();
    final me = _me!;
    final propsStream = PropertyService(me.orgId).watchAll();
    String? selectedPropertyId;
    String paymentType = 'full';
    String? error;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(ctx.tr('new_deal'), style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<List<Property>>(
                  stream: propsStream,
                  builder: (context, snap) {
                    final props = snap.data ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: selectedPropertyId,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      decoration: InputDecoration(labelText: ctx.tr('property')),
                      items: props.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title(ctx.lang), overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setLocal(() => selectedPropertyId = v),
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: ctx.tr('amount')),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: paymentType,
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(labelText: ctx.tr('payment_type')),
                  items: [
                    DropdownMenuItem(value: 'full', child: Text(ctx.tr('payment_full'))),
                    DropdownMenuItem(value: 'installment', child: Text(ctx.tr('payment_installment'))),
                  ],
                  onChanged: (v) => setLocal(() => paymentType = v ?? 'full'),
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
                      final amount = double.tryParse(amountCtrl.text.trim().replaceAll(',', '.'));
                      if (selectedPropertyId == null || amount == null || amount <= 0) {
                        setLocal(() => error = ctx.tr('err_deal_fields'));
                        return;
                      }
                      setLocal(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await _dealService!.create(customerId: c.id, propertyId: selectedPropertyId!, amount: amount, paymentType: paymentType);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setLocal(() {
                          saving = false;
                          error = ctx.tr(errorKeyFor(e));
                        });
                      }
                    },
              child: Text(ctx.tr('create')),
            ),
          ],
        ),
      ),
    );
  }
}
