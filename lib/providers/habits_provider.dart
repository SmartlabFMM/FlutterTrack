import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HabitsData {
  final double stress;
  final double sommeil;
  final double hydratation;
  final bool   medicaments;
  final bool   alcool;
  final bool   sport;

  const HabitsData({
    this.stress      = 0,
    this.sommeil     = 0,
    this.hydratation = 0,
    this.medicaments = false,
    this.alcool      = false,
    this.sport       = false,
  });

  HabitsData copyWith({
    double? stress,
    double? sommeil,
    double? hydratation,
    bool?   medicaments,
    bool?   alcool,
    bool?   sport,
  }) => HabitsData(
    stress:      stress      ?? this.stress,
    sommeil:     sommeil     ?? this.sommeil,
    hydratation: hydratation ?? this.hydratation,
    medicaments: medicaments ?? this.medicaments,
    alcool:      alcool      ?? this.alcool,
    sport:       sport       ?? this.sport,
  );
}

class HabitsNotifier extends StateNotifier<HabitsData> {
  HabitsNotifier() : super(const HabitsData());

  void setStress(double v)      => state = state.copyWith(stress: v);
  void setSommeil(double v)     => state = state.copyWith(sommeil: v.clamp(0, 12));
  void setHydratation(double v) => state = state.copyWith(hydratation: v.clamp(0, 10));
  void toggleMedicaments()      => state = state.copyWith(medicaments: !state.medicaments);
  void toggleAlcool()           => state = state.copyWith(alcool: !state.alcool);
  void toggleSport()            => state = state.copyWith(sport: !state.sport);

  Future<bool> save(String patientId) async {
    try {
      await FirebaseFirestore.instance.collection('habitudes_patient').add({
        'patient_id':  patientId,
        'timestamp':   FieldValue.serverTimestamp(),
        'medicaments': state.medicaments ? 1 : 0,
        'alcool':      state.alcool      ? 1 : 0,
        'sport':       state.sport       ? 1 : 0,
        'stress':      state.stress,
        'sommeil':     state.sommeil,
        'hydratation': state.hydratation,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}

final habitsProvider =
    StateNotifierProvider.autoDispose<HabitsNotifier, HabitsData>(
  (ref) => HabitsNotifier(),
);
