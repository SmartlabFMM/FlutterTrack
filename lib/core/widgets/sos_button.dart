import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../services/notification_service.dart';

class SosButton extends ConsumerStatefulWidget {
  const SosButton({super.key});
  @override
  ConsumerState<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends ConsumerState<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onLongPress() async {
    setState(() => _triggered = true);
    // Vibration + alerte
    await NotificationService.sendSmsFamilyAlert(
      phone: '+216XXXXXXXX',
      patientName: 'Patient',
      datetime: DateTime.now().toString(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.sosSent),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
      );
      await Future.delayed(const Duration(seconds: 3));
      setState(() => _triggered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) => Container(
          width: 100 + (_triggered ? 0 : _anim.value * 8),
          height: 100 + (_triggered ? 0 : _anim.value * 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.sosButton.withValues(alpha: 0.12 + _anim.value * 0.08),
          ),
          child: child,
        ),
        child: GestureDetector(
          onLongPress: _onLongPress,
          child: Container(
            width: 96, height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sosButton,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 30),
                SizedBox(height: 4),
                Text('SOS',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}