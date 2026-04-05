import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';

class VitalsScreen extends ConsumerWidget {
  final String patientId;
  const VitalsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Données vitales 24h'),
        actions: [
          DropdownButton<String>(
            underline: const SizedBox(),
            value: '24h',
            items: const [
              DropdownMenuItem(value: '24h', child: Text('24h')),
              DropdownMenuItem(value: '7j',  child: Text('7 jours')),
              DropdownMenuItem(value: '30j', child: Text('30 jours')),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── FC ───────────────────────────────────────────
          _VitalChartCard(
            title: 'Fréquence cardiaque',
            unit: 'bpm',
            color: AppColors.heartColor,
            icon: Icons.favorite_rounded,
            minY: 40, maxY: 180,
            currentMin: 62, currentMax: 145,
            spots: _mockHeartData(),
            seizureTime: 3.0,
          ),
          const SizedBox(height: 12),

          // ── Accéléromètre ────────────────────────────────
          _VitalChartCard(
            title: 'Accéléromètre — Magnitude',
            unit: 'g',
            color: AppColors.accelColor,
            icon: Icons.speed_rounded,
            minY: 0, maxY: 5,
            currentMin: 0.3, currentMax: 4.2,
            spots: _mockAccelData(),
            seizureTime: 3.0,
          ),
          const SizedBox(height: 12),

          // ── GSR ──────────────────────────────────────────
          _VitalChartCard(
            title: 'Conductance cutanée',
            unit: '%',
            color: AppColors.gsrColor,
            icon: Icons.sensors_rounded,
            minY: 0, maxY: 100,
            currentMin: 20, currentMax: 85,
            spots: _mockGsrData(),
            seizureTime: 3.0,
          ),
          const SizedBox(height: 16),

          // ── Événements ───────────────────────────────────
          _EventsTimeline(),
        ],
      ),
    );
  }

  List<FlSpot> _mockHeartData() => List.generate(24,
    (i) => FlSpot(i.toDouble(),
      i == 3 ? 145 : 65 + (i % 5) * 3.0));

  List<FlSpot> _mockAccelData() => List.generate(24,
    (i) => FlSpot(i.toDouble(),
      i == 3 ? 4.2 : 0.3 + (i % 3) * 0.1));

  List<FlSpot> _mockGsrData() => List.generate(24,
    (i) => FlSpot(i.toDouble(),
      i == 3 ? 85 : 20 + (i % 4) * 5.0));
}

class _VitalChartCard extends StatelessWidget {
  final String title, unit;
  final Color  color;
  final IconData icon;
  final double minY, maxY, seizureTime;
  final double currentMin, currentMax;
  final List<FlSpot> spots;

  const _VitalChartCard({
    required this.title, required this.unit, required this.color,
    required this.icon, required this.minY, required this.maxY,
    required this.spots, required this.seizureTime,
    required this.currentMin, required this.currentMax,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 5)),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(
              'Min: ${currentMin.toStringAsFixed(1)} $unit  ·  Max: ${currentMax.toStringAsFixed(1)} $unit',
              style: TextStyle(fontSize: 11,
                color: color, fontWeight: FontWeight.w500)),
          ]),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: LineChart(LineChartData(
            minY: minY, maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.cardBorder, strokeWidth: 0.8)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (v, _) => v % 6 == 0
                    ? Text('${v.toInt()}h',
                        style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint))
                    : const SizedBox(),
                )),
            ),
            extraLinesData: ExtraLinesData(verticalLines: [
              VerticalLine(
                x: seizureTime,
                color: AppColors.seizureRed,
                strokeWidth: 1.5,
                dashArray: [4, 3],
                label: VerticalLineLabel(
                  show: true, labelResolver: (_) => 'Crise',
                  style: const TextStyle(
                    fontSize: 10, color: AppColors.seizureRed,
                    fontWeight: FontWeight.w600)),
              ),
            ]),
            lineBarsData: [LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true, color: color.withValues(alpha: 0.08)),
            )],
          )),
        ),
      ],
    ),
  );
}

class _EventsTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Événements détectés',
        style: TextStyle(fontSize: 13,
          fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      const SizedBox(height: 10),
      _EventRow(
        time: '02h44', label: 'Crise tonico-clonique',
        score: '0.94', duration: '1min 23s',
        color: AppColors.seizureRed),
    ],
  );
}

class _EventRow extends StatelessWidget {
  final String time, label, score, duration; final Color color;
  const _EventRow({required this.time, required this.label,
    required this.score, required this.duration, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 3)),
      ],
    ),
    child: Row(children: [
      Text(time, style: TextStyle(fontSize: 14,
        fontWeight: FontWeight.w700, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(
        fontSize: 13, color: AppColors.textPrimary))),
      Text('Score $score · $duration',
        style: TextStyle(fontSize: 12, color: color)),
    ]),
  );
}
