const admin = require('firebase-admin');
const path = require('path');
const dotenv = require('dotenv');
dotenv.config();

// Use service account key from environment variable if provided
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_KEY_PATH;

if (!admin.apps.length) {
  if (serviceAccountPath) {
    admin.initializeApp({
      credential: admin.credential.cert(require(path.resolve(serviceAccountPath))),
    });
  } else {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  }
}

/**
 * Send a push notification via FCM
 * @param {string} token - FCM device token
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} [data] - Optional data payload
 */
async function sendPushNotification(token, title, body, data = {}) {
  const message = {
    token,
    notification: {
      title,
      body,
    },
    data,
  };
  try {
    const response = await admin.messaging().send(message);
    return response;
  } catch (err) {
    console.error('Error sending push notification:', err.message);
    throw err;
  }
}

module.exports = { sendPushNotification }; 