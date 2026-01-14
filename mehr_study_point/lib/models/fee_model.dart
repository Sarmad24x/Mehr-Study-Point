import 'package:hive/hive.dart';

part 'fee_model.g.dart';

@HiveType(typeId: 5)
enum FeeStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  paid,
  @HiveField(2)
  overdue,
  @HiveField(3)
  partial,
}

@HiveType(typeId: 6)
class FeeModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String studentId;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final double paidAmount;
  @HiveField(4)
  final DateTime dueDate;
  @HiveField(5)
  final DateTime? paidDate;
  @HiveField(6)
  final FeeStatus status;
  @HiveField(7)
  final String type; // Admission, Monthly, Late, Waiver

  FeeModel({
    required this.id,
    required this.studentId,
    required this.amount,
    this.paidAmount = 0.0,
    required this.dueDate,
    this.paidDate,
    required this.status,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'amount': amount,
      'paidAmount': paidAmount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status.name,
      'type': type,
    };
  }

  factory FeeModel.fromMap(Map<String, dynamic> map) {
    return FeeModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
      paidDate: map['paidDate'] != null ? DateTime.parse(map['paidDate']) : null,
      status: FeeStatus.values.byName(map['status'] ?? 'pending'),
      type: map['type'] ?? 'Monthly',
    );
  }
}
