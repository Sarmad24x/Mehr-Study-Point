import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import 'auth_provider.dart';
import '../models/fee_model.dart';

final feesStreamProvider = StreamProvider.autoDispose<List<FeeModel>>((ref) {
  // Restart stream on auth state change
  ref.watch(authStateProvider);
  return ref.watch(feeServiceProvider).getFeesStream();
});

final feeSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final filteredFeesProvider = Provider.autoDispose<List<FeeModel>>((ref) {
  final feesAsync = ref.watch(feesStreamProvider);
  final searchQuery = ref.watch(feeSearchQueryProvider).toLowerCase();

  return feesAsync.when(
    data: (fees) {
      if (searchQuery.isEmpty) return fees;
      return fees.where((fee) {
        return fee.studentId.toLowerCase().contains(searchQuery) ||
            fee.status.name.toLowerCase().contains(searchQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
