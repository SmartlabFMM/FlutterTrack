import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ble_provider.dart';
import '../../models/vital_signs_model.dart';
import '../../services/seizure_confirmation_service.dart';

Color _imuColor(double g) {
  if (g < 2.5) return const Color(0xFF10B981);
  if (g < 5.0) return AppColors.warning;
  return AppColors.seizureRed;
}

String _imuLabel(double g) {
  if (g < 2.5) return 'Faible';
  if (g < 5.0) return 'Modéré';
  return 'Élevé';
}

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/patient/dashboard')),
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
        ? _SeizureOverlay(
            score: ble.seizureScore,
            onDismiss: () => ref.read(bleProvider.notifier).clearSeizureAlert(),
            onConfirm: () async {
              final user = ref.read(authProvider).user!;
              await SeizureConfirmationService().confirm(user.uid);
              ref.read(bleProvider.notifier).clearSeizureAlert();
            },
          )
        : Column(children: [
            if (!isConnected) const _OfflineBanner(),
            Expanded(child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // ── Résumé valeurs actuelles ─────────────────
                if (ble.latestVitals != null)
                  _VitalsSummaryRow(vitals: ble.latestVitals!),
                const SizedBox(height: 16),

                // ── Graphique IMU ────────────────────────────
                _ImuSignalCard(spots: _accelData),
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

// ─── ImuSignalCard ───────────────────────────────────────────
class _ImuSignalCard extends StatelessWidget {
  final List<FlSpot> spots;
  const _ImuSignalCard({required this.spots});

  @override
  Widget build(BuildContext context) {
    final lastMag = spots.isNotEmpty ? spots.last.y : 0.0;
    final color   = _imuColor(lastMag);
    final label   = _imuLabel(lastMag);

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
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 8),
            const Text('Magnitude IMU',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
            const Spacer(),
            if (spots.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: color)),
                  const SizedBox(width: 4),
                  Text('${lastMag.toStringAsFixed(2)} g  $label',
                    style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: color)),
                ]),
              ),
          ]),
          const Text('√(acc_x² + acc_y² + acc_z²)',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 12),

          SizedBox(
            height: 110,
            child: spots.isEmpty
              ? Center(child: Text('En attente de données…',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12)))
              : LineChart(LineChartData(
                  minY: 0, maxY: 10,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2.5,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.cardBorder, strokeWidth: 0.8)),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 2.5,
                        getTitlesWidget: (v, _) => Text(
                          v % 1 == 0 ? '${v.toInt()}g' : '${v}g',
                          style: const TextStyle(
                            fontSize: 9, color: AppColors.textHint)),
                      )),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(y: 2.5,
                        color: AppColors.warning.withValues(alpha: 0.7),
                        strokeWidth: 1.2,
                        dashArray: [4, 3]),
                      HorizontalLine(y: 5.0,
                        color: AppColors.seizureRed.withValues(alpha: 0.7),
                        strokeWidth: 1.2,
                        dashArray: [4, 3]),
                    ]),
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
      ),
    );
  }
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
      _MiniStat(label: 'IMU',
        value: vitals.accelMagnitude.toStringAsFixed(2),
        unit: 'g',
        color: _imuColor(vitals.accelMagnitude),
        alert: vitals.accelMagnitude >= 2.5),
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
            fontWeight: FontWeight.w700, color: color,)),
          TextSpan(text: ' $unit', style: TextStyle(fontSize: 11,
            color: alert ? color : AppColors.textSecondary,)),
        ])),
      ]),
    ),
  );
}

// ─── Overlay crise ───────────────────────────────────────────
class _SeizureOverlay extends StatefulWidget {
  final double       score;
  final VoidCallback onDismiss;
  final Future<void> Function() onConfirm;
  const _SeizureOverlay({
    required this.score,
    required this.onDismiss,
    required this.onConfirm,
  });

  @override
  State<_SeizureOverlay> createState() => _SeizureOverlayState();
}

class _SeizureOverlayState extends State<_SeizureOverlay> {
  bool _confirming = false;

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
          Text('Score de risque : ${(widget.score * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 16,
              color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('Alertes envoyées aux contacts d\'urgence',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),

          // Bouton confirmer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirming ? null : () async {
                setState(() => _confirming = true);
                await widget.onConfirm();
              },
              icon: _confirming
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_rounded),
              label: const Text('Confirmer la crise'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.seizureRed,
                minimumSize: const Size(double.infinity, 50)),
            ),
          ),
          const SizedBox(height: 12),

          // Bouton acquitter (fausse alerte)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _confirming ? null : widget.onDismiss,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.seizureRed),
                minimumSize: const Size(double.infinity, 50)),
              child: const Text('Fausse alerte',
                style: TextStyle(color: AppColors.seizureRed)),
            ),
          ),
        ]),
      ),
    ),
  );
}