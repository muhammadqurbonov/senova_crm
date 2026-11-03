import 'package:flutter/material.dart';
import '../../models/org_config.dart';
import '../format.dart';
import '../l10n/app_lang.dart';
import '../theme/app_colors.dart';

/// Ҳолати формаи майдонҳои иловагӣ: controller-ҳо + арзишҳои интихобӣ.
class CustomFieldsController extends ChangeNotifier {
  final List<CustomFieldDef> defs;
  final Map<String, TextEditingController> _text = {};
  final Map<String, dynamic> _values = {};

  CustomFieldsController(this.defs, Map<String, dynamic>? initial) {
    for (final d in defs) {
      final v = initial?[d.id];
      if (d.type == 'text' || d.type == 'number') {
        _text[d.id] = TextEditingController(text: v == null ? '' : '$v');
      } else if (v != null) {
        _values[d.id] = v;
      }
    }
  }

  dynamic valueOf(String id) => _values[id];

  void setValue(String id, dynamic v) {
    if (v == null) {
      _values.remove(id);
    } else {
      _values[id] = v;
    }
    notifyListeners();
  }

  TextEditingController textOf(String id) => _text[id]!;

  /// true агар ҳамаи майдонҳои ҳатмӣ пур ва рақамҳо дурустанд.
  bool validate() {
    for (final d in defs) {
      final raw = collectOne(d);
      if (d.required && d.type != 'bool' && (raw == null || raw == '')) return false;
      if (d.type == 'number') {
        final t = _text[d.id]!.text.trim();
        if (t.isNotEmpty && double.tryParse(t.replaceAll(',', '.')) == null) return false;
      }
    }
    return true;
  }

  dynamic collectOne(CustomFieldDef d) {
    switch (d.type) {
      case 'text':
        final t = _text[d.id]!.text.trim();
        return t.isEmpty ? null : t;
      case 'number':
        final t = _text[d.id]!.text.trim().replaceAll(',', '.');
        return t.isEmpty ? null : double.tryParse(t);
      default:
        return _values[d.id];
    }
  }

  Map<String, dynamic> collect() {
    final out = <String, dynamic>{};
    for (final d in defs) {
      final v = collectOne(d);
      if (v != null) out[d.id] = v;
    }
    return out;
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }
}

class CustomFieldsForm extends StatelessWidget {
  final CustomFieldsController controller;
  const CustomFieldsForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.defs.isEmpty) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final d in controller.defs) Padding(padding: const EdgeInsets.only(top: 10), child: _field(context, d))],
      ),
    );
  }

  Widget _field(BuildContext context, CustomFieldDef d) {
    final label = d.required ? '${d.label} *' : d.label;
    switch (d.type) {
      case 'number':
        return TextField(
          controller: controller.textOf(d.id),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
        );
      case 'select':
        final cur = controller.valueOf(d.id) as String?;
        return DropdownButtonFormField<String>(
          initialValue: d.options.contains(cur) ? cur : null,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          decoration: InputDecoration(labelText: label),
          items: [for (final o in d.options) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))],
          onChanged: (v) => controller.setValue(d.id, v),
        );
      case 'bool':
        return Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
            Switch(value: controller.valueOf(d.id) == true, onChanged: (v) => controller.setValue(d.id, v)),
          ],
        );
      case 'date':
        final cur = controller.valueOf(d.id) as String?;
        return Row(
          children: [
            Expanded(child: Text(cur == null ? label : '${d.label}: ${_pretty(cur)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1940),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  controller.setValue(d.id, '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                }
              },
              child: Text(context.tr('choose')),
            ),
          ],
        );
      default:
        return TextField(controller: controller.textOf(d.id), decoration: InputDecoration(labelText: label));
    }
  }
}

String _pretty(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : formatDate(d);
}

/// Арзиши майдон барои намоиш (бе контекст, барои рӯйхат ва корт).
String displayCustomValue(CustomFieldDef d, dynamic v, {String yes = 'Yes', String no = 'No'}) {
  if (v == null) return '';
  switch (d.type) {
    case 'bool':
      return v == true ? yes : no;
    case 'date':
      return _pretty('$v');
    case 'number':
      return v is num ? (v == v.roundToDouble() ? formatAmount(v) : v.toString()) : '$v';
    default:
      return '$v';
  }
}
