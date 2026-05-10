const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();

// Supprime un utilisateur de Firebase Auth (appelé depuis l'app Flutter)
exports.deleteAuthUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Non autorisé');
  }

  const uid = request.data.uid;
  if (!uid) {
    throw new HttpsError('invalid-argument', 'UID manquant');
  }

  try {
    await admin.auth().deleteUser(uid);
    return { success: true };
  } catch (error) {
    throw new HttpsError('internal', error.message);
  }
});

