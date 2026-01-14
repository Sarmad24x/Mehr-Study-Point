import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
enum UserRole {
  @HiveField(0)
  admin,
  @HiveField(1)
  employee,
}

@HiveType(typeId: 1)
class UserModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final UserRole role;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.byName(map['role'] ?? 'employee'),
    );
  }

  UserModel copyWith({
    String? name,
    UserRole? role,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}
