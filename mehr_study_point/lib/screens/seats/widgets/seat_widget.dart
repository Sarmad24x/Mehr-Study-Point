
import 'package:flutter/material.dart';
import '../../../models/seat_model.dart';

class SeatWidget extends StatelessWidget {
  final SeatModel seat;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SeatWidget({
    super.key,
    required this.seat,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  Color _getStatusColor() {
    switch (seat.status) {
      case SeatStatus.available: return const Color(0xFF2ECC71);
      case SeatStatus.reserved: return const Color(0xFFE74C3C);
      case SeatStatus.maintenance: return const Color(0xFFE67E22);
      case SeatStatus.held: return const Color(0xFF3498DB);
    }
  }

  IconData _getStatusIcon() {
    switch (seat.status) {
      case SeatStatus.available:
      case SeatStatus.reserved:
        return Icons.chair_rounded;
      case SeatStatus.maintenance:
        return Icons.build_rounded;
      case SeatStatus.held:
        return Icons.lock_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final icon = _getStatusIcon();
    
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isSelected ? Colors.white : color,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              seat.seatNumber,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
