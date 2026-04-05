import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/seizure_model.dart';
import 'auth_provider.dart';

final seizureListProvider =
    FutureProvider.family<List<SeizureModel>, String>((ref, patientId) async {
  final odoo = ref.read(odooServiceProvider);
  return odoo.fetchSeizures(patientId: patientId);
});

final latestSeizureProvider =
    FutureProvider.family<SeizureModel?, String>((ref, patientId) async {
  final list = await ref.watch(
    seizureListProvider(patientId).future);
  return list.isEmpty ? null : list.first;
});