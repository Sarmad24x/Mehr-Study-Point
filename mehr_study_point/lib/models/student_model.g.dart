// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentModelAdapter extends TypeAdapter<StudentModel> {
  @override
  final int typeId = 2;

  @override
  StudentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentModel(
      id: fields[0] as String,
      fullName: fields[1] as String,
      contactNumber: fields[2] as String,
      guardianName: fields[3] as String?,
      guardianContact: fields[4] as String?,
      address: fields[5] as String,
      admissionDate: fields[6] as DateTime,
      status: fields[7] as String,
      assignedSeatId: fields[8] as String?,
      assignedSeatNumber: fields[9] as String?,
      monthlyFee: fields[10] as double,
    );
  }

  @override
  void write(BinaryWriter writer, StudentModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.contactNumber)
      ..writeByte(3)
      ..write(obj.guardianName)
      ..writeByte(4)
      ..write(obj.guardianContact)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.admissionDate)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.assignedSeatId)
      ..writeByte(9)
      ..write(obj.assignedSeatNumber)
      ..writeByte(10)
      ..write(obj.monthlyFee);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
