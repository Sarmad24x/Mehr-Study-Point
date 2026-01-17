// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeeModelAdapter extends TypeAdapter<FeeModel> {
  @override
  final int typeId = 6;

  @override
  FeeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeeModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      amount: fields[2] as double,
      paidAmount: fields[3] as double,
      dueDate: fields[4] as DateTime,
      paidDate: fields[5] as DateTime?,
      status: fields[6] as FeeStatus,
      type: fields[7] as String,
      paymentMethod: fields[8] as String?,
      notes: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FeeModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.paidAmount)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.paidDate)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.type)
      ..writeByte(8)
      ..write(obj.paymentMethod)
      ..writeByte(9)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FeeStatusAdapter extends TypeAdapter<FeeStatus> {
  @override
  final int typeId = 5;

  @override
  FeeStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FeeStatus.pending;
      case 1:
        return FeeStatus.paid;
      case 2:
        return FeeStatus.overdue;
      case 3:
        return FeeStatus.partial;
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
      case FeeStatus.partial:
        writer.writeByte(3);
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
