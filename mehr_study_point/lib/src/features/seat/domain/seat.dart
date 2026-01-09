import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'seat.g.dart';

@HiveType(typeId: 1)
enum SeatStatus {
  @HiveField(0)
  available,
  @HiveField(1)
  reserved,
  @HiveField(2)
  maintenance,
}

@HiveType(typeId: 2)
class Seat extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final int seatNumber;
  @HiveField(2)
  final SeatStatus status;
  @HiveField(3)
  final String? zone;
  @HiveField(4)
  final String? studentId;

  const Seat({
    required this.id,
    required this.seatNumber,
    required this.status,
    this.zone,
    this.studentId,
  });

  @override
  List<Object?> get props => [id, seatNumber, status, zone, studentId];

  factory Seat.fromMap(Map<String, dynamic> map) {
    return Seat(
      id: map['id'] as String,
      seatNumber: map['seat_number'] as int,
      status: SeatStatus.values.firstWhere(
            (e) => e.toString() == 'SeatStatus.${map['status']}',
        orElse: () => SeatStatus.available,
      ),
      zone: map['zone'] as String?,
      studentId: map['student_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seat_number': seatNumber,
      'status': status.toString().split('.').last,
      'zone': zone,
      'student_id': studentId,
    };
  }
}
