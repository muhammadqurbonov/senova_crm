import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/motion.dart';
import '../../models/customer_model.dart';
import '../../models/deal_model.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/audit_service.dart';
import '../../services/customer_service.dart';
import '../../services/deal_service.dart';
import '../../services/property_service.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  AppUser? _me;
  DealService? _service;
  Stream<List<Deal>>? _deals;
  Stream<List<Customer>>? _customers;
  Stream<List<Property>>? _properties;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthProvider>().user;
    if (me != null) {
      _me = me;
      _service = DealService(me.orgId);
      _deals = _service!.watchAll();
      _customers = CustomerService(me.orgId).watchAll();
      _properties = PropertyService(me.orgId).watchAll();
    }
  }

  Future<void> _delete(Deal d) async {
    final me = _me!;
    final label = context.money(d.amount);
    if (!await confirmDelete(context, label)) return;
    try {
      await _service!.delete(d.id);
      AuditService(me.orgId).log(me, 'deal.delete', targetType: 'deal', targetId: d.id, details: '${d.amount}');
    } catch (e) {
      if (mounted) showSnack(context, context.tr(errorKeyFor(e)), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    if (me == null) return const SizedBox();
    final canDelete = Permissions.canDelete(me);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('deals_title'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final f in const ['all', 'open', 'closed', 'rejected'])
                  ChoiceChip(
                    label: Text(context.tr('filter_$f')),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border, width: 0.5),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Deal>>(
                stream: _deals,
                builder: (context, dealSnap) => StreamBuilder<List<Customer>>(
                  stream: _customers,
                  builder: (context, custSnap) => StreamBuilder<List<Property>>(
                    stream: _properties,
                    builder: (context, propSnap) {
                      final err = dealSnap.error ?? custSnap.error ?? propSnap.error;
                      if (err != null) return ErrorView(error: err);
                      if (!dealSnap.hasData) return const LoadingView();

                      final customerNames = {
                        for (final c in custSnap.data ?? const <Customer>[]) c.id: (c.name.isEmpty ? c.phone : c.name),
                      };
                      final propertyTitles = {
                        for (final p in propSnap.data ?? const <Property>[]) p.id: p.title(context.lang),
                      };
                      final deals = dealSnap.data!.where((d) => _filter == 'all' || d.status == _filter).toList();
                      if (deals.isEmpty) return EmptyView(message: context.tr('no_deals'), icon: Icons.handshake_outlined);

                      return ListView.builder(
                        itemCount: deals.length,
                        itemBuilder: (context, i) => FadeSlideIn(
                          key: ValueKey(deals[i].id),
                          delay: staggerDelay(i),
                          child: _DealTile(
                            deal: deals[i],
                            customerName: customerNames[deals[i].customerId] ?? '—',
                            propertyTitle: propertyTitles[deals[i].propertyId] ?? '—',
                            canDelete: canDelete,
                            onDelete: () => _delete(deals[i]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealTile extends StatelessWidget {
  final Deal deal;
  final String customerName;
  final String propertyTitle;
  final bool canDelete;
  final VoidCallback onDelete;
  const _DealTile({required this.deal, required this.customerName, required this.propertyTitle, required this.canDelete, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final d = deal;
    final Color color;
    final String statusKey;
    if (d.status == 'open') {
      color = AppColors.primaryLight;
      statusKey = 'deal_open';
    } else if (d.status == 'closed') {
      color = AppColors.success;
      statusKey = 'deal_closed';
    } else {
      color = AppColors.danger;
      statusKey = 'deal_rejected';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.money(d.amount), style: const TextStyle(color: AppColors.primaryLight, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$customerName · $propertyTitle', overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5)),
                Text(d.paymentType == PaymentType.installment ? context.tr('payment_installment') : context.tr('payment_full'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(context.tr(statusKey), style: TextStyle(color: color, fontSize: 11)),
          ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
