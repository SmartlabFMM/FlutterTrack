import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

enum LocationTrigger { sos, seizure, riskScore }

// ── Modèle localisation ───────────────────────────────────────
class LocationData {
  final double   lat;
  final double   lng;
  final DateTime updatedAt;
  final bool     isActive;

  const LocationData({
    required this.lat,
    required this.lng,
    required this.updatedAt,
    required this.isActive,
  });

  factory LocationData.fromMap(Map<String, dynamic> m) => LocationData(
    lat:       (m['lat']  as num).toDouble(),
    lng:       (m['lng']  as num).toDouble(),
    updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    isActive:  m['isActive'] == true,
  );
}

// ── État du partage ───────────────────────────────────────────
class LocationSharingState {
  final bool            isSharing;
  final LocationTrigger? trigger;

  const LocationSharingState({this.isSharing = false, this.trigger});
}

// ── Notifier patient ──────────────────────────────────────────
class LocationSharingNotifier extends StateNotifier<LocationSharingState> {
  Timer? _periodicTimer;
  Timer? _stopTimer;

  LocationSharingNotifier() : super(const LocationSharingState());

  Future<void> startSharing(String uid, LocationTrigger trigger) async {
    if (state.isSharing) return;

    // Vérifier / demander la permission GPS
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return;

    state = LocationSharingState(isSharing: true, trigger: trigger);

    await _sendPosition(uid);

    _periodicTimer = Timer.periodic(
      const Duration(seconds: 10), (_) => _sendPosition(uid));

    // RGPD : arrêt automatique après 30 minutes
    _stopTimer = Timer(const Duration(minutes: 30), () => stopSharing(uid));
  }

  Future<void> stopSharing(String uid) async {
    _periodicTimer?.cancel();
    _stopTimer?.cancel();
    _periodicTimer = null;
    _stopTimer     = null;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'location': {
        'isActive':  false,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });

    state = const LocationSharingState();
  }

  Future<void> _sendPosition(String uid) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'location': {
          'lat':       pos.latitude,
          'lng':       pos.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive':  true,
        },
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _stopTimer?.cancel();
    super.dispose();
  }
}

final locationSharingProvider =
    StateNotifierProvider<LocationSharingNotifier, LocationSharingState>(
  (ref) => LocationSharingNotifier(),
);

// ── Provider famille : écoute temps réel ─────────────────────
final familyLocationProvider =
    StreamProvider.autoDispose.family<LocationData?, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(patientId)
      .snapshots()
      .map((snap) {
        final data = snap.data();
        if (data == null || data['location'] == null) return null;
        try {
          return LocationData.fromMap(
              data['location'] as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      });
});

// ── Provider déclencheurs automatiques ───────────────────────
class TriggerData {
  final bool   seizureDetected;
  final double riskScore;
  const TriggerData({required this.seizureDetected, required this.riskScore});
}

final patientLocationTriggerProvider =
    StreamProvider.autoDispose.family<TriggerData, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) {
        final d = snap.data() ?? {};
        return TriggerData(
          seizureDetected: d['seizureDetected'] == true,
          riskScore: ((d['riskScore'] ?? 0.0) as num).toDouble(),
        );
      });
});
