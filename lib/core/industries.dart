import 'package:flutter/material.dart';
import 'industries_data.dart';

class StageTpl {
  final String key;
  final String ru;
  final String tj;
  final String en;
  final String color;
  final String type;
  const StageTpl(this.key, this.ru, this.tj, this.en, this.color, this.type);

  String name(String lang) => lang == 'ru' ? ru : (lang == 'tj' ? tj : en);
}

class DemoItem {
  final String tj;
  final String ru;
  final double price;
  const DemoItem(this.tj, this.ru, this.price);
}

/// Шаблони соҳа: номи соҳа, stage-ҳо, истилоҳот (бо роҳи override-и калидҳои тарҷума) ва маълумоти демо.
class IndustryPreset {
  final String id;
  final IconData icon;
  final String ru;
  final String tj;
  final String en;
  final List<StageTpl> stages;
  final List<DemoItem> demoItems;

  /// lang -> key -> text. Холӣ = истилоҳоти пешфарз (амволи ғайриманқул).
  final Map<String, Map<String, String>> overrides;

  const IndustryPreset({
    required this.id,
    required this.icon,
    required this.ru,
    required this.tj,
    required this.en,
    required this.stages,
    required this.demoItems,
    required this.overrides,
  });

  String name(String lang) => lang == 'ru' ? ru : (lang == 'tj' ? tj : en);
}

IndustryPreset presetOf(String id) => kIndustries[id] ?? kIndustries['generic']!;

/// Ҳуҷҷатҳои pipelineStages барои ширкати нав аз рӯи соҳа. 'id' — танҳо барои сохтани ID-и ҳуҷҷат.
List<Map<String, dynamic>> stagesDataFor(String industry, String orgId) {
  final p = presetOf(industry);
  return [
    for (var i = 0; i < p.stages.length; i++)
      {
        'id': p.stages[i].key,
        'key': p.stages[i].key,
        'name_tj': p.stages[i].tj,
        'name_ru': p.stages[i].ru,
        'name_en': p.stages[i].en,
        'order': i,
        'color': p.stages[i].color,
        'type': p.stages[i].type,
        'orgId': orgId,
      },
  ];
}
