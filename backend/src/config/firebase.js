const admin = require('firebase-admin');

let firebaseApp;

const initFirebase = () => {
  if (!firebaseApp && process.env.FIREBASE_PROJECT_ID) {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
    });
  }
  return firebaseApp;
};

const sendNotification = async (token, title, body, data = {}) => {
  try {
    if (!firebaseApp) return;
    const message = { token, notification: { title, body }, data };
    await admin.messaging().send(message);
  } catch (err) {
    console.error('FCM error:', err.message);
  }
};

module.exports = { initFirebase, sendNotification };
