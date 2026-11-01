import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../models/customer_model.dart';
import '../../models/deal_model.dart';
import '../../models/pipeline_stage_model.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../../services/deal_service.dart';
import '../../services/pipeline_stage_service.dart';
import '../../services/task_service.dart';
import 'dashboard_metrics.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Stream<List<PipelineStage>>? _stages;
  Stream<List<Customer>>? _customers;
  Stream<List<Deal>>? _deals;
  Stream<List<AppTask>>? _tasks;

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthProvider>().user;
    if (me != null) {
      _stages = PipelineStageService(me.orgId).watchAll();
      _customers = CustomerService(me.orgId).watchAll();
      _deals = DealService(me.orgId).watchAll();
      _tasks = TaskService(me.orgId).watchAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stages == null) return const SizedBox();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('dashboard_title'), style: const TextStyle(fontSize: 22, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            StreamBuilder<List<PipelineStage>>(
              stream: _stages,
              builder: (context, stageSnap) => StreamBuilder<List<Customer>>(
                stream: _customers,
                builder: (context, custSnap) => StreamBuilder<List<Deal>>(
                  stream: _deals,
                  builder: (context, dealSnap) => StreamBuilder<List<AppTask>>(
                    stream: _tasks,
                    builder: (context, taskSnap) {
                      final err = stageSnap.error ?? custSnap.error ?? dealSnap.error ?? taskSnap.error;
                      if (err != null) return SizedBox(height: 200, child: ErrorView(error: err));
                      if (!stageSnap.hasData || !custSnap.hasData || !dealSnap.hasData || !taskSnap.hasData) {
                        return const SizedBox(height: 200, child: LoadingView());
                      }
                      final stages = stageSnap.data!;
                      final m = DashboardMetrics.compute(
                        stages: stages,
                        customers: custSnap.data!,
                        deals: dealSnap.data!,
                        tasks: taskSnap.data!,
                      );
                      return _Content(metrics: m, stages: stages);
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

class _Content extends StatelessWidget {
  final DashboardMetrics metrics;
  final List<PipelineStage> stages;
  const _Content({required this.metrics, required this.stages});

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final cols = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 520 ? 3 : 2);
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              _StatCard(label: context.tr('stat_total_leads'), value: '${m.totalLeads}'),
              _StatCard(label: context.tr('stat_in_progress'), value: '${m.inProgress}'),
              _StatCard(label: context.tr('stat_won'), value: '${m.won}', color: AppColors.accent),
              _StatCard(label: context.tr('stat_conversion'), value: '${m.conversionPercent}%'),
              _StatCard(label: context.tr('stat_open_deals'), value: '${m.openDeals}'),
              _StatCard(label: context.tr('stat_pipeline_value'), value: context.money(m.openDealsValue)),
              _StatCard(label: context.tr('stat_won_value'), value: context.money(m.wonDealsValue), color: AppColors.accent),
              _StatCard(label: context.tr('stat_overdue_tasks'), value: '${m.overdueTasks}', color: m.overdueTasks > 0 ? AppColors.danger : AppColors.primaryLight),
            ],
          );
        }),
        const SizedBox(height: 24),
        Text(context.tr('leads_by_stage'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 0.5)),
          child: Column(
            children: [
              for (final s in stages) _StageBar(label: s.name(context.lang), count: m.countsByStage[s.id] ?? 0, total: m.totalLeads, color: AppColors.fromHex(s.color)),
              if (m.withoutStage > 0) _StageBar(label: context.tr('no_stage'), count: m.withoutStage, total: m.totalLeads, color: AppColors.textSecondary),
              if (stages.isEmpty && m.withoutStage == 0) Text(context.tr('no_stages'), style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StageBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _StageBar({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: value, minHeight: 8, color: color, backgroundColor: AppColors.border),
            ),
          ),
          SizedBox(width: 40, child: Text('$count', textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, this.color = AppColors.primaryLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
