// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seat.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SeatAdapter extends TypeAdapter<Seat> {
  @override
  final int typeId = 2;

  @override
  Seat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Seat(
      id: fields[0] as String,
      seatNumber: fields[1] as int,
      status: fields[2] as SeatStatus,
      zone: fields[3] as String?,
      studentId: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Seat obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.seatNumber)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.zone)
      ..writeByte(4)
      ..write(obj.studentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SeatStatusAdapter extends TypeAdapter<SeatStatus> {
  @override
  final int typeId = 1;

  @override
  SeatStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SeatStatus.available;
      case 1:
        return SeatStatus.reserved;
      case 2:
        return SeatStatus.maintenance;
      default:
        return SeatStatus.available;
    }
  }

  @override
  void write(BinaryWriter writer, SeatStatus obj) {
    switch (obj) {
      case SeatStatus.available:
        writer.writeByte(0);
        break;
      case SeatStatus.reserved:
        writer.writeByte(1);
        break;
      case SeatStatus.maintenance:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeatStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
