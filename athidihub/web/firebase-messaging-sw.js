/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAjr0eqOlhkm3X35Y6Ir1wHudlnQcnjEPE',
  appId: '1:749268725625:web:6cac924cc5573bd88a09a8',
  messagingSenderId: '749268725625',
  projectId: 'athidihub',
  authDomain: 'athidihub.firebaseapp.com',
  storageBucket: 'athidihub.firebasestorage.app',
  measurementId: 'G-FBV89SP8HP',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || payload.data?.title || 'Athidihub';
  const body = payload.notification?.body || payload.data?.body || '';
  const route = payload.data?.route || '/';

  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: {
      route,
      ...payload.data,
    },
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const route = event.notification.data?.route || '/';
  const url = new URL(route, self.location.origin).toString();

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if ('focus' in client) {
          client.focus();
          client.postMessage({ type: 'notification-click', route });
          return;
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(url);
      }

      return undefined;
    }),
  );
});
