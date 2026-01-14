import 'package:hive/hive.dart';

part 'seat_model.g.dart';

@HiveType(typeId: 3)
enum SeatStatus {
  @HiveField(0)
  available,
  @HiveField(1)
  reserved,
  @HiveField(2)
  maintenance,
}

@HiveType(typeId: 4)
class SeatModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String seatNumber;
  @HiveField(2)
  final SeatStatus status;
  @HiveField(3)
  final String? studentId;
  @HiveField(4)
  final String? zone;

  SeatModel({
    required this.id,
    required this.seatNumber,
    required this.status,
    this.studentId,
    this.zone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seatNumber': seatNumber,
      'status': status.name,
      'studentId': studentId,
      'zone': zone,
    };
  }

  factory SeatModel.fromMap(Map<String, dynamic> map) {
    return SeatModel(
      id: map['id'] ?? '',
      seatNumber: map['seatNumber'] ?? '',
      status: SeatStatus.values.byName(map['status'] ?? 'available'),
      studentId: map['studentId'],
      zone: map['zone'],
    );
  }
}
