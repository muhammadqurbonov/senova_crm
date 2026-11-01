/// Ҳадди болоии ҳуҷҷатҳо дар як query (ҳимоя аз хондани тамоми collection).
const int kQueryLimit = 1000;

/// Калидҳои stage-ҳои системавӣ (бо онҳо мантиқи сделка ва dashboard кор мекунад).
class StageKeys {
  StageKeys._();
  static const String newLead = 'lid_nav';
  static const String won = 'mizoj_shud';
  static const String lost = 'rad_kard';
}

class DealStatus {
  DealStatus._();
  static const String open = 'open';
  static const String closed = 'closed';
  static const String rejected = 'rejected';
}

class OrgStatus {
  OrgStatus._();
  static const String active = 'active';
  static const String suspended = 'suspended';
}

const List<String> kLanguages = ['ru', 'tj', 'en'];
