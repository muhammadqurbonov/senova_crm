import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../models/customer_model.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/audit_service.dart';
import '../../services/customer_service.dart';
import '../../services/task_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  AppUser? _me;
  TaskService? _service;
  Stream<List<AppTask>>? _stream;

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthProvider>().user;
    if (me != null) {
      _me = me;
      _service = TaskService(me.orgId);
      _stream = _service!.watchByUser(me.uid);
    }
  }

  Future<void> _delete(AppTask t) async {
    final me = _me!;
    if (!await confirmDelete(context, t.title)) return;
    try {
      await _service!.delete(t.id);
      AuditService(me.orgId).log(me, 'task.delete', targetType: 'task', targetId: t.id, details: t.title);
    } catch (e) {
      if (mounted) showSnack(context, context.tr(errorKeyFor(e)), error: true);
    }
  }

  Future<void> _toggle(AppTask t, bool done) async {
    try {
      await _service!.toggleDone(t.id, done);
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
                Expanded(child: Text(context.tr('tasks_title'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600))),
                if (canWrite)
                  FilledButton.icon(
                    onPressed: () => _showAddTaskDialog(me),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.tr('add')),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<AppTask>>(
                stream: _stream,
                builder: (context, snap) {
                  if (snap.hasError) return ErrorView(error: snap.error);
                  if (!snap.hasData) return const LoadingView();
                  final tasks = snap.data!;
                  if (tasks.isEmpty) return EmptyView(message: context.tr('no_tasks'), icon: Icons.check_circle_outline);
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      final overdue = t.dueDate != null && t.dueDate!.isBefore(DateTime.now()) && !t.done;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: overdue ? AppColors.danger : AppColors.border, width: 0.5)),
                        child: Row(
                          children: [
                            Checkbox(value: t.done, activeColor: AppColors.primary, onChanged: canWrite ? (v) => _toggle(t, v ?? false) : null),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.title, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, decoration: t.done ? TextDecoration.lineThrough : null)),
                                  if (t.customerName.isNotEmpty) Text(t.customerName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                            if (t.dueDate != null) Text(formatDate(t.dueDate!), style: TextStyle(color: overdue ? AppColors.danger : AppColors.textSecondary, fontSize: 11)),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                onPressed: () => _delete(t),
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
        ),
      ),
    );
  }

  void _showAddTaskDialog(AppUser me) {
    final titleCtrl = TextEditingController();
    final customersStream = CustomerService(me.orgId).watchAll();
    Customer? selectedCustomer;
    DateTime? dueDate;
    String? error;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(ctx.tr('new_task'), style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: InputDecoration(labelText: ctx.tr('task_title'))),
                const SizedBox(height: 10),
                StreamBuilder<List<Customer>>(
                  stream: customersStream,
                  builder: (context, snap) {
                    final customers = snap.data ?? const <Customer>[];
                    return DropdownButtonFormField<String>(
                      initialValue: selectedCustomer?.id,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      decoration: InputDecoration(labelText: ctx.tr('customer_optional')),
                      items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name.isEmpty ? c.phone : c.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (id) {
                        Customer? found;
                        for (final c in customers) {
                          if (c.id == id) found = c;
                        }
                        setLocal(() => selectedCustomer = found);
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text(dueDate == null ? ctx.tr('no_deadline') : formatDate(dueDate!), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2035));
                        if (picked != null) setLocal(() => dueDate = picked);
                      },
                      child: Text(ctx.tr('choose')),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 6),
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
                      if (titleCtrl.text.trim().isEmpty) {
                        setLocal(() => error = ctx.tr('err_task_title'));
                        return;
                      }
                      setLocal(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        final cust = selectedCustomer;
                        await _service!.create(
                          customerId: cust?.id ?? '',
                          customerName: cust == null ? '' : (cust.name.isEmpty ? cust.phone : cust.name),
                          title: titleCtrl.text.trim(),
                          dueDate: dueDate,
                          assignedTo: me.uid,
                          assignedToName: me.name,
                        );
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
