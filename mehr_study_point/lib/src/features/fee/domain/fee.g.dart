// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeeAdapter extends TypeAdapter<Fee> {
  @override
  final int typeId = 4;

  @override
  Fee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Fee(
      id: fields[0] as String,
      studentId: fields[1] as String,
      amount: fields[2] as double,
      dueDate: fields[3] as DateTime,
      paidDate: fields[4] as DateTime?,
      status: fields[5] as FeeStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Fee obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.paidDate)
      ..writeByte(5)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FeeStatusAdapter extends TypeAdapter<FeeStatus> {
  @override
  final int typeId = 3;

  @override
  FeeStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FeeStatus.pending;
      case 1:
        return FeeStatus.paid;
      case 2:
        return FeeStatus.overdue;
      default:
        return FeeStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, FeeStatus obj) {
    switch (obj) {
      case FeeStatus.pending:
        writer.writeByte(0);
        break;
      case FeeStatus.paid:
        writer.writeByte(1);
        break;
      case FeeStatus.overdue:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
