import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';
import '../industries_data.dart';
import 'app_strings.dart';

/// Забони фаъол (ru | tj | en) + соҳаи ширкат + номҳои ихтиёрӣ.
/// Дар MaterialApp.builder гузошта мешавад, ҳамин тавр [BuildContext.tr] дар ҳама ҷо кор мекунад
/// ва истилоҳот аз рӯи соҳа (клиника, сохтмон...) худкор иваз мешавад.
class AppLang extends InheritedWidget {
  final String code;
  final String industry;
  final Map<String, String> labels;

  const AppLang({
    super.key,
    required this.code,
    this.industry = 'real_estate',
    this.labels = const {},
    required super.child,
  });

  static AppLang? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppLang>();

  static String codeOf(BuildContext context) => maybeOf(context)?.code ?? 'ru';

  @override
  bool updateShouldNotify(AppLang oldWidget) =>
      code != oldWidget.code || industry != oldWidget.industry || !mapEquals(labels, oldWidget.labels);
}

class S {
  S._();

  /// Тартиби ҷустуҷӯ: номи ихтиёрии ширкат -> истилоҳоти соҳа -> матни умумӣ (ru -> калид).
  static String lookup(
    String code,
    String key, [
    Map<String, String>? args,
    String? industry,
    Map<String, String>? labels,
  ]) {
    var s = labels?[key] ??
        kIndustries[industry]?.overrides[code]?[key] ??
        kStrings[code]?[key] ??
        kStrings['ru']?[key] ??
        key;
    if (args != null) {
      args.forEach((k, v) {
        s = s.replaceAll('{$k}', v);
      });
    }
    return s;
  }
}

extension TrContext on BuildContext {
  String tr(String key, [Map<String, String>? args]) {
    final l = AppLang.maybeOf(this);
    return S.lookup(l?.code ?? 'ru', key, args, l?.industry, l?.labels);
  }

  String get lang => AppLang.codeOf(this);
}
