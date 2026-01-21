import 'package:hive/hive.dart';

part 'student_model.g.dart';

@HiveType(typeId: 2)
class StudentModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String fullName;
  @HiveField(2)
  final String contactNumber;
  @HiveField(3)
  final String? guardianName;
  @HiveField(4)
  final String? guardianContact;
  @HiveField(5)
  final String address;
  @HiveField(6)
  final DateTime admissionDate;
  @HiveField(7)
  final String status; // Active, Inactive, Archived
  @HiveField(8)
  final String? assignedSeatId;
  @HiveField(9)
  final String? assignedSeatNumber;
  @HiveField(10)
  final double monthlyFee;
  @HiveField(11)
  final DateTime? leaveDate;

  StudentModel({
    required this.id,
    required this.fullName,
    required this.contactNumber,
    this.guardianName,
    this.guardianContact,
    required this.address,
    required this.admissionDate,
    required this.status,
    this.assignedSeatId,
    this.assignedSeatNumber,
    this.monthlyFee = 2000.0,
    this.leaveDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'contactNumber': contactNumber,
      'guardianName': guardianName,
      'guardianContact': guardianContact,
      'address': address,
      'admissionDate': admissionDate.toIso8601String(),
      'status': status,
      'assignedSeatId': assignedSeatId,
      'assignedSeatNumber': assignedSeatNumber,
      'monthlyFee': monthlyFee,
      'leaveDate': leaveDate?.toIso8601String(),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      guardianName: map['guardianName'],
      guardianContact: map['guardianContact'],
      address: map['address'] ?? '',
      admissionDate: DateTime.parse(map['admissionDate'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'Active',
      assignedSeatId: map['assignedSeatId'],
      assignedSeatNumber: map['assignedSeatNumber'],
      monthlyFee: (map['monthlyFee'] as num?)?.toDouble() ?? 2000.0,
      leaveDate: map['leaveDate'] != null ? DateTime.parse(map['leaveDate']) : null,
    );
  }

  StudentModel copyWith({
    String? fullName,
    String? contactNumber,
    String? guardianName,
    String? guardianContact,
    String? address,
    DateTime? admissionDate,
    String? status,
    String? assignedSeatId,
    String? assignedSeatNumber,
    double? monthlyFee,
    DateTime? leaveDate,
  }) {
    return StudentModel(
      id: id,
      fullName: fullName ?? this.fullName,
      contactNumber: contactNumber ?? this.contactNumber,
      guardianName: guardianName ?? this.guardianName,
      guardianContact: guardianContact ?? this.guardianContact,
      address: address ?? this.address,
      admissionDate: admissionDate ?? this.admissionDate,
      status: status ?? this.status,
      assignedSeatId: assignedSeatId ?? this.assignedSeatId,
      assignedSeatNumber: assignedSeatNumber ?? this.assignedSeatNumber,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      leaveDate: leaveDate ?? this.leaveDate,
    );
  }
}
