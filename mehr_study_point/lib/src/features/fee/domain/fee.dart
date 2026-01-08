import 'package:equatable/equatable.dart';

enum FeeStatus {
  pending,
  paid,
  overdue,
}

class Fee extends Equatable {
  final String id;
  final String studentId;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
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
      // id is handled by the database
      'student_id': studentId,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}
