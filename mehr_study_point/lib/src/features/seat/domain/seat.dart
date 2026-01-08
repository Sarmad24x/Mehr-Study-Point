import 'package:equatable/equatable.dart';

enum SeatStatus {
  available,
  reserved,
  maintenance,
}

class Seat extends Equatable {
  final String id;
  final int seatNumber;
  final SeatStatus status;
  final String? zone;
  final String? studentId; // The ID of the student who has reserved the seat

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
