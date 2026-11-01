import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../models/property_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/audit_service.dart';
import '../../services/property_service.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  AppUser? _me;
  PropertyService? _service;
  Stream<List<Property>>? _stream;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthProvider>().user;
    if (me != null) {
      _me = me;
      _service = PropertyService(me.orgId);
      _stream = _service!.watchAll();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete(Property p) async {
    final me = _me!;
    final label = p.title(context.lang);
    if (!await confirmDelete(context, label)) return;
    try {
      await _service!.delete(p.id);
      AuditService(me.orgId).log(me, 'property.delete', targetType: 'property', targetId: p.id, details: label);
    } catch (e) {
      if (mounted) showSnack(context, context.tr(errorKeyFor(e)), error: true);
    }
  }

  Future<void> _setStatus(Property p, PropertyStatus s) async {
    try {
      await _service!.updateStatus(p.id, s.value);
    } catch (e) {
      if (mounted) showSnack(context, context.tr(errorKeyFor(e)), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    if (me == null) return const SizedBox();
    final canWrite = Permissions.canWrite(me);
    final canDelete = Permissions.canDelete(me);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(context.tr('properties_title'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600))),
                if (canWrite)
                  FilledButton.icon(
                    onPressed: _showAddPropertyDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.tr('add')),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: context.tr('search_properties'),
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Property>>(
                stream: _stream,
                builder: (context, snap) {
                  if (snap.hasError) return ErrorView(error: snap.error);
                  if (!snap.hasData) return const LoadingView();
                  final q = _query.trim().toLowerCase();
                  final props = snap.data!.where((p) {
                    if (q.isEmpty) return true;
                    return p.titleTj.toLowerCase().contains(q) || p.titleRu.toLowerCase().contains(q) || p.district.toLowerCase().contains(q);
                  }).toList();
                  if (props.isEmpty) return EmptyView(message: context.tr('no_properties'), icon: Icons.apartment_outlined);
                  return LayoutBuilder(builder: (context, constraints) {
                    final cols = (constraints.maxWidth / 270).floor().clamp(1, 4);
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.25),
                      itemCount: props.length,
                      itemBuilder: (context, i) => _PropertyCard(
                        property: props[i],
                        canWrite: canWrite,
                        canDelete: canDelete,
                        onDelete: () => _delete(props[i]),
                        onStatus: (s) => _setStatus(props[i], s),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPropertyDialog() {
    final titleTjCtrl = TextEditingController();
    final titleRuCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final roomsCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    String? error;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(ctx.tr('new_property'), style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleTjCtrl, decoration: InputDecoration(labelText: ctx.tr('title_tj'))),
                const SizedBox(height: 10),
                TextField(controller: titleRuCtrl, decoration: InputDecoration(labelText: ctx.tr('title_ru'))),
                const SizedBox(height: 10),
                TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: ctx.tr('price'))),
                const SizedBox(height: 10),
                TextField(controller: roomsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: ctx.tr('rooms'))),
                const SizedBox(height: 10),
                TextField(controller: areaCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: ctx.tr('area'))),
                const SizedBox(height: 10),
                TextField(controller: districtCtrl, decoration: InputDecoration(labelText: ctx.tr('district'))),
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
                      final price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
                      if ((titleTjCtrl.text.trim().isEmpty && titleRuCtrl.text.trim().isEmpty) || price == null || price <= 0) {
                        setLocal(() => error = ctx.tr('err_property_fields'));
                        return;
                      }
                      setLocal(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await _service!.create(Property(
                          id: '',
                          orgId: _service!.orgId,
                          titleTj: titleTjCtrl.text.trim(),
                          titleRu: titleRuCtrl.text.trim(),
                          price: price,
                          rooms: int.tryParse(roomsCtrl.text.trim()),
                          area: double.tryParse(areaCtrl.text.trim().replaceAll(',', '.')),
                          district: districtCtrl.text.trim(),
                        ));
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

class _PropertyCard extends StatelessWidget {
  final Property property;
  final bool canWrite;
  final bool canDelete;
  final VoidCallback onDelete;
  final ValueChanged<PropertyStatus> onStatus;
  const _PropertyCard({required this.property, required this.canWrite, required this.canDelete, required this.onDelete, required this.onStatus});

  Color _statusColor(PropertyStatus s) {
    switch (s) {
      case PropertyStatus.available:
        return AppColors.success;
      case PropertyStatus.reserved:
        return AppColors.warning;
      case PropertyStatus.sold:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = property;
    final color = _statusColor(p.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(p.title(context.lang), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
              if (canDelete) InkWell(onTap: onDelete, child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(context.money(p.price), style: const TextStyle(color: AppColors.primaryLight, fontSize: 15, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (p.rooms != null)
            Text('${context.tr('rooms_short', {'n': '${p.rooms}'})} · ${p.area != null ? formatAmount(p.area!) : '-'} ${context.tr('sqm')}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          if (p.district.isNotEmpty) Text(p.district, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          if (canWrite)
            PopupMenuButton<PropertyStatus>(
              tooltip: context.tr('status'),
              color: AppColors.surface,
              onSelected: onStatus,
              itemBuilder: (_) => [
                for (final s in PropertyStatus.values) PopupMenuItem(value: s, child: Text(context.tr('pstatus_${s.value}'))),
              ],
              child: _StatusChip(label: context.tr('pstatus_${p.status.value}'), color: color, editable: true),
            )
          else
            _StatusChip(label: context.tr('pstatus_${p.status.value}'), color: color, editable: false),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool editable;
  const _StatusChip({required this.label, required this.color, required this.editable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11)),
          if (editable) Icon(Icons.arrow_drop_down, size: 14, color: color),
        ],
      ),
    );
  }
}
