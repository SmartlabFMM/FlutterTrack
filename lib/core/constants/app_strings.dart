class AppStrings {
  AppStrings._();

  // App
  static const String appName       = 'EpiTrack';
  static const String appTagline    = 'Surveillance intelligente de l\'épilepsie';

  // Auth
  static const String login         = 'Connexion';
  static const String email         = 'Adresse e-mail';
  static const String password      = 'Mot de passe';
  static const String loginButton   = 'Se connecter';
  static const String logout        = 'Déconnexion';
  static const String loginError    = 'Identifiants incorrects';

  // Navigation
  static const String navHome       = 'Accueil';
  static const String navSignals    = 'Signaux';
  static const String navHistory    = 'Historique';
  static const String navSettings   = 'Réglages';
  static const String navAlerts     = 'Alertes';
  static const String navContacts   = 'Contacts';
  static const String navPatients   = 'Patients';
  static const String navReports    = 'Rapports';

  // Bracelet
  static const String braceletConn  = 'Bracelet connecté';
  static const String braceletDisc  = 'Bracelet déconnecté';
  static const String bleScanning   = 'Recherche du bracelet…';
  static const String blePairing    = 'Connexion en cours…';

  // Crise
  static const String seizureAlert  = 'Crise détectée !';
  static const String seizureScore  = 'Score ML';
  static const String seizureDur    = 'Durée';
  static const String noSeizure     = 'Aucune anomalie détectée';
  static const String lastSeizure   = 'Dernière crise';

  // SOS
  static const String sosHold       = 'Appui long = Alerte SOS';
  static const String sosSent       = 'Alerte SOS envoyée !';
  static const String sosContacts   = 'Vos contacts ont été notifiés';

  // Vitaux
  static const String heartRate     = 'Fréquence cardiaque';
  static const String accel         = 'Convulsions';
  static const String gsr           = 'Conductance cutanée';
  static const String bpm           = 'bpm';
  static const String normal        = 'Normal';

  // Médecin
  static const String myPatients    = 'Mes patients';
  static const String patientFile   = 'Dossier patient';
  static const String vitals24h     = 'Données 24h';
  static const String generatePdf   = 'Générer rapport PDF';
  static const String addNote       = 'Ajouter note clinique';

  // Famille
  static const String emergContacts = 'Contacts d\'urgence';
  static const String callPatient   = 'Appeler le patient';
  static const String callDoctor    = 'Contacter le médecin';
  static const String smsSent       = 'SMS envoyé automatiquement';
}