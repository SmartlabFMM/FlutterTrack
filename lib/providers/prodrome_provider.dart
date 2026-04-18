import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProdromeEntry {
  final String id;
  final DateTime date;
  final List<String> symptoms;
  final String note;

  const ProdromeEntry({
    required this.id,
    required this.date,
    required this.symptoms,
    required this.note,
  });

  factory ProdromeEntry.fromMap(Map<String, dynamic> m) => ProdromeEntry(
    id:       m['id']       as String? ?? '',
    date:     DateTime.parse(m['date'] as String),
    symptoms: List<String>.from(m['symptoms'] as List? ?? []),
    note:     m['note']     as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id':       id,
    'date':     date.toIso8601String(),
    'symptoms': symptoms,
    'note':     note,
  };
}

final prodromeProvider =
    StreamProvider.family<List<ProdromeEntry>, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('prodromes')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => ProdromeEntry.fromMap(d.data()))
          .toList());
});

Future<void> addProdrome(String uid, ProdromeEntry entry) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('prodromes')
      .doc(entry.id)
      .set(entry.toMap());
}

Future<void> deleteProdrome(String uid, String id) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('prodromes')
      .doc(id)
      .delete();
}
