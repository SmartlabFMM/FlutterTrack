import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/ble_provider.dart';
import '../../models/vital_signs_model.dart';

class LiveSignalsScreen extends ConsumerStatefulWidget {
  const LiveSignalsScreen({super.key});
  @override
  ConsumerState<LiveSignalsScreen> createState() => _LiveSignalsScreenState();
}

class _LiveSignalsScreenState extends ConsumerState<LiveSignalsScreen> {
  final List<FlSpot> _accelData = [];
  final List<FlSpot> _heartData = [];
  final List<FlSpot> _gsrData   = [];
  int _tick = 0;

  @override
  Widget build(BuildContext context) {
    // Mise à jour buffers graphiques via listener (évite la mutation dans build)
    ref.listen<BleState>(bleProvider, (prev, next) {
      if (next.latestVitals != null &&
          next.latestVitals != prev?.latestVitals) {
        final v = next.latestVitals!;
        setState(() {
          _tick++;
          _accelData.add(FlSpot(_tick.toDouble(), v.accelMagnitude));
          _heartData.add(FlSpot(_tick.toDouble(), v.heartRate.toDouble()));
          _gsrData.add(FlSpot(_tick.toDouble(), v.gsrValue * 100));
          if (_accelData.length > 60) {
            _accelData.removeAt(0);
            _heartData.removeAt(0);
            _gsrData.removeAt(0);
          }
        });
      }
    });

    final ble = ref.watch(bleProvider);
    final isConnected = ble.status == BleStatus.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signaux en direct'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected
                ? AppColors.tealPale : AppColors.dangerLight,
              borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Container(width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? AppColors.teal : AppColors.danger)),
              const SizedBox(width: 6),
              Text(isConnected ? 'En direct' : 'Déconnecté',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isConnected ? AppColors.tealDark : AppColors.danger)),
            ]),
          ),
        ],
      ),
      body: ble.seizureDetected
        ? _SeizureOverlay(score: ble.seizureScore,
            onDismiss: () => ref.read(bleProvider.notifier).clearSeizureAlert())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Résumé valeurs actuelles ─────────────────
              if (ble.latestVitals != null)
                _VitalsSummaryRow(vitals: ble.latestVitals!),
              const SizedBox(height: 16),

              // ── Graphique accéléromètre ──────────────────
              _SignalCard(
                title: AppStrings.accel,
                subtitle: 'Magnitude (g)',
                color: AppColors.accelColor,
                spots: _accelData,
                minY: 0, maxY: 4,
                unit: 'g',
              ),
              const SizedBox(height: 12),

              // ── Graphique FC ─────────────────────────────
              _SignalCard(
                title: AppStrings.heartRate,
                subtitle: 'Battements / minute',
                color: AppColors.heartColor,
                spots: _heartData,
                minY: 40, maxY: 180,
                unit: 'bpm',
              ),
              const SizedBox(height: 12),

              // ── Graphique GSR ────────────────────────────
              _SignalCard(
                title: AppStrings.gsr,
                subtitle: 'Conductance normalisée (%)',
                color: AppColors.gsrColor,
                spots: _gsrData,
                minY: 0, maxY: 100,
                unit: '%',
              ),
            ],
          ),
    );
  }
}

// ─── SignalCard ──────────────────────────────────────────────
class _SignalCard extends StatelessWidget {
  final String       title, subtitle, unit;
  final Color        color;
  final List<FlSpot> spots;
  final double       minY, maxY;

  const _SignalCard({
    required this.title, required this.subtitle, required this.unit,
    required this.color, required this.spots,
    required this.minY, required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: color)),
            const SizedBox(width: 8),
            Text(title,
              style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const Spacer(),
            if (spots.isNotEmpty)
              Text('${spots.last.y.toStringAsFixed(1)} $unit',
                style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: color)),
          ]),
          Text(subtitle,
            style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 12),

          SizedBox(
            height: 100,
            child: spots.isEmpty
              ? Center(child: Text('En attente de données…',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12)))
              : LineChart(LineChartData(
                  minY: minY, maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.cardBorder, strokeWidth: 0.8)),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.0,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.08)),
                  )],
                )),
          ),
        ],
      ),
    );
  }
}

// ─── Vitals summary row ──────────────────────────────────────
class _VitalsSummaryRow extends StatelessWidget {
  final VitalSignsModel vitals;
  const _VitalsSummaryRow({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _MiniStat(label: 'FC', value: '${vitals.heartRate}',
        unit: 'bpm', color: AppColors.heartColor,
        alert: vitals.isHeartRateElevated),
      const SizedBox(width: 8),
      _MiniStat(label: 'Accél.',
        value: vitals.accelMagnitude.toStringAsFixed(2),
        unit: 'g', color: AppColors.accelColor, alert: false),
      const SizedBox(width: 8),
      _MiniStat(label: 'GSR',
        value: (vitals.gsrValue * 100).toStringAsFixed(0),
        unit: '%', color: AppColors.gsrColor,
        alert: vitals.isGsrElevated),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value, unit;
  final Color  color;
  final bool   alert;
  const _MiniStat({required this.label, required this.value,
    required this.unit, required this.color, required this.alert});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert ? color.withValues(alpha: 0.12) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: alert ? color : AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11,
          color: alert ? color : AppColors.textSecondary)),
        const SizedBox(height: 2),
        RichText(text: TextSpan(children: [
          TextSpan(text: value, style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.w700, color: color,
            fontFamily: 'Inter')),
          TextSpan(text: ' $unit', style: TextStyle(fontSize: 11,
            color: alert ? color : AppColors.textSecondary,
            fontFamily: 'Inter')),
        ])),
      ]),
    ),
  );
}

// ─── Overlay crise ───────────────────────────────────────────
class _SeizureOverlay extends StatelessWidget {
  final double       score;
  final VoidCallback onDismiss;
  const _SeizureOverlay({required this.score, required this.onDismiss});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.dangerLight,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded,
            size: 80, color: AppColors.seizureRed),
          const SizedBox(height: 16),
          const Text('Crise détectée !',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
              color: AppColors.seizureRedDark)),
          const SizedBox(height: 8),
          Text('Score ML : ${(score * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 16,
              color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('Alertes envoyées aux contacts d\'urgence',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onDismiss,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.seizureRed),
            child: const Text('Acquitter l\'alerte'),
          ),
        ]),
      ),
    ),
  );
}