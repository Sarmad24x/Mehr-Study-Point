import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final double defaultAdmissionFee;
  final double defaultMonthlyFee;
  final double lateFeePerDay;
  final int lateFeeGracePeriod; // in days

  const AppSettings({
    required this.defaultAdmissionFee,
    required this.defaultMonthlyFee,
    required this.lateFeePerDay,
    required this.lateFeeGracePeriod,
  });

  @override
  List<Object?> get props => [
        defaultAdmissionFee,
        defaultMonthlyFee,
        lateFeePerDay,
        lateFeeGracePeriod,
      ];

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      defaultAdmissionFee: (map['default_admission_fee'] as num).toDouble(),
      defaultMonthlyFee: (map['default_monthly_fee'] as num).toDouble(),
      lateFeePerDay: (map['late_fee_per_day'] as num).toDouble(),
      lateFeeGracePeriod: map['late_fee_grace_period'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'default_admission_fee': defaultAdmissionFee,
      'default_monthly_fee': defaultMonthlyFee,
      'late_fee_per_day': lateFeePerDay,
      'late_fee_grace_period': lateFeeGracePeriod,
    };
  }
}
