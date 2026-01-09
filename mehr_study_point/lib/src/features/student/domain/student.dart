import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'student.g.dart';

@HiveType(typeId: 0)
class Student extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String fullName;
  @HiveField(2)
  final String contactNumber;
  @HiveField(3)
  final String? guardianName;
  @HiveField(4)
  final String? guardianContactNumber;
  @HiveField(5)
  final String address;
  @HiveField(6)
  final DateTime admissionDate;
  @HiveField(7)
  final bool isActive;
  @HiveField(8)
  final String? assignedSeatId;

  const Student({
    required this.id,
    required this.fullName,
    required this.contactNumber,
    this.guardianName,
    this.guardianContactNumber,
    required this.address,
    required this.admissionDate,
    required this.isActive,
    this.assignedSeatId,
  });

  @override
  List<Object?> get props => [
        id,
        fullName,
        contactNumber,
        guardianName,
        guardianContactNumber,
        address,
        admissionDate,
        isActive,
        assignedSeatId,
      ];

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      contactNumber: map['contact_number'] as String,
      guardianName: map['guardian_name'] as String?,
      guardianContactNumber: map['guardian_contact_number'] as String?,
      address: map['address'] as String,
      admissionDate: DateTime.parse(map['admission_date'] as String),
      isActive: map['is_active'] as bool,
      assignedSeatId: map['assigned_seat_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'contact_number': contactNumber,
      'guardian_name': guardianName,
      'guardian_contact_number': guardianContactNumber,
      'address': address,
      'admission_date': admissionDate.toIso8601String(),
      'is_active': isActive,
      'assigned_seat_id': assignedSeatId,
    };
  }
}
