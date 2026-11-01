import 'package:flutter/widgets.dart';
import 'l10n/app_lang.dart';

String formatAmount(num v) {
  return v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
}

String formatDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd.$mm.${d.year}';
}

String formatDateTime(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '${formatDate(d)} $hh:$mi';
}

extension MoneyX on BuildContext {
  String money(num v) => '${formatAmount(v)} ${tr('currency')}';
}
