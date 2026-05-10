import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/location_provider.dart';

class DoctorLocationScreen extends ConsumerWidget {
  final String patientId;
  const DoctorLocationScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locAsync = ref.watch(familyLocationProvider(patientId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Localisation du patient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: locAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (_, __) => const Center(child: Text('Erreur de chargement')),
        data:    (loc) => _LocationBody(location: loc),
      ),
    );
  }
}

class _LocationBody extends StatelessWidget {
  final LocationData? location;
  const _LocationBody({required this.location});

  @override
  Widget build(BuildContext context) {
    if (location == null || !location!.isActive) {
      return const _InactiveView();
    }
    return _ActiveMapView(location: location!);
  }
}

class _InactiveView extends StatelessWidget {
  const _InactiveView();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: const BoxDecoration(
            color: AppColors.surfaceAlt,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_off_rounded,
            size: 48, color: AppColors.textHint),
        ),
        const SizedBox(height: 24),
        const Text(
          'Partage de localisation inactif',
          style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'La localisation ne s\'active qu\'en cas de crise détectée.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _ActiveMapView extends StatelessWidget {
  final LocationData location;
  const _ActiveMapView({required this.location});

  String _timeAgo() {
    final diff = DateTime.now().difference(location.updatedAt);
    if (diff.inSeconds < 60)  return 'il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60)  return 'il y a ${diff.inMinutes} min';
    return 'il y a ${diff.inHours}h';
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(location.lat, location.lng);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom:   15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.epitrack',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point:  point,
                  width:  60,
                  height: 60,
                  child:  const _PatientMarker(),
                ),
              ],
            ),
          ],
        ),

        // Bandeau statut
        Positioned(
          top: 12, left: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.3),
                  blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Row(children: [
              Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Localisation active',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
            ]),
          ),
        ),

        // Carte info en bas
        Positioned(
          bottom: 24, left: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text('Dernière position : ${_timeAgo()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
                ]),
                const SizedBox(height: 6),
                Text(
                  'Lat: ${location.lat.toStringAsFixed(6)}  '
                  'Lng: ${location.lng.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mise à jour toutes les 10 secondes • Arrêt auto dans 30 min',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PatientMarker extends StatelessWidget {
  const _PatientMarker();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.danger,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [
        BoxShadow(
          color: AppColors.danger.withValues(alpha: 0.4),
          blurRadius: 8, spreadRadius: 2),
      ],
    ),
    child: const Icon(Icons.person_pin_rounded,
      color: Colors.white, size: 28),
  );
}
