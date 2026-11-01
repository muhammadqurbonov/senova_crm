import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class PipelineStage {
  /// ID-и ҳуҷҷат дар Firestore (барои ширкатҳои нав: `${orgId}_${key}`).
  final String id;

  /// Калиди кӯтоҳи stage (масалан `lid_nav`) — ҳамин дар customers.stageId навишта мешавад.
  final String key;
  final String orgId;
  final String nameTj;
  final String nameRu;
  final String nameEn;
  final int order;
  final String color;

  /// 'open' | 'won' | 'lost'
  final String type;

  PipelineStage({
    required this.id,
    required this.key,
    required this.orgId,
    required this.nameTj,
    required this.nameRu,
    this.nameEn = '',
    required this.order,
    this.color = '#2F80ED',
    this.type = 'open',
  });

  /// Ном аз рӯи забон; агар тарҷума набошад — ба забони дигар бармегардад.
  String name(String lang) {
    switch (lang) {
      case 'ru':
        return nameRu.isNotEmpty ? nameRu : nameTj;
      case 'en':
        if (nameEn.isNotEmpty) return nameEn;
        return nameRu.isNotEmpty ? nameRu : nameTj;
      default:
        return nameTj.isNotEmpty ? nameTj : nameRu;
    }
  }

  /// Мизоҷ ба ин stage тааллуқ дорад? Ҳам калиди нав, ҳам ID-и ҳуҷҷати кӯҳна қабул мешавад
  /// (мутобиқат бо маълумоти пештара).
  bool matches(String stageId) => stageId.isNotEmpty && (stageId == key || stageId == id);

  bool get isWon => type == 'won' || key == StageKeys.won;
  bool get isLost => type == 'lost' || key == StageKeys.lost;
  bool get isSystem => key == StageKeys.won || key == StageKeys.lost;

  factory PipelineStage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final orgId = (data['orgId'] ?? '') as String;
    final prefix = '${orgId}_';
    final derivedKey = (orgId.isNotEmpty && doc.id.startsWith(prefix)) ? doc.id.substring(prefix.length) : doc.id;
    return PipelineStage(
      id: doc.id,
      key: (data['key'] as String?) ?? derivedKey,
      orgId: orgId,
      nameTj: data['name_tj'] ?? '',
      nameRu: data['name_ru'] ?? '',
      nameEn: data['name_en'] ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      color: data['color'] ?? '#2F80ED',
      type: data['type'] ?? 'open',
    );
  }
}

/// Stage-ҳои пешфарз барои ширкати нав. Калиди 'id' танҳо барои сохтани ID-и ҳуҷҷат истифода мешавад.
List<Map<String, dynamic>> defaultStagesData(String orgId) => [
      {'id': 'lid_nav', 'key': 'lid_nav', 'name_tj': 'Лид нав', 'name_ru': 'Новый лид', 'name_en': 'New lead', 'order': 0, 'color': '#63A4FF', 'type': 'open', 'orgId': orgId},
      {'id': 'tamos', 'key': 'tamos', 'name_tj': 'Тамос гирифта шуд', 'name_ru': 'Контакт установлен', 'name_en': 'Contacted', 'order': 1, 'color': '#8FA3BF', 'type': 'open', 'orgId': orgId},
      {'id': 'nishondihi', 'key': 'nishondihi', 'name_tj': 'Нишондиҳии мулк', 'name_ru': 'Показ объекта', 'name_en': 'Viewing', 'order': 2, 'color': '#2F80ED', 'type': 'open', 'orgId': orgId},
      {'id': 'muzokira', 'key': 'muzokira', 'name_tj': 'Музокира', 'name_ru': 'Переговоры', 'name_en': 'Negotiation', 'order': 3, 'color': '#F5A524', 'type': 'open', 'orgId': orgId},
      {'id': 'mizoj_shud', 'key': 'mizoj_shud', 'name_tj': 'Мизоҷ шуд', 'name_ru': 'Стал клиентом', 'name_en': 'Won', 'order': 4, 'color': '#22C55E', 'type': 'won', 'orgId': orgId},
      {'id': 'rad_kard', 'key': 'rad_kard', 'name_tj': 'Рад кард', 'name_ru': 'Отказ', 'name_en': 'Lost', 'order': 5, 'color': '#EF5350', 'type': 'lost', 'orgId': orgId},
    ];
