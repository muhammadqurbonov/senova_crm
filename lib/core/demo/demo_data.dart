import '../../models/customer_model.dart';
import '../../models/deal_model.dart';
import '../../models/note_model.dart';
import '../../models/pipeline_stage_model.dart';
import '../../models/property_model.dart';
import '../../models/task_model.dart';
import '../constants.dart';
import '../industries.dart';

/// Маълумоти хаёлии демо барои ҳар соҳа. Ҳеҷ вақт ба Firestore навишта/хонда намешавад.
class DemoData {
  DemoData._();

  static const _people = [
    ['Фарҳод Раҳимов', '+992 900 11 22 33'],
    ['Нигора Каримова', '+992 918 45 67 89'],
    ['Алексей Петров', '+992 933 21 43 65'],
    ['Зарина Саидова', '+992 907 98 76 54'],
    ['Шоҳрух Ҷӯраев', '+992 935 11 00 22'],
    ['Мадина Алиева', '+992 927 33 44 55'],
    ['Дмитрий Орлов', '+992 888 12 12 12'],
    ['Ситора Назарова', '+992 904 77 88 99'],
  ];

  static IndustryPreset _p(String orgId) => presetOf(demoIndustryOf(orgId));

  static List<PipelineStage> stages(String orgId) {
    final p = _p(orgId);
    return [
      for (var i = 0; i < p.stages.length; i++)
        PipelineStage(
          id: '${orgId}_${p.stages[i].key}',
          key: p.stages[i].key,
          orgId: orgId,
          nameTj: p.stages[i].tj,
          nameRu: p.stages[i].ru,
          nameEn: p.stages[i].en,
          order: i,
          color: p.stages[i].color,
          type: p.stages[i].type,
        ),
    ];
  }

  static List<Customer> customers(String orgId) {
    final keys = _p(orgId).stages.map((s) => s.key).toList();
    final stageIdx = [0, 0, 1, 1, 2, 3, 4, 5];
    final sources = [
      LeadSource.telegram, LeadSource.whatsapp, LeadSource.instagram, LeadSource.facebook,
      LeadSource.manual, LeadSource.whatsapp, LeadSource.telegram, LeadSource.instagram,
    ];
    final claimed = [false, true, true, false, true, true, true, true];
    final now = DateTime.now();
    return [
      for (var i = 0; i < _people.length; i++)
        Customer(
          id: 'c${i + 1}',
          orgId: orgId,
          name: _people[i][0],
          phone: _people[i][1],
          source: sources[i],
          stageId: keys[stageIdx[i]],
          managerId: claimed[i] ? 'demo_mgr' : null,
          managerName: claimed[i] ? 'Demo' : null,
          createdAt: now.subtract(Duration(days: 12 - i)),
          updatedAt: now,
        ),
    ];
  }

  static List<Property> items(String orgId) {
    final p = _p(orgId);
    final realEstate = p.id == 'real_estate';
    return [
      for (var i = 0; i < p.demoItems.length; i++)
        Property(
          id: 'p${i + 1}',
          orgId: orgId,
          titleTj: p.demoItems[i].tj,
          titleRu: p.demoItems[i].ru,
          price: p.demoItems[i].price,
          rooms: realEstate && i < 2 ? 3 - i : null,
          area: realEstate && i < 2 ? 95.0 - 30 * i : null,
          district: realEstate ? const ['Сино', 'Фирдавсӣ', 'Варзоб', 'Шоҳмансур'][i % 4] : '',
          status: i == 1 ? PropertyStatus.reserved : PropertyStatus.available,
        ),
    ];
  }

  static List<Deal> deals(String orgId) {
    final it = items(orgId);
    final now = DateTime.now();
    Deal d(String id, String cust, int itemIdx, String status, int daysAgo, {PaymentType pay = PaymentType.full}) => Deal(
          id: id,
          orgId: orgId,
          customerId: cust,
          propertyId: it[itemIdx % it.length].id,
          amount: it[itemIdx % it.length].price,
          paymentType: pay,
          status: status,
          createdAt: now.subtract(Duration(days: daysAgo)),
          closedAt: status == 'open' ? null : now.subtract(Duration(days: daysAgo - 1)),
        );
    return [
      d('d1', 'c5', 0, 'open', 3),
      d('d2', 'c6', 1, 'open', 5, pay: PaymentType.installment),
      d('d3', 'c7', 2, 'closed', 9),
      d('d4', 'c8', 0, 'rejected', 8),
    ];
  }

  static List<AppTask> tasks(String orgId) {
    final now = DateTime.now();
    AppTask t(String id, String cust, String custName, String title, int days, {bool done = false}) => AppTask(
          id: id,
          orgId: orgId,
          customerId: cust,
          customerName: custName,
          title: title,
          dueDate: now.add(Duration(days: days)),
          done: done,
          assignedTo: 'demo',
          assignedToName: 'Demo',
        );
    return [
      t('t1', 'c1', _people[0][0], 'Перезвонить клиенту', 1),
      t('t2', 'c5', _people[4][0], 'Отправить предложение', 2),
      t('t3', 'c6', _people[5][0], 'Подготовить договор', -1),
      t('t4', 'c7', _people[6][0], 'Закрыть документы', -3, done: true),
    ];
  }

  static List<Note> notes(String orgId, String customerId) {
    final now = DateTime.now();
    return [
      Note(id: 'n1', orgId: orgId, customerId: customerId, type: 'note', text: 'Клиент заинтересован, просит прислать детали.', authorName: 'Demo', createdAt: now.subtract(const Duration(hours: 5))),
      Note(id: 'n2', orgId: orgId, customerId: customerId, type: 'note', text: 'Первый контакт через мессенджер.', authorName: 'Demo', createdAt: now.subtract(const Duration(days: 2))),
    ];
  }
}
