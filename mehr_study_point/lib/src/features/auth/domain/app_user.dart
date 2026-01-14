import 'package:equatable/equatable.dart';

enum UserRole { admin, superAdmin, employee }

class AppUser extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, email, fullName, role, isActive];

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role'] as String).toLowerCase(),
        orElse: () => UserRole.employee,
      ),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'is_active': isActive,
    };
  }
}
