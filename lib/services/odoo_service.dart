import '../models/user_model.dart';
import '../models/seizure_model.dart';
import '../models/alert_model.dart';

/// Service mock — remplacer les méthodes par de vrais appels Firebase/Odoo
class OdooService {
  // ── Identifiants de démonstration ────────────────────────
  static final _users = <String, _MockUser>{
    'patient@epitrack.com': const _MockUser(
      password: 'patient123', uid: 1,
      name: 'Ahmed Ben Ali', role: UserRole.patient,
      linkedPatientId: '1',
    ),
    'famille@epitrack.com': const _MockUser(
      password: 'famille123', uid: 2,
      name: 'Fatima Ben Ali', role: UserRole.family,
      linkedPatientId: '1',
    ),
    'docteur@epitrack.com': const _MockUser(
      password: 'docteur123', uid: 3,
      name: 'Kamel Trabelsi', role: UserRole.doctor,
    ),
  };

  static int _nextUid = 100;
  String? _sessionId;

  // ── Authentification ────────────────────────────────────
  Future<UserModel> authenticate(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final u = _users[email.toLowerCase().trim()];
    if (u == null || u.password != password) {
      throw Exception('Identifiants incorrects');
    }
    _sessionId = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    return UserModel(
      uid:             u.uid,
      name:            u.name,
      email:           email,
      role:            u.role,
      sessionId:       _sessionId!,
      linkedPatientId: u.linkedPatientId,
    );
  }

  void logout() => _sessionId = null;

  // ── Inscription ─────────────────────────────────────────
  Future<UserModel> register({
    required String   name,
    required String   email,
    required String   password,
    required UserRole role,
    String?           linkedPatientId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final key = email.toLowerCase().trim();
    if (_users.containsKey(key)) {
      throw Exception('Un compte avec cet email existe déjà.');
    }
    final uid = _nextUid++;
    _users[key] = _MockUser(
      password: password, uid: uid, name: name, role: role,
      linkedPatientId: linkedPatientId);
    _sessionId = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    return UserModel(
      uid: uid, name: name, email: email,
      role: role, sessionId: _sessionId!,
      linkedPatientId: linkedPatientId);
  }

  // ── Crises ──────────────────────────────────────────────
  Future<List<SeizureModel>> fetchSeizures({required String patientId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final name = _patientNameById(patientId);
    final now  = DateTime.now();

    // Données variées selon le patient
    final base = int.tryParse(patientId) ?? 1;
    final seed = base % 5;
    return [
      SeizureModel(id: base * 10 + 1, patientId: patientId,
        patientName: name,
        datetime: now.subtract(Duration(hours: 3 + seed * 2)),
        durationSeconds: 60 + seed * 15, mlScore: 0.88 + seed * 0.02,
        acknowledged: true),
      SeizureModel(id: base * 10 + 2, patientId: patientId,
        patientName: name,
        datetime: now.subtract(Duration(days: 4 + seed, hours: 2)),
        durationSeconds: 40 + seed * 10, mlScore: 0.82 + seed * 0.02,
        acknowledged: true),
      SeizureModel(id: base * 10 + 3, patientId: patientId,
        patientName: name,
        datetime: now.subtract(Duration(days: 10 + seed * 2)),
        durationSeconds: 90 + seed * 5, mlScore: 0.91 + seed * 0.01,
        acknowledged: true),
      SeizureModel(id: base * 10 + 4, patientId: patientId,
        patientName: name,
        datetime: now.subtract(Duration(days: 18 + seed)),
        durationSeconds: 55 + seed * 8, mlScore: 0.85 + seed * 0.02,
        acknowledged: true),
      SeizureModel(id: base * 10 + 5, patientId: patientId,
        patientName: name,
        datetime: now.subtract(Duration(days: 25 + seed * 2)),
        durationSeconds: 75 + seed * 6, mlScore: 0.89 + seed * 0.01,
        acknowledged: true),
      SeizureModel(id: base * 10 + 6, patientId: patientId,
        patientName: name,
        datetime: now.subtract(Duration(days: 35 + seed)),
        durationSeconds: 50 + seed * 12, mlScore: 0.86 + seed * 0.02,
        acknowledged: true),
    ];
  }

  // ── Alertes ─────────────────────────────────────────────
  Future<List<AlertModel>> fetchAlerts(
      {required int userId, required UserRole role}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      AlertModel(id: 1, type: AlertType.seizureDetected,
        status: AlertStatus.unread,
        patientId: '1', patientName: 'Ahmed Ben Ali',
        datetime: now.subtract(const Duration(hours: 2)),
        mlScore: 0.94, durationSeconds: 83),
      AlertModel(id: 2, type: AlertType.seizureDetected,
        status: AlertStatus.unread,
        patientId: '5', patientName: 'Nour El Houda Belkadi',
        datetime: now.subtract(const Duration(hours: 5)),
        mlScore: 0.91, durationSeconds: 65),
      AlertModel(id: 3, type: AlertType.seizureDetected,
        status: AlertStatus.read,
        patientId: '9', patientName: 'Mariem Chaabane',
        datetime: now.subtract(const Duration(hours: 18)),
        mlScore: 0.88, durationSeconds: 52),
      AlertModel(id: 4, type: AlertType.seizureDetected,
        status: AlertStatus.read,
        patientId: '1', patientName: 'Ahmed Ben Ali',
        datetime: now.subtract(const Duration(days: 1, hours: 3)),
        mlScore: 0.87, durationSeconds: 45),
      AlertModel(id: 5, type: AlertType.sosManual,
        status: AlertStatus.acknowledged,
        patientId: '12', patientName: 'Anas Mejri',
        datetime: now.subtract(const Duration(days: 2))),
      AlertModel(id: 6, type: AlertType.seizureDetected,
        status: AlertStatus.acknowledged,
        patientId: '3', patientName: 'Karim Tlili',
        datetime: now.subtract(const Duration(days: 3)),
        mlScore: 0.92, durationSeconds: 110),
      AlertModel(id: 7, type: AlertType.seizureDetected,
        status: AlertStatus.acknowledged,
        patientId: '7', patientName: 'Rania Zouari',
        datetime: now.subtract(const Duration(days: 5)),
        mlScore: 0.86, durationSeconds: 40),
    ];
  }

  // ── Patients (médecin) ──────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchMyPatients(int doctorUserId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    final h   = now.subtract(const Duration(hours: 2));

    return [
      // ─── En alerte ─────────────────────────────────────
      {
        'id': '1', 'name': 'Ahmed Ben Ali', 'age': 28,
        'status': 'seizure',
        'lastSeizure': 'Aujourd\'hui ${h.hour}h${h.minute.toString().padLeft(2,'0')}',
        'monthCount': 3,
        'diagnosis': 'Épilepsie tonico-clonique généralisée',
        'treatment': 'Valproate 500mg · 2×/j',
        'phone': '+216 71 XXX XXX',
        'city': 'Tunis',
        'nextRdv': 'Lundi 7 avr.',
        'notes': 'Stress récent signalé. Augmenter le suivi.',
      },
      {
        'id': '5', 'name': 'Nour El Houda Belkadi', 'age': 31,
        'status': 'seizure',
        'lastSeizure': 'Aujourd\'hui 07h14',
        'monthCount': 4,
        'diagnosis': 'Épilepsie focale temporale',
        'treatment': 'Lamotrigine 100mg · 2×/j',
        'phone': '+216 72 XXX XXX',
        'city': 'Sfax',
        'nextRdv': 'Mercredi 9 avr.',
        'notes': 'Réduction de dose envisagée si stable 3 mois.',
      },

      // ─── Stables ───────────────────────────────────────
      {
        'id': '2', 'name': 'Sara Mansouri', 'age': 35,
        'status': 'stable',
        'lastSeizure': 'Il y a 14 jours',
        'monthCount': 1,
        'diagnosis': 'Épilepsie d\'absence de l\'adulte',
        'treatment': 'Éthosuximide 250mg · 2×/j',
        'phone': '+216 73 XXX XXX',
        'city': 'Sousse',
        'nextRdv': 'Vendredi 11 avr.',
        'notes': 'Bonne compliance au traitement.',
      },
      {
        'id': '4', 'name': 'Leila Gharbi', 'age': 42,
        'status': 'stable',
        'lastSeizure': 'Il y a 21 jours',
        'monthCount': 1,
        'diagnosis': 'Épilepsie myoclonique juvénile',
        'treatment': 'Lévétiracétam 500mg · 2×/j',
        'phone': '+216 74 XXX XXX',
        'city': 'Monastir',
        'nextRdv': 'Mardi 15 avr.',
        'notes': 'Rythme de sommeil amélioré. Continuer suivi.',
      },
      {
        'id': '6', 'name': 'Youssef Hamdi', 'age': 19,
        'status': 'stable',
        'lastSeizure': 'Il y a 18 jours',
        'monthCount': 1,
        'diagnosis': 'Épilepsie bénigne rolandique',
        'treatment': 'Carbamazépine 200mg · 2×/j',
        'phone': '+216 75 XXX XXX',
        'city': 'Tunis',
        'nextRdv': 'Jeudi 17 avr.',
        'notes': 'Rémission probable avant 20 ans.',
      },
      {
        'id': '7', 'name': 'Rania Zouari', 'age': 26,
        'status': 'stable',
        'lastSeizure': 'Il y a 10 jours',
        'monthCount': 2,
        'diagnosis': 'Épilepsie tonico-clonique généralisée',
        'treatment': 'Valproate 300mg · 2×/j + Clonazépam 0.5mg',
        'phone': '+216 76 XXX XXX',
        'city': 'Bizerte',
        'nextRdv': 'Lundi 14 avr.',
        'notes': 'Enceinte (S12) — adapter traitement.',
      },
      {
        'id': '8', 'name': 'Sami Boughzala', 'age': 53,
        'status': 'stable',
        'lastSeizure': 'Il y a 1 mois',
        'monthCount': 1,
        'diagnosis': 'Épilepsie focale occipitale',
        'treatment': 'Oxcarbazépine 600mg · 2×/j',
        'phone': '+216 77 XXX XXX',
        'city': 'Gabès',
        'nextRdv': 'Mercredi 16 avr.',
        'notes': 'IRM programmée en mai.',
      },
      {
        'id': '9', 'name': 'Mariem Chaabane', 'age': 38,
        'status': 'stable',
        'lastSeizure': 'Il y a 5 jours',
        'monthCount': 2,
        'diagnosis': 'Épilepsie focale frontale',
        'treatment': 'Phénytoine 100mg · 3×/j',
        'phone': '+216 78 XXX XXX',
        'city': 'Nabeul',
        'nextRdv': 'Vendredi 18 avr.',
        'notes': 'Taux plasmatique à vérifier prochain RDV.',
      },
      {
        'id': '10', 'name': 'Khaled Jebali', 'age': 45,
        'status': 'stable',
        'lastSeizure': 'Il y a 3 semaines',
        'monthCount': 1,
        'diagnosis': 'Épilepsie post-traumatique',
        'treatment': 'Lévétiracétam 750mg · 2×/j',
        'phone': '+216 79 XXX XXX',
        'city': 'Kairouan',
        'nextRdv': 'Mardi 22 avr.',
        'notes': 'Suite AVC ischémique 2022. Suivi neuro + épileptologue.',
      },
      {
        'id': '11', 'name': 'Amel Khedher', 'age': 29,
        'status': 'stable',
        'lastSeizure': 'Il y a 12 jours',
        'monthCount': 2,
        'diagnosis': 'Épilepsie limbique auto-immune',
        'treatment': 'Lévétiracétam 1000mg + Méthylprednisolone IV',
        'phone': '+216 80 XXX XXX',
        'city': 'Tunis',
        'nextRdv': 'Jeudi 24 avr.',
        'notes': 'Anticorps anti-LGI1 positifs. Immunothérapie en cours.',
      },
      {
        'id': '13', 'name': 'Fatma Riahi', 'age': 61,
        'status': 'stable',
        'lastSeizure': 'Il y a 1 mois',
        'monthCount': 1,
        'diagnosis': 'Épilepsie symptomatique vasculaire',
        'treatment': 'Valproate 500mg + Aspirine 100mg',
        'phone': '+216 81 XXX XXX',
        'city': 'Ariana',
        'nextRdv': 'Lundi 28 avr.',
        'notes': 'Diabétique type 2 — surveiller interaction médicamenteuse.',
      },
      {
        'id': '14', 'name': 'Tarek Sfaxi', 'age': 33,
        'status': 'stable',
        'lastSeizure': 'Il y a 25 jours',
        'monthCount': 1,
        'diagnosis': 'Épilepsie avec crises atoniques',
        'treatment': 'Rufinamide 400mg · 2×/j',
        'phone': '+216 82 XXX XXX',
        'city': 'La Marsa',
        'nextRdv': 'Mercredi 30 avr.',
        'notes': 'Suivi neuropsychologique en cours.',
      },

      // ─── Hors ligne ────────────────────────────────────
      {
        'id': '3', 'name': 'Karim Tlili', 'age': 22,
        'status': 'offline',
        'lastSeizure': 'Il y a 1 mois',
        'monthCount': 0,
        'diagnosis': 'Épilepsie idiopathique généralisée',
        'treatment': 'Valproate 250mg · 2×/j',
        'phone': '+216 83 XXX XXX',
        'city': 'Mahdia',
        'nextRdv': 'À planifier',
        'notes': 'Bracelet déchargé. Relancer contact.',
      },
      {
        'id': '12', 'name': 'Anas Mejri', 'age': 17,
        'status': 'offline',
        'lastSeizure': 'Il y a 2 semaines',
        'monthCount': 2,
        'diagnosis': 'Épilepsie myoclonique juvénile',
        'treatment': 'Lévétiracétam 500mg · 2×/j',
        'phone': '+216 84 XXX XXX',
        'city': 'Manouba',
        'nextRdv': 'À planifier',
        'notes': 'Mineur — consentement parental requis. Parents contactés.',
      },
      {
        'id': '15', 'name': 'Houda Soltani', 'age': 48,
        'status': 'offline',
        'lastSeizure': 'Il y a 3 semaines',
        'monthCount': 0,
        'diagnosis': 'Épilepsie focale cryptogénique',
        'treatment': 'Lamotrigine 150mg · 2×/j',
        'phone': '+216 85 XXX XXX',
        'city': 'Ben Arous',
        'nextRdv': 'À planifier',
        'notes': 'Perdue de vue depuis décembre. Relance courrier envoyé.',
      },
    ];
  }

  // ── Données détail patient (pour fiche dossier) ─────────
  static Map<String, dynamic>? patientDetail(String id) {
    return _patientDetails[id];
  }

  static const _patientDetails = <String, Map<String, dynamic>>{
    '1': {
      'age': 28, 'gender': 'Homme', 'city': 'Tunis',
      'diagnosis': 'Épilepsie tonico-clonique généralisée',
      'since': 'Suivi depuis mars 2024',
      'treatment': 'Valproate 500mg · 2×/j',
      'phone': '+216 71 XXX XXX',
      'nextRdv': 'Lundi 7 avr.',
      'notes': [
        {'date': '28 mars', 'text': 'Stress au travail signalé. Augmenter vigilance.'},
        {'date': '12 mars', 'text': 'Efficacité Valproate confirmée. Maintenir dose.'},
        {'date': '02 fév.', 'text': 'Début du suivi avec bracelet EpiTrack.'},
      ],
      'allergies': 'Pénicilline',
      'bloodGroup': 'A+',
      'weight': '74 kg',
      'seizureType': 'Tonico-clonique · Grand mal',
      'triggers': ['Manque de sommeil', 'Stress', 'Alcool'],
      'compliance': 0.92,
    },
    '2': {
      'age': 35, 'gender': 'Femme', 'city': 'Sousse',
      'diagnosis': 'Épilepsie d\'absence de l\'adulte',
      'since': 'Suivi depuis juin 2023',
      'treatment': 'Éthosuximide 250mg · 2×/j',
      'phone': '+216 73 XXX XXX',
      'nextRdv': 'Vendredi 11 avr.',
      'notes': [
        {'date': '25 mars', 'text': 'Bonne compliance. Aucune crise ce mois.'},
        {'date': '10 jan.', 'text': 'Réduction de dose tentée — 1 crise. Retour ancienne dose.'},
      ],
      'allergies': 'Aucune connue',
      'bloodGroup': 'O+',
      'weight': '62 kg',
      'seizureType': 'Absence · Petit mal',
      'triggers': ['Hyperventilation', 'Lumières clignotantes'],
      'compliance': 0.97,
    },
    '3': {
      'age': 22, 'gender': 'Homme', 'city': 'Mahdia',
      'diagnosis': 'Épilepsie idiopathique généralisée',
      'since': 'Suivi depuis sept. 2024',
      'treatment': 'Valproate 250mg · 2×/j',
      'phone': '+216 83 XXX XXX',
      'nextRdv': 'À planifier',
      'notes': [
        {'date': '01 mars', 'text': 'Bracelet déchargé depuis 1 semaine. Relancer patient.'},
      ],
      'allergies': 'Aucune connue',
      'bloodGroup': 'B+',
      'weight': '68 kg',
      'seizureType': 'Tonico-clonique généralisée',
      'triggers': ['Manque de sommeil', 'Jeux vidéo'],
      'compliance': 0.71,
    },
  };

  // ── Liste patients (pour la famille à l'inscription) ────
  static List<Map<String, String>> allPatients() {
    return List.generate(15, (i) {
      final id = '${i + 1}';
      return {'id': id, 'name': _patientNameById(id)};
    });
  }

  // ── Helpers publics ─────────────────────────────────────
  static String patientName(String id) => _patientNameById(id);

  static String _patientNameById(String id) => switch (id) {
    '1'  => 'Ahmed Ben Ali',
    '2'  => 'Sara Mansouri',
    '3'  => 'Karim Tlili',
    '4'  => 'Leila Gharbi',
    '5'  => 'Nour El Houda Belkadi',
    '6'  => 'Youssef Hamdi',
    '7'  => 'Rania Zouari',
    '8'  => 'Sami Boughzala',
    '9'  => 'Mariem Chaabane',
    '10' => 'Khaled Jebali',
    '11' => 'Amel Khedher',
    '12' => 'Anas Mejri',
    '13' => 'Fatma Riahi',
    '14' => 'Tarek Sfaxi',
    '15' => 'Houda Soltani',
    _    => 'Patient #$id',
  };
}

class _MockUser {
  final String   password, name;
  final int      uid;
  final UserRole role;
  final String?  linkedPatientId;
  const _MockUser({
    required this.password, required this.uid,
    required this.name,     required this.role,
    this.linkedPatientId,
  });
}
