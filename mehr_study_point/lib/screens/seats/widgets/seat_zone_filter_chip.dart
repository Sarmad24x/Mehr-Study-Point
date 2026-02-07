
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/seat_provider.dart';

class SeatZoneFilterChip extends ConsumerWidget {
  final String label;
  final String? value;

  const SeatZoneFilterChip({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(seatZoneFilterProvider);
    final isSelected = currentFilter == value;
    
    return GestureDetector(
      onTap: () {
        ref.read(seatZoneFilterProvider.notifier).state = isSelected ? null : value;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.shade700 
              : (Theme.of(context).brightness == Brightness.light ? Colors.grey[100] : Colors.grey[900]),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blueGrey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
