import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'fee.g.dart';

@HiveType(typeId: 3)
enum FeeStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  paid,
  @HiveField(2)
  overdue,
}

@HiveType(typeId: 4)
class Fee extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String studentId;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final DateTime dueDate;
  @HiveField(4)
  final DateTime? paidDate;
  @HiveField(5)
  final FeeStatus status;

  const Fee({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
  });

  @override
  List<Object?> get props => [id, studentId, amount, dueDate, paidDate, status];

  factory Fee.fromMap(Map<String, dynamic> map) {
    return Fee(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date'] as String),
      paidDate: map['paid_date'] != null ? DateTime.parse(map['paid_date'] as String) : null,
      status: FeeStatus.values.firstWhere(
        (e) => e.toString() == 'FeeStatus.${map['status']}',
        orElse: () => FeeStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}
