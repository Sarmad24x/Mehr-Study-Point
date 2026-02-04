
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/dashboard_provider.dart';

class OccupancyCard extends StatelessWidget {
  final DashboardStats stats;

  const OccupancyCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final occupied = stats.totalSeats - stats.availableSeats;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: theme.colorScheme.outline.withOpacity(0.2)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seat Occupancy',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                        value: stats.availableSeats.toDouble(),
                        color: const Color(0xFF4CAF50),
                        radius: 18,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: occupied.toDouble(),
                        color: theme.colorScheme.error,
                        radius: 18,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${stats.availableSeats}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Available',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(context, 'Available', const Color(0xFF4CAF50)),
              const SizedBox(width: 24),
              _buildLegendItem(context, 'Occupied', theme.colorScheme.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
