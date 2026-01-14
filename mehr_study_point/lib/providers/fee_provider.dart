import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import '../models/fee_model.dart';

final feesStreamProvider = StreamProvider<List<FeeModel>>((ref) {
  return ref.watch(feeServiceProvider).getFeesStream();
});

final feeSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredFeesProvider = Provider<List<FeeModel>>((ref) {
  final feesAsync = ref.watch(feesStreamProvider);
  final searchQuery = ref.watch(feeSearchQueryProvider).toLowerCase();

  return feesAsync.when(
    data: (fees) {
      if (searchQuery.isEmpty) return fees;
      // In a real app, we might want to join with Student names here.
      // For now, we'll just filter by Student ID or Status.
      return fees.where((fee) {
        return fee.studentId.toLowerCase().contains(searchQuery) ||
            fee.status.name.toLowerCase().contains(searchQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
