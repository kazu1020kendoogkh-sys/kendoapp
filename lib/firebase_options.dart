import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  // さっきブラウザの画面に表示された「firebaseConfig」の内容をここに当てはめます
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDsZPSKi7_iDDre0qCOocdvIlic3GeMwwo",
    authDomain: "fb-kendo-app.firebaseapp.com",
    projectId: "fb-kendo-app",
    storageBucket: "fb-kendo-app.firebasestorage.app",
    messagingSenderId: "219800903869",
    appId: "1:219800903869:web:9e95311137d1f7799897d4",
    measurementId: "G-62SJM7N14C"
  );
}