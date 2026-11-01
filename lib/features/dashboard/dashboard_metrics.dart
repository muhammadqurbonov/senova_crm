import '../../models/customer_model.dart';
import '../../models/deal_model.dart';
import '../../models/pipeline_stage_model.dart';
import '../../models/task_model.dart';

/// Ҳисоби метрикаҳои dashboard — функсияи софи тестшаванда.
///
/// Таърифҳо:
///  - totalLeads: шумораи ҳамаи мизоҷон/лидҳо.
///  - won / lost: мизоҷоне, ки stage-и онҳо 'won' / 'lost' аст.
///  - inProgress: гирифташуда (менеҷер дорад) ва на won, на lost.
///  - conversionPercent: won / totalLeads * 100 (рӯйкарда).
///  - openDealsValue: ҷамъи маблағи сделкаҳои кушода (ин ПАЙПЛАЙН аст, на даромад).
///  - wonDealsValue: ҷамъи маблағи сделкаҳои пӯшидашуда (status == closed).
///  - overdueTasks: супоришҳои иҷронашуда, ки мӯҳлататон гузаштааст.
class DashboardMetrics {
  final int totalLeads;
  final int inProgress;
  final int won;
  final int lost;
  final int conversionPercent;
  final int openDeals;
  final double openDealsValue;
  final double wonDealsValue;
  final int overdueTasks;

  /// Шумораи мизоҷон аз рӯи PipelineStage.id
  final Map<String, int> countsByStage;
  final int withoutStage;

  const DashboardMetrics({
    required this.totalLeads,
    required this.inProgress,
    required this.won,
    required this.lost,
    required this.conversionPercent,
    required this.openDeals,
    required this.openDealsValue,
    required this.wonDealsValue,
    required this.overdueTasks,
    required this.countsByStage,
    required this.withoutStage,
  });

  static PipelineStage? _stageOf(List<PipelineStage> stages, String stageId) {
    for (final s in stages) {
      if (s.matches(stageId)) return s;
    }
    return null;
  }

  static DashboardMetrics compute({
    required List<PipelineStage> stages,
    required List<Customer> customers,
    required List<Deal> deals,
    required List<AppTask> tasks,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    var won = 0;
    var lost = 0;
    var inProgress = 0;
    var withoutStage = 0;
    final counts = <String, int>{};

    for (final c in customers) {
      final stage = _stageOf(stages, c.stageId);
      if (stage == null) {
        withoutStage++;
        continue;
      }
      counts[stage.id] = (counts[stage.id] ?? 0) + 1;
      if (stage.isWon) {
        won++;
      } else if (stage.isLost) {
        lost++;
      } else if (c.isClaimed) {
        inProgress++;
      }
    }

    var openDeals = 0;
    var openValue = 0.0;
    var wonValue = 0.0;
    for (final d in deals) {
      if (d.status == 'open') {
        openDeals++;
        openValue += d.amount;
      } else if (d.status == 'closed') {
        wonValue += d.amount;
      }
    }

    final overdue = tasks.where((t) => !t.done && t.dueDate != null && t.dueDate!.isBefore(ref)).length;
    final total = customers.length;

    return DashboardMetrics(
      totalLeads: total,
      inProgress: inProgress,
      won: won,
      lost: lost,
      conversionPercent: total == 0 ? 0 : ((won / total) * 100).round(),
      openDeals: openDeals,
      openDealsValue: openValue,
      wonDealsValue: wonValue,
      overdueTasks: overdue,
      countsByStage: counts,
      withoutStage: withoutStage,
    );
  }
}
