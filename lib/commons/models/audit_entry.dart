import 'json_read.dart';
import 'localized_text.dart';

class AuditEntry {
  final String id;
  final String action;
  final String actorName;
  final String actorType;
  final DateTime? at;
  final LocalizedText? branchName;
  final String entity;
  final String entityId;
  final String? oldValue;
  final String? newValue;
  final String? reason;

  const AuditEntry({
    required this.id,
    required this.action,
    required this.actorName,
    required this.actorType,
    required this.at,
    required this.branchName,
    required this.entity,
    required this.entityId,
    required this.oldValue,
    required this.newValue,
    required this.reason,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: readStr(json['id']),
        action: readStr(json['action']),
        actorName: readStr(json['actorName']),
        actorType: readStr(json['actorType']),
        at: readDate(json['at']),
        branchName: json['branchName'] == null ? null : LocalizedText.fromJson(json['branchName']),
        entity: readStr(json['entity']),
        entityId: readStr(json['entityId']),
        oldValue: readAnyText(json['oldValue']),
        newValue: readAnyText(json['newValue']),
        reason: readStrOrNull(json['reason']),
      );
}
