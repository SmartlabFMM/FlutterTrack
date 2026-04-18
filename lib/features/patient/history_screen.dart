import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/seizure_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seizure_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(authProvider).user!;
    final seizures = ref.watch(seizureListProvider(user.uid.toString()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des crises'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/patient/dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
              color: AppColors.primary),
            tooltip: 'Exporter PDF',
            onPressed: () => _exportPdf(context),
          ),
        ],
      ),
      body: seizures.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Erreur : $e',
            style: const TextStyle(color: AppColors.danger))),
        data: (list) => list.isEmpty
          ? const _EmptyHistory()
          : Column(children: [
              _MonthSummary(seizures: list),
              Expanded(
                child: _GroupedSeizureList(seizures: list),
              ),
            ]),
      ),
    );
  }

  void _exportPdf(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération du PDF en cours…'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating));
  }
}

// ─── Résumé mensuel avec mini graphique en barres ────────────
class _MonthSummary extends StatelessWidget {
  final List<SeizureModel> seizures;
  const _MonthSummary({required this.seizures});

  @override
  Widget build(BuildContext context) {
    final now    = DateTime.now();
    final month  = seizures.where((s) =>
      s.datetime.month == now.month && s.datetime.year == now.year).length;
    final avgDur = seizures.isEmpty ? 0
      : seizures.map((s) => s.durationSeconds)
          .reduce((a, b) => a + b) ~/ seizures.length;

    // Compter les crises par semaine (4 semaines du mois courant)
    final weekCounts = List<int>.filled(4, 0);
    for (final s in seizures) {
      if (s.datetime.month == now.month && s.datetime.year == now.year) {
        final dayOfMonth = s.datetime.day;
        final weekIdx = ((dayOfMonth - 1) ~/ 7).clamp(0, 3);
        weekCounts[weekIdx]++;
      }
    }
    final maxCount = weekCounts.reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder)),
      child: Column(children: [
        Row(children: [
          _StatPill(label: 'Ce mois', value: '$month',
            color: AppColors.primary),
          const SizedBox(width: 10),
          _StatPill(label: 'Durée moy.', value: _fmt(avgDur),
            color: AppColors.teal),
          const SizedBox(width: 10),
          _StatPill(label: 'Total', value: '${seizures.length}',
            color: AppColors.primaryDark),
        ]),
        if (month > 0) ...[
          const SizedBox(height: 14),
          // Mini bar chart par semaine
          SizedBox(
            height: 60,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxCount + 1).toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['S1', 'S2', 'S3', 'S4'];
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();
                        return Text(labels[i],
                          style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(4, (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: weekCounts[i].toDouble(),
                      color: weekCounts[i] > 0
                        ? AppColors.primary
                        : AppColors.cardBorder,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                )),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Crises par semaine ce mois',
            style: TextStyle(fontSize: 10, color: AppColors.textHint)),
        ],
      ]),
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60; final r = s % 60;
    return m > 0 ? '${m}m ${r}s' : '${r}s';
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _StatPill({required this.label, required this.value,
    required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 22,
        fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(
        fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}

// ─── Liste groupée par mois ───────────────────────────────────
class _GroupedSeizureList extends StatelessWidget {
  final List<SeizureModel> seizures;
  const _GroupedSeizureList({required this.seizures});

  // Group seizures by year-month key
  Map<String, List<int>> _group() {
    final Map<String, List<int>> groups = {};
    for (var i = 0; i < seizures.length; i++) {
      final s = seizures[i];
      final key = '${s.datetime.year}-${s.datetime.month.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(i);
    }
    return groups;
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('MMMM yyyy', 'fr').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _group();
    final keys   = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    final items = <_ListItem>[];
    for (final key in keys) {
      items.add(_ListItem.header(key));
      final indices = groups[key]!;
      for (var j = 0; j < indices.length; j++) {
        final idx  = indices[j];
        final prev = j + 1 < indices.length ? seizures[indices[j + 1]] : null;
        items.add(_ListItem.card(seizures[idx], prev));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item.isHeader) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(_monthLabel(item.key!),
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.4)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SeizureCard(
            seizure: item.seizure!,
            previous: item.previous),
        );
      },
    );
  }
}

class _ListItem {
  final bool isHeader;
  final String? key;
  final SeizureModel? seizure;
  final SeizureModel? previous;

  const _ListItem._({required this.isHeader, this.key,
    this.seizure, this.previous});

  factory _ListItem.header(String key) =>
    _ListItem._(isHeader: true, key: key);

  factory _ListItem.card(SeizureModel seizure, SeizureModel? previous) =>
    _ListItem._(isHeader: false, seizure: seizure, previous: previous);
}

// ─── Carte crise avec indicateur de tendance ─────────────────
class _SeizureCard extends StatelessWidget {
  final SeizureModel  seizure;
  final SeizureModel? previous;
  const _SeizureCard({required this.seizure, this.previous});

  @override
  Widget build(BuildContext context) {
    final scoreColor = seizure.mlScore >= 0.92 ? AppColors.seizureRed
                     : seizure.mlScore >= 0.85 ? AppColors.warning
                     : AppColors.teal;

    // Tendance : comparaison durée avec la crise précédente
    Widget? trendWidget;
    if (previous != null) {
      final diff = seizure.durationSeconds - previous!.durationSeconds;
      if (diff > 0) {
        trendWidget = Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.trending_up_rounded,
            size: 14, color: AppColors.seizureRed),
          const SizedBox(width: 2),
          Text('+${diff}s',
            style: const TextStyle(fontSize: 10,
              color: AppColors.seizureRed, fontWeight: FontWeight.w600)),
        ]);
      } else if (diff < 0) {
        trendWidget = Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.trending_down_rounded,
            size: 14, color: AppColors.teal),
          const SizedBox(width: 2),
          Text('${diff}s',
            style: const TextStyle(fontSize: 10,
              color: AppColors.teal, fontWeight: FontWeight.w600)),
        ]);
      } else {
        trendWidget = Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.trending_flat_rounded,
            size: 14, color: AppColors.textHint),
          const SizedBox(width: 2),
          const Text('=',
            style: TextStyle(fontSize: 10,
              color: AppColors.textHint, fontWeight: FontWeight.w600)),
        ]);
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: [
        // Date
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(DateFormat('dd MMM', 'fr').format(seizure.datetime),
            style: const TextStyle(fontSize: 15,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(DateFormat('HH:mm').format(seizure.datetime),
            style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
        ]),
        const SizedBox(width: 16),

        // Durée + indicateur de tendance
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Durée', style: TextStyle(
            fontSize: 11, color: AppColors.textSecondary)),
          Text(seizure.durationFormatted,
            style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          if (trendWidget != null) ...[
            const SizedBox(height: 2),
            trendWidget,
          ],
        ]),
        const Spacer(),

        // Score ML
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Text('${(seizure.mlScore * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: scoreColor)),
            Text(seizure.severityLabel,
              style: TextStyle(fontSize: 10, color: scoreColor)),
          ]),
        ),
      ]),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_circle_outline_rounded,
        size: 64, color: AppColors.teal.withValues(alpha: 0.5)),
      const SizedBox(height: 16),
      const Text('Aucune crise enregistrée',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      const Text('Votre historique apparaîtra ici.',
        style: TextStyle(fontSize: 13, color: AppColors.textHint)),
    ]),
  );
}
