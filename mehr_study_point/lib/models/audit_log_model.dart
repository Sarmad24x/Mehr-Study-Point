import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String userId;
  final String userName;
  final String action; // CREATE, UPDATE, DELETE
  final String entityType; // Student, Fee, Seat
  final String entityId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.oldValues,
    this.newValues,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'oldValues': oldValues,
      'newValues': newValues,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String id) {
    return AuditLogModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      action: map['action'] ?? '',
      entityType: map['entityType'] ?? '',
      entityId: map['entityId'] ?? '',
      oldValues: map['oldValues'],
      newValues: map['newValues'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
