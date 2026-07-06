// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase config shared with Maksab customer apps (chat Firestore).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMEqWRV6IufIK8vGwa92gd7Ml9BQnbhPQ',
    appId: '1:1091888758486:android:9284cba638c5a8c35b9377',
    messagingSenderId: '1091888758486',
    projectId: 'maksab-production-c93fb',
    storageBucket: 'maksab-production-c93fb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAlC7ZR0HFyqfLFFsVrUS_qlvODqX_bVus',
    appId: '1:1091888758486:ios:ca4c1ac31f28e0025b9377',
    messagingSenderId: '1091888758486',
    projectId: 'maksab-production-c93fb',
    storageBucket: 'maksab-production-c93fb.firebasestorage.app',
    iosBundleId: 'om.maksab.admin',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBMEqWRV6IufIK8vGwa92gd7Ml9BQnbhPQ',
    appId: '1:1091888758486:web:9284cba638c5a8c35b9377',
    messagingSenderId: '1091888758486',
    projectId: 'maksab-production-c93fb',
    storageBucket: 'maksab-production-c93fb.firebasestorage.app',
  );
}
