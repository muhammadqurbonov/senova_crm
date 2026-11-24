/// Майдони иловагии корбарӣ (барои мизоҷ ё барои элементи феҳрист).
class CustomFieldDef {
  static const List<String> types = ['text', 'number', 'select', 'bool', 'date'];

  final String id;
  final String label;
  final String type;
  final List<String> options;
  final bool required;

  const CustomFieldDef({
    required this.id,
    required this.label,
    this.type = 'text',
    this.options = const [],
    this.required = false,
  });

  Map<String, dynamic> toMap() => {'id': id, 'label': label, 'type': type, 'options': options, 'required': required};

  factory CustomFieldDef.fromMap(Map<String, dynamic> m) {
    final t = '${m['type'] ?? 'text'}';
    return CustomFieldDef(
      id: '${m['id'] ?? ''}',
      label: '${m['label'] ?? ''}',
      type: types.contains(t) ? t : 'text',
      options: [for (final o in (m['options'] as List? ?? const [])) '$o'],
      required: m['required'] == true,
    );
  }
}

/// Контакти ширкат дар мессенҷер/шабака: Telegram, WhatsApp, Instagram, сайт ва ғ. (танҳо истинод, бе токен).
class ChannelContact {
  final String id;
  final String type;
  final String value;
  final String label;

  const ChannelContact({required this.id, required this.type, required this.value, this.label = ''});

  Map<String, dynamic> toMap() => {'id': id, 'type': type, 'value': value, 'label': label};

  factory ChannelContact.fromMap(Map<String, dynamic> m) => ChannelContact(
        id: '${m['id'] ?? ''}',
        type: '${m['type'] ?? 'other'}',
        value: '${m['value'] ?? ''}',
        label: '${m['label'] ?? ''}',
      );
}

/// Танзимоти ширкат (дар organizations/{id} нигоҳ дошта мешавад ва аз ҷониби Super Admin идора мешавад).
class OrgConfig {
  static const List<String> allModules = ['items', 'deals', 'tasks'];

  final String industry;
  final List<String> modules;
  final Map<String, String> labels; // customers | items | deals -> номи ихтиёрӣ
  final List<CustomFieldDef> customerFields;
  final List<CustomFieldDef> itemFields;
  final Map<String, Map<String, dynamic>> integrations;
  final List<ChannelContact> contacts;

  const OrgConfig({
    this.industry = 'real_estate',
    this.modules = allModules,
    this.labels = const {},
    this.customerFields = const [],
    this.itemFields = const [],
    this.integrations = const {},
    this.contacts = const [],
  });

  bool hasModule(String m) => modules.contains(m);
  bool get isRealEstate => industry == 'real_estate';

  /// Номҳои ихтиёрӣ ҳамчун override-и калидҳои тарҷума (барои ҳамаи забонҳо).
  Map<String, String> get overrides {
    final m = <String, String>{};
    void put(List<String> keys, String? v) {
      if (v == null || v.trim().isEmpty) return;
      for (final k in keys) {
        m[k] = v.trim();
      }
    }

    put(['nav_customers'], labels['customers']);
    put(['nav_properties', 'properties_title'], labels['items']);
    put(['nav_deals', 'deals_title'], labels['deals']);
    return m;
  }

  static List<CustomFieldDef> _fields(dynamic raw) {
    if (raw is! List) return const [];
    final out = <CustomFieldDef>[];
    for (final e in raw) {
      if (e is Map) {
        final f = CustomFieldDef.fromMap(Map<String, dynamic>.from(e));
        if (f.id.isNotEmpty && f.label.isNotEmpty) out.add(f);
      }
    }
    return out;
  }

  static List<ChannelContact> _contacts(dynamic raw) {
    if (raw is! List) return const [];
    final out = <ChannelContact>[];
    for (final e in raw) {
      if (e is Map) {
        final c = ChannelContact.fromMap(Map<String, dynamic>.from(e));
        if (c.id.isNotEmpty && c.value.isNotEmpty) out.add(c);
      }
    }
    return out;
  }

  factory OrgConfig.fromMap(Map<String, dynamic> data) {
    final cf = data['customFields'];
    final integ = <String, Map<String, dynamic>>{};
    final rawInteg = data['integrations'];
    if (rawInteg is Map) {
      rawInteg.forEach((k, v) {
        if (v is Map) integ['$k'] = Map<String, dynamic>.from(v);
      });
    }
    final rawLabels = data['labels'];
    return OrgConfig(
      industry: (data['industry'] as String?) ?? 'real_estate', // ширкатҳои кӯҳна — амвол
      modules: data['modules'] is List ? [for (final m in data['modules'] as List) '$m'] : allModules,
      labels: rawLabels is Map ? {for (final e in rawLabels.entries) '${e.key}': '${e.value}'} : const {},
      customerFields: _fields(cf is Map ? cf['customer'] : null),
      itemFields: _fields(cf is Map ? cf['item'] : null),
      integrations: integ,
      contacts: _contacts(data['contacts']),
    );
  }

  /// Майдонҳои сатҳи боло барои update() дар organizations/{id} (бе integrations — онро сервер идора мекунад).
  Map<String, dynamic> toUpdate() => {
        'industry': industry,
        'modules': modules,
        'labels': labels,
        'customFields': {
          'customer': [for (final f in customerFields) f.toMap()],
          'item': [for (final f in itemFields) f.toMap()],
        },
        'contacts': [for (final c in contacts) c.toMap()],
      };
}
