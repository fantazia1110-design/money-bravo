const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationOnNewLog = functions.firestore
    .document('users/{userId}/logs/{logId}')
    .onCreate(async (snap, context) => {
        const logData = snap.data();
        const userId = context.params.userId;

        // منع إرسال إشعار عند تسجيل الدخول لتجنب الإزعاج
        if (logData.action && logData.action.includes('تسجيل الدخول')) {
            return null;
        }

        const byUser = logData.by || 'مستخدم';
        const action = logData.action || 'نشاط جديد';

        const message = {
            notification: {
                title: 'إشعار جديد 🔔',
                body: `قام ${byUser} بـ ${action}`
            },
            android: {
                notification: {
                    sound: 'default'
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default'
                    }
                }
            },
            topic: `group_${userId}`
        };

        return admin.messaging().send(message);
    });