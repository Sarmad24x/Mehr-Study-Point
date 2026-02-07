
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'seat_model.g.dart';

@HiveType(typeId: 3)
enum SeatStatus {
  @HiveField(0)
  available,
  @HiveField(1)
  reserved,
  @HiveField(2)
  maintenance,
  @HiveField(3)
  held
}

@HiveType(typeId: 4)
class SeatModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String seatNumber;
  @HiveField(2)
  final SeatStatus status;
  @HiveField(3)
  final String? studentId;
  @HiveField(4)
  final String? zone; // Library area/wing
  @HiveField(5)
  final DateTime? holdExpiresAt;

  const SeatModel({
    required this.id,
    required this.seatNumber,
    required this.status,
    this.studentId,
    this.zone,
    this.holdExpiresAt,
  });

  @override
  List<Object?> get props => [id, seatNumber, status, studentId, zone, holdExpiresAt];

  SeatModel copyWith({
    String? id,
    String? seatNumber,
    SeatStatus? status,
    String? studentId,
    String? zone,
    DateTime? holdExpiresAt,
  }) {
    return SeatModel(
      id: id ?? this.id,
      seatNumber: seatNumber ?? this.seatNumber,
      status: status ?? this.status,
      studentId: studentId ?? this.studentId,
      zone: zone ?? this.zone,
      holdExpiresAt: holdExpiresAt ?? this.holdExpiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seatNumber': seatNumber,
      'status': status.name,
      'studentId': studentId,
      'zone': zone,
      'holdExpiresAt': holdExpiresAt?.toIso8601String(),
    };
  }

  factory SeatModel.fromMap(Map<String, dynamic> map) {
    return SeatModel(
      id: map['id'] ?? '',
      seatNumber: map['seatNumber'] ?? '',
      status: SeatStatus.values.byName(map['status'] ?? 'available'),
      studentId: map['studentId'],
      zone: map['zone'],
      holdExpiresAt: map['holdExpiresAt'] != null 
          ? DateTime.parse(map['holdExpiresAt']) 
          : null,
    );
  }
}
