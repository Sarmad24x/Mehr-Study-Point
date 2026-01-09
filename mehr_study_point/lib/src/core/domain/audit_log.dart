import 'package:equatable/equatable.dart';

enum AuditAction {
  create,
  update,
  delete,
  login,
  logout,
}

class AuditLog extends Equatable {
  final String? id;
  final String userId;
  final AuditAction actionType;
  final String tableName;
  final String recordId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? deviceInfo;
  final DateTime timestamp;

  const AuditLog({
    this.id,
    required this.userId,
    required this.actionType,
    required this.tableName,
    required this.recordId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.deviceInfo,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        actionType,
        tableName,
        recordId,
        oldValues,
        newValues,
        ipAddress,
        deviceInfo,
        timestamp,
      ];

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'action_type': actionType.toString().split('.').last.toUpperCase(),
      'table_name': tableName,
      'record_id': recordId,
      'old_values': oldValues,
      'new_values': newValues,
      'ip_address': ipAddress,
      'device_info': deviceInfo,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
