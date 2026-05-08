import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

final _patientOnlineProvider = StreamProvider.autoDispose
    .family<bool, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(patientId)
      .snapshots()
      .map((snap) => snap.data()?['vitals_live'] != null);
});

class VitalsScreen extends ConsumerStatefulWidget {
  final String patientId;
  const VitalsScreen({super.key, required this.patientId});

  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  String _range = '24h';

  double get _maxX => switch (_range) {
    '7j'  => 7  * 24,
    '30j' => 30 * 24,
    _     => 24,
  };

  double get _xInterval => switch (_range) {
    '7j'  => 24,   // toutes les 24h → affiche j1…j7
    '30j' => 120,  // toutes les 5j  → affiche j5…j30
    _     => 6,    // toutes les 6h  → affiche 0h…24h
  };

  String _xTitle(double v) => switch (_range) {
    '7j'  => 'j${(v / 24).toInt()}',
    '30j' => 'j${(v / 24).toInt()}',
    _     => '${v.toInt()}h',
  };

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(_patientOnlineProvider(widget.patientId))
        .maybeWhen(data: (v) => v, orElse: () => false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Données vitales'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          DropdownButton<String>(
            underline: const SizedBox(),
            value: _range,
            items: const [
              DropdownMenuItem(value: '24h', child: Text('24h')),
              DropdownMenuItem(value: '7j',  child: Text('7 jours')),
              DropdownMenuItem(value: '30j', child: Text('30 jours')),
            ],
            onChanged: (v) => setState(() => _range = v!),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        if (!isOnline) const _OfflineBanner(),
        Expanded(child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _VitalChartCard(
              title: 'Fréquence cardiaque',
              unit: 'bpm',
              color: AppColors.heartColor,
              icon: Icons.favorite_rounded,
              minY: 40, maxY: 180,
              maxX: _maxX, xInterval: _xInterval, xTitle: _xTitle,
            ),
            const SizedBox(height: 12),
            _VitalChartCard(
              title: 'Magnitude IMU',
              unit: 'g',
              color: AppColors.accelColor,
              icon: Icons.speed_rounded,
              minY: 0, maxY: 10,
              maxX: _maxX, xInterval: _xInterval, xTitle: _xTitle,
              imuThresholds: true,
            ),
            const SizedBox(height: 12),
            _VitalChartCard(
              title: 'Conductance cutanée',
              unit: '%',
              color: AppColors.gsrColor,
              icon: Icons.sensors_rounded,
              minY: 0, maxY: 100,
              maxX: _maxX, xInterval: _xInterval, xTitle: _xTitle,
            ),
            const SizedBox(height: 24),
          ],
        )),
      ]),
    );
  }
}

// ─── Offline banner ──────────────────────────────────────────
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.cardBorder)),
    child: const Row(children: [
      Icon(Icons.watch_off_rounded, size: 18, color: AppColors.textHint),
      SizedBox(width: 10),
      Text('Bracelet hors ligne',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary)),
    ]),
  );
}

// ─── Carte graphique ─────────────────────────────────────────
class _VitalChartCard extends StatelessWidget {
  final String          title, unit;
  final Color           color;
  final IconData        icon;
  final double          minY, maxY, maxX, xInterval;
  final String Function(double) xTitle;
  final bool            imuThresholds;

  const _VitalChartCard({
    required this.title,    required this.unit,
    required this.color,    required this.icon,
    required this.minY,     required this.maxY,
    required this.maxX,     required this.xInterval,
    required this.xTitle,
    this.imuThresholds = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10, offset: const Offset(0, 3)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── En-tête ──────────────────────────────────────
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
            Text('En attente du bracelet…',
              style: TextStyle(
                fontSize: 11, color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8)),
            child: Text(unit, style: const TextStyle(
              fontSize: 11, color: AppColors.textHint,
              fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 14),

        // ── Graphique vide avec échelle ───────────────────
        SizedBox(
          height: 120,
          child: LineChart(LineChartData(
            minY: minY, maxY: maxY,
            minX: 0,    maxX: maxX,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: imuThresholds ? 2.5 : null,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.cardBorder, strokeWidth: 0.8)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: imuThresholds ? 2.5 : null,
                  getTitlesWidget: (v, _) {
                    if (imuThresholds) {
                      return Text(
                        v % 1 == 0 ? '${v.toInt()}g' : '${v}g',
                        style: const TextStyle(
                          fontSize: 9, color: AppColors.textHint));
                    }
                    if (v == minY || v == maxY) {
                      return Text(v.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 9, color: AppColors.textHint));
                    }
                    return const SizedBox();
                  },
                )),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: xInterval,
                  getTitlesWidget: (v, _) => Text(xTitle(v),
                    style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint)),
                )),
            ),
            extraLinesData: imuThresholds
              ? ExtraLinesData(horizontalLines: [
                  HorizontalLine(y: 2.5,
                    color: AppColors.warning.withValues(alpha: 0.7),
                    strokeWidth: 1.2,
                    dashArray: [4, 3]),
                  HorizontalLine(y: 5.0,
                    color: AppColors.seizureRed.withValues(alpha: 0.7),
                    strokeWidth: 1.2,
                    dashArray: [4, 3]),
                ])
              : null,
            lineBarsData: const [],
          )),
        ),
        if (imuThresholds) ...[
          const SizedBox(height: 8),
          Row(children: [
            _ImuLegendItem(
              color: const Color(0xFF10B981), label: '< 2.5g  Faible'),
            const SizedBox(width: 12),
            _ImuLegendItem(
              color: AppColors.warning, label: '2.5–5g  Modéré'),
            const SizedBox(width: 12),
            _ImuLegendItem(
              color: AppColors.seizureRed, label: '> 5g  Élevé'),
          ]),
        ],
      ],
    ),
  );
}

class _ImuLegendItem extends StatelessWidget {
  final Color  color;
  final String label;
  const _ImuLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 7, height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(
        fontSize: 10, color: AppColors.textSecondary)),
    ],
  );
}
