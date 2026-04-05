import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';

const _kRemindersKey = 'epitrack_reminders';

// ── Stream broadcast des rappels déclenchés ───────────────────
final _firedController = StreamController<ReminderModel>.broadcast();

final reminderFiredProvider = StreamProvider<ReminderModel>((ref) {
  return _firedController.stream;
});

// ── Provider liste des rappels ────────────────────────────────
final reminderProvider =
    AsyncNotifierProvider<ReminderNotifier, List<ReminderModel>>(
        ReminderNotifier.new);

class ReminderNotifier extends AsyncNotifier<List<ReminderModel>> {
  Timer?     _timer;
  String     _lastDayKey = '';
  final Set<String> _firedToday = {};

  @override
  Future<List<ReminderModel>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final list  = _load(prefs);
    _startTimer();
    ref.onDispose(() => _timer?.cancel());
    return list;
  }

  // ── Timer interne ─────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
    _check(); // vérification immédiate
  }

  void _check() {
    final now    = DateTime.now();
    final dayKey = '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}';
    if (dayKey != _lastDayKey) {
      _firedToday.clear();
      _lastDayKey = dayKey;
    }
    final list = state.valueOrNull ?? [];
    for (final r in list) {
      if (!r.isActive) continue;
      final key = '${dayKey}_${r.id}';
      if (_firedToday.contains(key)) continue;
      if (r.hour == now.hour && r.minute == now.minute) {
        _firedToday.add(key);
        _firedController.add(r);
      }
    }
  }

  // ── CRUD ──────────────────────────────────────────────────
  Future<void> add(ReminderModel reminder) async {
    final List<ReminderModel> list = [...(state.valueOrNull ?? []), reminder];
    state = AsyncData(list);
    await _save(list);
  }

  Future<void> remove(String id) async {
    final List<ReminderModel> list =
        (state.valueOrNull ?? []).where((r) => r.id != id).toList();
    state = AsyncData(list);
    await _save(list);
  }

  Future<void> toggle(String id) async {
    final List<ReminderModel> list = (state.valueOrNull ?? [])
        .map((r) => r.id == id ? r.copyWith(isActive: !r.isActive) : r)
        .toList();
    state = AsyncData(list);
    await _save(list);
  }

  // ── Persistance ───────────────────────────────────────────
  List<ReminderModel> _load(SharedPreferences prefs) {
    final raw = prefs.getStringList(_kRemindersKey) ?? [];
    return raw.map((s) {
      try {
        return ReminderModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(s) as Map));
      } catch (_) { return null; }
    }).whereType<ReminderModel>().toList();
  }

  Future<void> _save(List<ReminderModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kRemindersKey, list.map((r) => jsonEncode(r.toJson())).toList());
  }
}
