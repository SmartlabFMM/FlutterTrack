import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class Contact {
  final String name;
  final String phone;
  final String role;
  const Contact({required this.name, required this.phone, required this.role});

  factory Contact.fromMap(Map<String, dynamic> m) => Contact(
    name:  m['name']  as String? ?? '',
    phone: m['phone'] as String? ?? '',
    role:  m['role']  as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name':  name,
    'phone': phone,
    'role':  role,
  };
}

final contactProvider =
    StreamProvider.autoDispose<List<Contact>>((ref) {
  final uid = ref.watch(authProvider).user?.uid;
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) {
    final raw = snap.data()?['contacts'];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Contact.fromMap)
        .toList();
  });
});

Future<void> addContact(String uid, Contact contact) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'contacts': FieldValue.arrayUnion([contact.toMap()])
  }, SetOptions(merge: true));
}

Future<void> removeContact(String uid, Contact contact) async {
  final doc = await FirebaseFirestore.instance
      .collection('users').doc(uid).get();
  final raw = doc.data()?['contacts'];
  if (raw is! List) return;

  final updated = raw
      .whereType<Map<String, dynamic>>()
      .where((m) =>
          m['name']  != contact.name ||
          m['phone'] != contact.phone ||
          m['role']  != contact.role)
      .toList();

  await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'contacts': updated}, SetOptions(merge: true));
}
