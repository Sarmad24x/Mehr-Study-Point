import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/seat_model.dart';
import '../models/fee_model.dart';

class HiveService {
  static const String userBoxName = 'userBox';
  static const String studentBoxName = 'studentBox';
  static const String seatBoxName = 'seatBox';
  static const String feeBoxName = 'feeBox';
  static const String settingsBoxName = 'settingsBox';

  Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserRoleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UserModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(StudentModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SeatStatusAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(SeatModelAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(FeeStatusAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(FeeModelAdapter());

    // Open Boxes
    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox<StudentModel>(studentBoxName);
    await Hive.openBox<SeatModel>(seatBoxName);
    await Hive.openBox<FeeModel>(feeBoxName);
    await Hive.openBox(settingsBoxName);
  }

  // Generic methods for Hive operations
  Box<T> getBox<T>(String name) => Hive.box<T>(name);

  Future<void> clearAll() async {
    await Hive.box<UserModel>(userBoxName).clear();
    await Hive.box<StudentModel>(studentBoxName).clear();
    await Hive.box<SeatModel>(seatBoxName).clear();
    await Hive.box<FeeModel>(feeBoxName).clear();
  }
}
