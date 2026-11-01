import 'package:flutter/widgets.dart';
import 'app_strings.dart';

/// Забони фаъол (ru | tj | en). Дар MaterialApp.builder гузошта мешавад,
/// ҳамин тавр [BuildContext.tr] дар ҳама ҷо (аз ҷумла dialog) кор мекунад.
class AppLang extends InheritedWidget {
  final String code;

  const AppLang({super.key, required this.code, required super.child});

  static String codeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLang>()?.code ?? 'ru';
  }

  @override
  bool updateShouldNotify(AppLang oldWidget) => code != oldWidget.code;
}

class S {
  S._();

  static String lookup(String code, String key, [Map<String, String>? args]) {
    var s = kStrings[code]?[key] ?? kStrings['ru']?[key] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        s = s.replaceAll('{$k}', v);
      });
    }
    return s;
  }
}

extension TrContext on BuildContext {
  String tr(String key, [Map<String, String>? args]) => S.lookup(AppLang.codeOf(this), key, args);
  String get lang => AppLang.codeOf(this);
}
