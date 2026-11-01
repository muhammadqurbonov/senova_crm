// Тестҳои воҳидӣ. Иҷро: flutter test
// (Дар муҳити таҳияи ин лоиҳа Flutter SDK набуд — ин тестҳо дар компютери шумо бояд иҷро шаванд.)
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:imkon_crm/core/l10n/app_lang.dart';
import 'package:imkon_crm/core/l10n/app_strings.dart';
import 'package:imkon_crm/core/permissions.dart';
import 'package:imkon_crm/core/theme/app_colors.dart';
import 'package:imkon_crm/features/dashboard/dashboard_metrics.dart';
import 'package:imkon_crm/models/customer_model.dart';
import 'package:imkon_crm/models/deal_model.dart';
import 'package:imkon_crm/models/pipeline_stage_model.dart';
import 'package:imkon_crm/models/task_model.dart';
import 'package:imkon_crm/models/user_model.dart';

AppUser user(UserRole r, {bool active = true, bool sa = false}) =>
    AppUser(uid: 'u', name: 'n', email: 'e', orgId: 'o', role: r, active: active, isSuperAdmin: sa);

PipelineStage stage(String key, {String type = 'open', String? id}) =>
    PipelineStage(id: id ?? 'o_$key', key: key, orgId: 'o', nameTj: key, nameRu: key, order: 0, type: type);

Customer cust(String id, String stageId, {String? manager}) => Customer(
    id: id, orgId: 'o', name: id, phone: '', source: LeadSource.manual, stageId: stageId,
    managerId: manager, createdAt: DateTime(2026), updatedAt: DateTime(2026));

void main() {
  group('Permissions', () {
    test('admin can do everything in org', () {
      final u = user(UserRole.admin);
      expect(Permissions.canWrite(u), isTrue);
      expect(Permissions.canDelete(u), isTrue);
      expect(Permissions.canManageEmployees(u), isTrue);
      expect(Permissions.canAccessSettings(u), isTrue);
    });
    test('manager can write but not delete or open settings', () {
      final u = user(UserRole.manager);
      expect(Permissions.canWrite(u), isTrue);
      expect(Permissions.canDelete(u), isFalse);
      expect(Permissions.canAccessSettings(u), isFalse);
    });
    test('viewer is read-only', () {
      final u = user(UserRole.viewer);
      expect(Permissions.canWrite(u), isFalse);
      expect(Permissions.canClaimLeads(u), isFalse);
    });
    test('inactive user has no permissions', () {
      final u = user(UserRole.admin, active: false);
      expect(Permissions.canWrite(u), isFalse);
      expect(Permissions.canDelete(u), isFalse);
    });
    test('only super admin manages organizations', () {
      expect(Permissions.canManageOrganizations(user(UserRole.admin)), isFalse);
      expect(Permissions.canManageOrganizations(user(UserRole.admin, sa: true)), isTrue);
    });
    test('unknown role string falls back to viewer', () {
      expect(UserRoleX.fromString('hacker'), UserRole.viewer);
      expect(AppUser.fromMap('x', {'orgId': 'o'}).role, UserRole.manager); // legacy: нақш набошад
    });
  });

  group('PipelineStage', () {
    test('matches both short key and legacy full doc id', () {
      final s = stage('tamos');
      expect(s.matches('tamos'), isTrue);
      expect(s.matches('o_tamos'), isTrue);
      expect(s.matches(''), isFalse);
      expect(s.matches('other'), isFalse);
    });
    test('system stages detected by key or type', () {
      expect(stage('mizoj_shud').isWon, isTrue);
      expect(stage('custom', type: 'lost').isLost, isTrue);
      expect(stage('custom').isWon, isFalse);
    });
    test('name falls back between languages', () {
      final s = PipelineStage(id: 'a', key: 'a', orgId: 'o', nameTj: 'Тоҷ', nameRu: '', order: 0);
      expect(s.name('ru'), 'Тоҷ');
      expect(s.name('en'), 'Тоҷ');
    });
  });

  group('DashboardMetrics', () {
    final stages = [stage('lid_nav'), stage('mizoj_shud', type: 'won'), stage('rad_kard', type: 'lost')];
    test('counts, conversion and no-stage', () {
      final m = DashboardMetrics.compute(
        stages: stages,
        customers: [cust('1', 'lid_nav', manager: 'm'), cust('2', 'lid_nav'), cust('3', 'mizoj_shud', manager: 'm'), cust('4', 'o_rad_kard'), cust('5', 'zzz')],
        deals: [],
        tasks: [],
      );
      expect(m.totalLeads, 5);
      expect(m.inProgress, 1);
      expect(m.won, 1);
      expect(m.lost, 1);
      expect(m.withoutStage, 1);
      expect(m.conversionPercent, 20);
    });
    test('empty data does not divide by zero', () {
      final m = DashboardMetrics.compute(stages: [], customers: [], deals: [], tasks: []);
      expect(m.conversionPercent, 0);
    });
    test('deal values: open is pipeline, only closed is won value', () {
      final m = DashboardMetrics.compute(stages: stages, customers: [], tasks: [], deals: [
        Deal(id: 'd1', orgId: 'o', customerId: 'c', propertyId: 'p', amount: 100, createdAt: DateTime(2026)),
        Deal(id: 'd2', orgId: 'o', customerId: 'c', propertyId: 'p', amount: 50, status: 'closed', createdAt: DateTime(2026)),
        Deal(id: 'd3', orgId: 'o', customerId: 'c', propertyId: 'p', amount: 25, status: 'rejected', createdAt: DateTime(2026)),
      ]);
      expect(m.openDeals, 1);
      expect(m.openDealsValue, 100);
      expect(m.wonDealsValue, 50);
    });
    test('overdue tasks ignore done and tasks without due date', () {
      final now = DateTime(2026, 6, 1);
      AppTask t(String id, DateTime? due, bool done) => AppTask(id: id, orgId: 'o', customerId: '', customerName: '', title: id, dueDate: due, done: done, assignedTo: 'u', assignedToName: 'n');
      final m = DashboardMetrics.compute(stages: [], customers: [], deals: [], now: now, tasks: [
        t('a', DateTime(2026, 5, 1), false), t('b', DateTime(2026, 5, 1), true), t('c', null, false), t('d', DateTime(2026, 7, 1), false),
      ]);
      expect(m.overdueTasks, 1);
    });
  });

  group('Localization', () {
    test('Russian is complete and default fallback works', () {
      expect(S.lookup('ru', 'sign_in'), 'Войти');
      expect(S.lookup('tj', 'sign_in'), 'Ворид шудан');
      expect(S.lookup('en', 'sign_in'), 'Sign in');
      expect(S.lookup('xx', 'sign_in'), 'Войти');
      expect(S.lookup('ru', 'no_such_key'), 'no_such_key');
    });
    test('every language has exactly the same keys', () {
      final ru = kStrings['ru']!.keys.toSet();
      expect(kStrings['tj']!.keys.toSet(), ru);
      expect(kStrings['en']!.keys.toSet(), ru);
    });
    test('placeholders are substituted', () {
      expect(S.lookup('en', 'delete_body', {'name': 'X'}), contains('"X"'));
    });
  });

  group('AppColors', () {
    test('fromHex parses and never throws', () {
      expect(AppColors.fromHex('#22C55E'), const Color(0xFF22C55E));
      expect(AppColors.fromHex('garbage'), AppColors.primary);
      expect(AppColors.fromHex('#GGGGGG'), AppColors.primary);
    });
  });
}
