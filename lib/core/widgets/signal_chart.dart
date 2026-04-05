import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';

class SignalChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Color        color;
  final double       minY;
  final double       maxY;
  final double       height;
  final String?      emptyLabel;

  const SignalChart({
    super.key,
    required this.spots,
    required this.color,
    required this.minY,
    required this.maxY,
    this.height     = 100,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            emptyLabel ?? 'En attente de données…',
            style: const TextStyle(
              color: AppColors.textHint, fontSize: 12))),
      );
    }

    return SizedBox(
      height: height,
      child: LineChart(LineChartData(
        minY: minY, maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.cardBorder, strokeWidth: 0.8)),
        borderData:    FlBorderData(show: false),
        titlesData:    const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots:     spots,
            isCurved:  true,
            color:     color,
            barWidth:  2.0,
            dotData:   const FlDotData(show: false),
            belowBarData: BarAreaData(
              show:  true,
              color: color.withValues(alpha: 0.08)),
          ),
        ],
      )),
    );
  }
}
