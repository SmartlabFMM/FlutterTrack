import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

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

// ── Provider : stream des vitaux live du patient ──────────────
final _liveVitalsProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(patientId)
      .snapshots()
      .map((snap) => snap.data()?['vitals_live'] as Map<String, dynamic>?);
});

// ── Écran ────────────────────────────────────────────────────
class FamilySignalsScreen extends ConsumerStatefulWidget {
  const FamilySignalsScreen({super.key});

  @override
  ConsumerState<FamilySignalsScreen> createState() =>
      _FamilySignalsScreenState();
}

class _FamilySignalsScreenState extends ConsumerState<FamilySignalsScreen> {
  final List<FlSpot> _heartData = [];
  final List<FlSpot> _accelData = [];
  final List<FlSpot> _gsrData   = [];
  int _tick = 0;

  Map<String, dynamic>? _latest;

  @override
  Widget build(BuildContext context) {
    final patId = ref.watch(authProvider).user?.linkedPatientId ?? '';

    ref.listen(_liveVitalsProvider(patId), (_, next) {
      next.whenData((data) {
        if (data == null) return;
        setState(() {
          _tick++;
          _latest = data;
          final hr    = ((data['heartRate']      ?? 0) as num).toDouble();
          final accel = ((data['accelMagnitude'] ?? 0) as num).toDouble();
          final gsr   = ((data['gsrValue']       ?? 0) as num).toDouble() * 100;

          _heartData.add(FlSpot(_tick.toDouble(), hr));
          _accelData.add(FlSpot(_tick.toDouble(), accel));
          _gsrData  .add(FlSpot(_tick.toDouble(), gsr));

          if (_heartData.length > 60) {
            _heartData.removeAt(0);
            _accelData.removeAt(0);
            _gsrData  .removeAt(0);
          }
        });
      });
    });

    final vitalsAsync = ref.watch(_liveVitalsProvider(patId));
    final hasData = _latest != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Signaux du patient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/family/dashboard'),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hasData ? AppColors.tealPale : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasData ? AppColors.teal : AppColors.textHint,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                hasData ? 'En direct' : 'Aucune donnée',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: hasData ? AppColors.tealDark : AppColors.textHint,
                ),
              ),
            ]),
          ),
        ],
      ),
      body: vitalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (_, __) => const Center(child: Text('Erreur de connexion')),
        data: (_) => Column(children: [
          if (!hasData) const _OfflineBanner(),
          Expanded(child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Résumé valeurs actuelles ─────────────────────
              if (hasData) ...[
                _VitalsSummaryRow(data: _latest!),
                const SizedBox(height: 16),
              ],

              // ── Fréquence cardiaque ──────────────────────────
              _SignalCard(
                title:    'Fréquence cardiaque',
                subtitle: 'Battements / minute',
                unit:     'bpm',
                color:    AppColors.heartColor,
                spots:    _heartData,
                minY: 40, maxY: 180,
              ),
              const SizedBox(height: 12),

              // ── Magnitude IMU ────────────────────────────────
              _ImuSignalCard(spots: _accelData),
              const SizedBox(height: 12),

              // ── GSR ──────────────────────────────────────────
              _SignalCard(
                title:    'Conductance cutanée',
                subtitle: 'Conductance normalisée (%)',
                unit:     '%',
                color:    AppColors.gsrColor,
                spots:    _gsrData,
                minY: 0, maxY: 100,
              ),

              const SizedBox(height: 24),
              _RgpdNote(),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Résumé valeurs ────────────────────────────────────────────
class _VitalsSummaryRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _VitalsSummaryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final hr    = ((data['heartRate']      ?? 0) as num).toInt();
    final accel = ((data['accelMagnitude'] ?? 0) as num).toDouble();
    final gsr   = ((data['gsrValue']       ?? 0) as num).toDouble() * 100;

    final hrAlert  = hr > 120 || hr < 45;
    final gsrAlert = gsr > 70;

    return Row(children: [
      _MiniStat(label: 'FC',    value: '$hr',
        unit: 'bpm', color: AppColors.heartColor, alert: hrAlert),
      const SizedBox(width: 8),
      _MiniStat(label: 'IMU', value: accel.toStringAsFixed(2),
        unit: 'g', color: _imuColor(accel), alert: accel >= 2.5),
      const SizedBox(width: 8),
      _MiniStat(label: 'GSR',   value: gsr.toStringAsFixed(0),
        unit: '%', color: AppColors.gsrColor, alert: gsrAlert),
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
        border: Border.all(color: alert ? color : AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
          fontSize: 11, color: alert ? color : AppColors.textSecondary)),
        const SizedBox(height: 2),
        RichText(text: TextSpan(children: [
          TextSpan(text: value, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: color, fontFamily: 'Inter')),
          TextSpan(text: ' $unit', style: TextStyle(
            fontSize: 11,
            color: alert ? color : AppColors.textSecondary,
            fontFamily: 'Inter')),
        ])),
      ]),
    ),
  );
}

// ── Carte graphique ───────────────────────────────────────────
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary)),
          const Spacer(),
          if (spots.isNotEmpty)
            Text('${spots.last.y.toStringAsFixed(1)} $unit',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ]),
        Text(subtitle, style: const TextStyle(
          fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 12),

        SizedBox(
          height: 100,
          child: spots.isEmpty
            ? Center(child: Text('En attente des données du bracelet…',
                style: TextStyle(
                  color: AppColors.textHint, fontSize: 12)))
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

// ── ImuSignalCard ─────────────────────────────────────────────
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
              ? Center(child: Text('En attente des données du bracelet…',
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

// ── Bannière hors ligne ───────────────────────────────────────
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

// ── Note RGPD ─────────────────────────────────────────────────
class _RgpdNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: const Row(children: [
      Icon(Icons.lock_rounded, size: 14, color: AppColors.primary),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          'Ces données sont chiffrées et accessibles uniquement à la famille autorisée.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
        ),
      ),
    ]),
  );
}
