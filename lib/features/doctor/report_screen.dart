import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../models/seizure_model.dart';
import '../../providers/seizure_provider.dart';


class ReportScreen extends ConsumerWidget {
  final String patientId;
  const ReportScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seizures   = ref.watch(seizureListProvider(patientId));
    final patientRaw = ref.watch(patientDataProvider(patientId)).valueOrNull ?? {};
    final name       = patientRaw['nom'] as String? ?? 'Patient #$patientId';
    final detail     = patientRaw.isNotEmpty ? patientRaw : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Rapport médical'),
          actions: [
            seizures.when(
              data: (list) => TextButton.icon(
                onPressed: () => _generatePdf(context, list, name, detail),
                icon: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.primary),
                label: const Text('Exporter PDF',
                  style: TextStyle(color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
              ),
              loading: () => const SizedBox(),
              error:   (_, __) => const SizedBox(),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── En-tête dossier ───────────────────────────────
            _ReportHeader(
              patientName: name,
              patientId: patientId,
              detail: detail,
            ),
            const SizedBox(height: 14),

            // ── Résumé crises ────────────────────────────────
            seizures.when(
              data:    (list) => _SeizureSummaryCard(seizures: list),
              loading: () => const _Skeleton(),
              error:   (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 14),

            // ── Mode de vie ──────────────────────────────────
            _LifestyleSection(lifestyle:
              detail != null
                ? (detail['lifestyle'] as Map?)?.cast<String, dynamic>()
                : null),
            const SizedBox(height: 14),

            // ── Déclencheurs ──────────────────────────────────
            _TriggersSection(
              triggers: detail != null
                ? List<String>.from(detail['triggers'] as List? ?? [])
                : []),
            const SizedBox(height: 14),

            // ── Compliance ────────────────────────────────────
            _ComplianceSection(
              compliance: (detail?['compliance'] as num?)?.toDouble()),
            const SizedBox(height: 14),

            // ── Tableau des crises ───────────────────────────
            _SectionTitle(icon: Icons.history_rounded,
              label: 'Historique des crises', color: AppColors.seizureRed),
            const SizedBox(height: 10),
            seizures.when(
              data: (list) => list.isEmpty
                ? const _EmptyRow('Aucune crise enregistrée')
                : Column(children: list.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _SeizureRow(seizure: s),
                  )).toList()),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary)),
              error: (_, __) => const Text('Erreur de chargement'),
            ),
            const SizedBox(height: 14),

            // ── Notes cliniques ───────────────────────────────
            if (detail != null && (detail['notes'] as List?)?.isNotEmpty == true) ...[
              _SectionTitle(icon: Icons.notes_rounded,
                label: 'Notes cliniques', color: AppColors.primaryDark),
              const SizedBox(height: 10),
              _NotesSection(
                notes: List<Map<String,dynamic>>.from(
                  detail['notes'] as List)),
              const SizedBox(height: 14),
            ],

            // ── Pied de page ─────────────────────────────────
            Center(
              child: Text(
                'Rapport généré par EpiTrack · '
                '${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Génération PDF avec mode de vie ─────────────────────────
  Future<void> _generatePdf(
      BuildContext context,
      List<SeizureModel> seizures,
      String name,
      Map<String, dynamic>? detail) async {
    final doc    = pw.Document();
    final today  = DateFormat('dd MMMM yyyy', 'fr').format(DateTime.now());
    final avgScore = seizures.isEmpty ? 0.0
      : seizures.map((s) => s.mlScore).reduce((a, b) => a + b)
          / seizures.length;
    final compliance = (detail?['compliance'] as num?)?.toDouble();
    final lifestyle = detail != null
      ? (detail['lifestyle'] as Map?)?.cast<String, dynamic>() ?? {}
      : <String, dynamic>{};
    final triggers = detail != null
      ? List<String>.from(detail['triggers'] as List? ?? [])
      : <String>[];
    final notes = detail != null
      ? List<Map<String,dynamic>>.from(detail['notes'] as List? ?? [])
      : <Map<String,dynamic>>[];

    try {

    // Load Unicode fonts (supports French accents + em dash)
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold    = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.blueGrey200))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('EpiTrack — Rapport médical',
              style: pw.TextStyle(
                fontSize: 10, color: PdfColors.blueGrey600,
                fontWeight: pw.FontWeight.bold)),
            pw.Text(today,
              style: const pw.TextStyle(
                fontSize: 10, color: PdfColors.blueGrey600)),
          ],
        ),
      ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('Page ${ctx.pageNumber}/${ctx.pagesCount}',
          style: const pw.TextStyle(
            fontSize: 9, color: PdfColors.blueGrey400)),
      ),
      build: (ctx) => [

        // ── En-tête patient ──────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('DBEAFE'),
            borderRadius: pw.BorderRadius.circular(10)),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('RAPPORT DE SUIVI ÉPILEPSIE',
                  style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('1E3A8A'))),
                pw.SizedBox(height: 10),
                _pdfInfoLine('Patient',    name),
                _pdfInfoLine('N° dossier', '#EP-$patientId'),
                _pdfInfoLine('Médecin',    'Dr. Kamel Trabelsi'),
                _pdfInfoLine('Diagnostic', detail?['diagnosis'] as String? ?? '—'),
                _pdfInfoLine('Traitement', detail?['treatment'] as String? ?? '—'),
                _pdfInfoLine('Date',       today),
              ]),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // ── Résumé crises ────────────────────────────────
        _pdfSection('Résumé des crises'),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          _pdfStatBox('${seizures.length}', 'Crises totales',
            PdfColor.fromHex('FECACA'), PdfColor.fromHex('991B1B')),
          pw.SizedBox(width: 8),
          _pdfStatBox('${(avgScore * 100).toStringAsFixed(0)}%',
            'Score de risque moyen', PdfColor.fromHex('FDE68A'), PdfColor.fromHex('92400E')),
          pw.SizedBox(width: 8),
          _pdfStatBox(
            compliance != null ? '${(compliance * 100).round()}%' : '—',
            'Compliance',
            PdfColor.fromHex('99F6E4'), PdfColor.fromHex('065F46')),
        ]),
        pw.SizedBox(height: 20),

        // ── Mode de vie ──────────────────────────────────
        _pdfSection('Mode de vie & facteurs comportementaux'),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('F8FAFF'),
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColor.fromHex('E2E8F0'))),
          child: pw.Column(children: [
            lifestyle.isEmpty
              ? pw.Text('Aucune donnée — le patient n\'a pas encore renseigné son mode de vie.',
                  style: const pw.TextStyle(fontSize: 10))
              : pw.Column(children: lifestyle.entries.toList().asMap().entries.map((e) {
                  final odd = e.key.isOdd;
                  final label = e.value.key;
                  final value = e.value.value?.toString() ?? '—';
                  return _pdfLifestyleRow(label, value, odd);
                }).toList()),
          ]),
        ),
        pw.SizedBox(height: 16),

        // ── Déclencheurs ─────────────────────────────────
        _pdfSection('Déclencheurs identifiés'),
        pw.SizedBox(height: 6),
        pw.Wrap(
          spacing: 8, runSpacing: 6,
          children: triggers.isEmpty
            ? [pw.Text('Aucun déclencheur renseigné',
                style: const pw.TextStyle(fontSize: 10))]
            : triggers.map((t) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('FEF9C3'),
                borderRadius: pw.BorderRadius.circular(20),
                border: pw.Border.all(color: PdfColor.fromHex('FDE68A'))),
              child: pw.Text(t,
                style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('78350F'))),
            )).toList(),
        ),
        pw.SizedBox(height: 20),

        // ── Tableau des crises ───────────────────────────
        _pdfSection('Historique des crises'),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Date & Heure', 'Durée', 'Score de risque', 'Sévérité'],
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('1E3A8A'),
            fontSize: 11),
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromHex('DBEAFE')),
          oddRowDecoration: pw.BoxDecoration(
            color: PdfColor.fromHex('F8FAFF')),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 8, vertical: 6),
          cellStyle: const pw.TextStyle(fontSize: 10),
          data: seizures.isEmpty
            ? [['Aucune crise enregistrée', '', '', '']]
            : seizures.map((s) => [
                DateFormat('dd/MM/yyyy HH:mm').format(s.datetime),
                s.durationFormatted,
                '${(s.mlScore * 100).toStringAsFixed(0)}%',
                s.severityLabel,
              ]).toList(),
        ),
        pw.SizedBox(height: 20),

        // ── Notes cliniques ──────────────────────────────
        if (notes.isNotEmpty) ...[
          _pdfSection('Notes cliniques'),
          pw.SizedBox(height: 8),
          pw.Column(children: notes.map((n) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('EFF6FF'),
              border: pw.Border(
                left: pw.BorderSide(
                  color: PdfColor.fromHex('1E40AF'), width: 3))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(n['date'] as String? ?? '',
                  style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('1E40AF'))),
                pw.SizedBox(height: 3),
                pw.Text(n['text'] as String? ?? '',
                  style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          )).toList()),
          pw.SizedBox(height: 20),
        ],

        // ── Recommandations mode de vie ──────────────────
        _pdfSection('Recommandations — Mode de vie'),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('F0FDFA'),
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColor.fromHex('0D9488'))),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pdfRecoLine('Sommeil',
                'Viser 7-9h/nuit à horaires fixes. Éviter les écrans après 21h.'),
              _pdfRecoLine('Médicament',
                'Maintenir la prise à heure fixe. Ne jamais interrompre sans avis médical.'),
              _pdfRecoLine('Stress',
                'Techniques de relaxation (respiration, yoga). Suivi psychologique recommandé.'),
              _pdfRecoLine('Hydratation',
                'Augmenter l\'apport hydrique à 1.5-2L/jour, surtout en période chaude.'),
              _pdfRecoLine('Exercice',
                'Maintenir l\'activité modérée. Prévenir un accompagnant lors des séances.'),
            ],
          ),
        ),
        pw.SizedBox(height: 24),

        // ── Signature ────────────────────────────────────
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Signature du médecin',
                style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 30),
              pw.Container(width: 150, height: 1,
                color: PdfColors.blueGrey400),
              pw.Text('Dr. Kamel Trabelsi',
                style: const pw.TextStyle(fontSize: 10)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('Généré par EpiTrack',
                style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.blueGrey500)),
              pw.Text(today,
                style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.blueGrey500)),
            ]),
          ],
        ),
      ],
    ));

    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'rapport_EP-$patientId.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur PDF : $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  // ── Helpers PDF ──────────────────────────────────────────────
  pw.Widget _pdfSection(String title) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.blueGrey200))),
    child: pw.Text(title,
      style: pw.TextStyle(
        fontSize: 13, fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('1E40AF'))),
  );

  pw.Widget _pdfInfoLine(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Row(children: [
      pw.SizedBox(
        width: 80,
        child: pw.Text('$label :',
          style: pw.TextStyle(
            fontSize: 10, color: PdfColor.fromHex('4B6CB7')))),
      pw.Text(value,
        style: pw.TextStyle(
          fontSize: 10, fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('1E3A8A'))),
    ]),
  );

  pw.Widget _pdfStatBox(String val, String lbl, PdfColor bg, PdfColor fg) =>
    pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(val, style: pw.TextStyle(
              fontSize: 16, fontWeight: pw.FontWeight.bold,
              color: fg)),
            pw.SizedBox(height: 2),
            pw.Text(lbl, style: pw.TextStyle(
              fontSize: 9, color: fg),
              textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );

  pw.Widget _pdfLifestyleRow(String label, String value, bool odd) =>
    pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      color: odd ? PdfColors.white : PdfColor.fromHex('F0F7FF'),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(
            fontSize: 10, color: PdfColor.fromHex('374151'))),
          pw.Text(value, style: pw.TextStyle(
            fontSize: 10, fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('3B6FBF'))),
        ],
      ),
    );

  pw.Widget _pdfRecoLine(String label, String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 6, height: 6,
          margin: const pw.EdgeInsets.only(top: 3, right: 6),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('0D9488'),
            shape: pw.BoxShape.circle)),
        pw.Expanded(child: pw.RichText(text: pw.TextSpan(children: [
          pw.TextSpan(text: '$label : ',
            style: pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('0F766E'))),
          pw.TextSpan(text: text,
            style: const pw.TextStyle(fontSize: 10)),
        ]))),
      ],
    ),
  );

}

// ── Widgets Flutter (aperçu) ──────────────────────────────────

class _ReportHeader extends StatelessWidget {
  final String patientName, patientId;
  final Map<String, dynamic>? detail;
  const _ReportHeader({required this.patientName,
    required this.patientId, this.detail});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [AppColors.primaryDark, AppColors.primary]),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.25),
          blurRadius: 16, offset: const Offset(0, 6)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.description_rounded,
            color: Colors.white, size: 18)),
        const SizedBox(width: 12),
        const Text('Rapport de suivi épilepsie',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
            color: Colors.white)),
      ]),
      const SizedBox(height: 14),
      Container(height: 1,
        color: Colors.white.withValues(alpha: 0.2)),
      const SizedBox(height: 12),
      _HRow('Patient',    patientName),
      _HRow('N° dossier', '#EP-$patientId'),
      _HRow('Médecin',    'Dr. Kamel Trabelsi'),
      if (detail != null) ...[
        _HRow('Diagnostic', detail!['diagnosis'] as String? ?? '—'),
        _HRow('Traitement', detail!['treatment'] as String? ?? '—'),
      ],
      _HRow('Date', DateFormat('dd MMMM yyyy', 'fr').format(DateTime.now())),
    ]),
  );
}

class _HRow extends StatelessWidget {
  final String label, value;
  const _HRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 90,
        child: Text(label, style: TextStyle(
          fontSize: 11, color: Colors.white.withValues(alpha: 0.7)))),
      Expanded(child: Text(value, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
    ]),
  );
}

class _SeizureSummaryCard extends StatelessWidget {
  final List<SeizureModel> seizures;
  const _SeizureSummaryCard({required this.seizures});

  @override
  Widget build(BuildContext context) {
    final avgScore = seizures.isEmpty ? 0.0
      : seizures.map((s) => s.mlScore).reduce((a, b) => a + b)
          / seizures.length;

    return _Card(
      icon: Icons.analytics_rounded, iconColor: AppColors.seizureRed,
      title: 'Résumé des crises',
      child: Row(children: [
        _StatBox('${seizures.length}', 'Crises', AppColors.seizureRed),
        _vDivider(),
        _StatBox('${(avgScore*100).toStringAsFixed(0)}%',
          'Score de risque', AppColors.warning),
      ]),
    );
  }

}

class _LifestyleSection extends StatelessWidget {
  final Map<String, dynamic>? lifestyle;
  const _LifestyleSection({this.lifestyle});

  @override
  Widget build(BuildContext context) => _Card(
    icon: Icons.favorite_rounded, iconColor: const Color(0xFFEC4899),
    title: 'Mode de vie',
    child: lifestyle == null || lifestyle!.isEmpty
      ? const _EmptyRow('Le patient n\'a pas encore renseigné son mode de vie')
      : Wrap(
          spacing: 8, runSpacing: 8,
          children: lifestyle!.entries.map((e) {
            final val  = e.value as Map?;
            final label = val?['label'] as String? ?? e.key;
            final value = val?['value'] as String? ?? '—';
            final good  = val?['status'] == 'good';
            final color = good ? AppColors.teal : AppColors.warning;
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              ]),
            );
          }).toList(),
        ),
  );
}

class _TriggersSection extends StatelessWidget {
  final List<String> triggers;
  const _TriggersSection({required this.triggers});

  @override
  Widget build(BuildContext context) => _Card(
    icon: Icons.bolt_rounded, iconColor: AppColors.warning,
    title: 'Déclencheurs identifiés',
    child: triggers.isEmpty
      ? const _EmptyRow('Aucun déclencheur renseigné')
      : Wrap(
          spacing: 8, runSpacing: 8,
          children: triggers.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.bolt_rounded, size: 12, color: AppColors.warning),
              const SizedBox(width: 5),
              Text(t, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF92400E))),
            ]),
          )).toList(),
        ),
  );
}

class _ComplianceSection extends StatelessWidget {
  final double? compliance;
  const _ComplianceSection({required this.compliance});

  @override
  Widget build(BuildContext context) {
    if (compliance == null) {
      return _Card(
        icon: Icons.task_alt_rounded, iconColor: AppColors.textHint,
        title: 'Compliance au traitement',
        child: const _EmptyRow('Aucune donnée de compliance disponible'),
      );
    }
    final pct   = (compliance! * 100).round();
    final color = pct >= 90 ? AppColors.teal
                : pct >= 70 ? AppColors.warning
                : AppColors.seizureRed;

    return _Card(
      icon: Icons.task_alt_rounded, iconColor: color,
      title: 'Compliance au traitement',
      child: Column(children: [
        Row(children: [
          Text('$pct%', style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pct >= 90 ? 'Excellente' : pct >= 70 ? 'Correcte' : 'Insuffisante',
                style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w700, color: color)),
              const Text('Prises de médicament — 30 derniers jours',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          )),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: compliance!, minHeight: 10,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color)),
        ),
      ]),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final List<Map<String, dynamic>> notes;
  const _NotesSection({required this.notes});

  @override
  Widget build(BuildContext context) => _Card(
    icon: Icons.notes_rounded, iconColor: AppColors.primaryDark,
    title: 'Notes cliniques',
    child: Column(children: notes.asMap().entries.map((e) {
      final n = e.value;
      final isLast = e.key == notes.length - 1;
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 8, height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle, color: AppColors.primary)),
          if (!isLast) Container(
            width: 1, height: 32,
            color: AppColors.cardBorder,
            margin: const EdgeInsets.symmetric(vertical: 3)),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n['date'] as String? ?? '',
              style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.primary)),
            const SizedBox(height: 3),
            Text(n['text'] as String? ?? '',
              style: const TextStyle(
                fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
          ]),
        )),
      ]);
    }).toList()),
  );
}

class _SeizureRow extends StatelessWidget {
  final SeizureModel seizure;
  const _SeizureRow({required this.seizure});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.cardBorder)),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.bolt_rounded,
          size: 16, color: AppColors.seizureRed)),
      const SizedBox(width: 10),
      Expanded(child: Text(
        DateFormat('dd/MM/yyyy · HH:mm').format(seizure.datetime),
        style: const TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      Text(seizure.durationFormatted,
        style: const TextStyle(
          fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (seizure.mlScore >= 0.90
            ? AppColors.seizureRed : AppColors.warning)
            .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
        child: Text('${(seizure.mlScore*100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: seizure.mlScore >= 0.90
              ? AppColors.seizureRed : AppColors.warning))),
    ]),
  );
}

// ── Composants réutilisables ──────────────────────────────────
class _Card extends StatelessWidget {
  final IconData icon; final Color iconColor;
  final String title; final Widget child;
  const _Card({required this.icon, required this.iconColor,
    required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12, offset: const Offset(0, 4)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: iconColor)),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary)),
      ]),
      const SizedBox(height: 12),
      const Divider(height: 1, color: AppColors.cardBorder),
      const SizedBox(height: 12),
      child,
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _SectionTitle({required this.icon,
    required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 14, color: color)),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(
      fontSize: 14, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary)),
  ]);
}

class _StatBox extends StatelessWidget {
  final String value, label; final Color color;
  const _StatBox(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(
        fontSize: 10, color: AppColors.textSecondary),
        textAlign: TextAlign.center),
    ]),
  );
}

Widget _vDivider() => Container(
  width: 1, height: 40, color: AppColors.cardBorder);

class _EmptyRow extends StatelessWidget {
  final String text;
  const _EmptyRow(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.cardBorder)),
    child: Text(text, style: const TextStyle(
      fontSize: 13, color: AppColors.textSecondary)));
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 80, decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(14)));
}
