import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../services/sound_service.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';

// ── Listener racine : écoute le stream et affiche les overlays ─
class ReminderListener extends ConsumerWidget {
  final Widget child;
  const ReminderListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ReminderModel>>(
      reminderFiredProvider,
      (_, next) => next.whenData(
        (reminder) => _showBanner(context, reminder)),
    );
    return child;
  }

  static void _showBanner(BuildContext context, ReminderModel reminder) {
    playReminderSound();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ReminderBanner(
        reminder: reminder,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

// ── Bannière animée ────────────────────────────────────────────
class _ReminderBanner extends StatefulWidget {
  final ReminderModel  reminder;
  final VoidCallback   onDismiss;
  const _ReminderBanner({required this.reminder, required this.onDismiss});

  @override
  State<_ReminderBanner> createState() => _ReminderBannerState();
}

class _ReminderBannerState extends State<_ReminderBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset>   _slide;
  late Animation<double>   _fade;
  late Timer               _autoClose;
  double _progress = 1.0;

  static const _duration = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // Barre de décompte
    Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() =>
        _progress = 1 - (t.tick * 100 / _duration.inMilliseconds));
      if (_progress <= 0) t.cancel();
    });

    _autoClose = Timer(_duration, _dismiss);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _autoClose.cancel();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _autoClose.cancel();
    await _ctrl.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16, right: 16,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E78C7), Color(0xFF74B0E8)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90D9).withValues(alpha: 0.40),
                    blurRadius: 24,
                    offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(children: [
                      // Icône
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14)),
                        child: Stack(alignment: Alignment.center, children: [
                          const Icon(Icons.medication_rounded,
                            color: Colors.white, size: 28),
                          Positioned(
                            top: 6, right: 6,
                            child: Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amberAccent
                                      .withValues(alpha: 0.6),
                                    blurRadius: 6),
                                ]))),
                        ]),
                      ),
                      const SizedBox(width: 14),

                      // Texte
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rappel médicament',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4)),
                            const SizedBox(height: 3),
                            Text(widget.reminder.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.access_time_rounded,
                                size: 12, color: Colors.white60),
                              const SizedBox(width: 4),
                              Text(widget.reminder.timeLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600)),
                            ]),
                          ],
                        ),
                      ),

                      // Bouton fermer
                      GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18)),
                      ),
                    ]),
                  ),

                  // Bouton "Pris !"
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25))),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Médicament pris !',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Barre de décompte
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft:  Radius.circular(20),
                      bottomRight: Radius.circular(20)),
                    child: LinearProgressIndicator(
                      value: _progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.amberAccent)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
