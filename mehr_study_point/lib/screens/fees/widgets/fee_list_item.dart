
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/fee_model.dart';
import 'status_chip.dart';

class FeeListItem extends StatelessWidget {
  final FeeModel fee;
  final String studentName;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const FeeListItem({
    super.key,
    required this.fee,
    required this.studentName,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = fee.amount - fee.paidAmount;

    Color statusColor;
    IconData statusIcon;
    Color iconBgColor;

    switch (fee.status) {
      case FeeStatus.paid:
        statusColor = Colors.green.shade700;
        iconBgColor = Colors.green.shade50;
        statusIcon = Icons.check_circle_outline;
        break;
      case FeeStatus.pending:
        statusColor = Colors.orange.shade700;
        iconBgColor = Colors.orange.shade50;
        statusIcon = Icons.hourglass_empty;
        break;
      case FeeStatus.overdue:
        statusColor = Colors.red.shade700;
        iconBgColor = Colors.red.shade50;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case FeeStatus.partial:
        statusColor = Colors.blue.shade700;
        iconBgColor = Colors.blue.shade50;
        statusIcon = Icons.account_balance_wallet_outlined;
        break;
    }

    if (Theme.of(context).brightness == Brightness.dark) {
      iconBgColor = statusColor.withOpacity(0.15);
    }

    return Card(
      elevation: isSelected ? 4 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected 
          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
          : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: isSelectionMode 
          ? Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
              shape: const CircleBorder(),
            )
          : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          '${fee.type} • Rs. ${fee.amount.toInt()} • Due: ${DateFormat('dd MMM').format(fee.dueDate)}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusChip(status: fee.status),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Owed: ${remaining.toInt()}',
                  style: TextStyle(fontSize: 11, color: Colors.red.shade400),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
