import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDiSIjNCrRYb6nCU-yCBXzam0WBpHd6yTs',
    appId: '1:114088417877:android:14bf656ac91ec588c092dc',
    messagingSenderId: '114088417877',
    projectId: 'sales-auditor-562b0',
    storageBucket: 'sales-auditor-562b0.firebasestorage.app',
  );
}
