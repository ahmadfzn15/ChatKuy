import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqYv65BdareEhp6w49ZtBd5d-emJG5_aE',
    appId: '1:340738288883:web:85d36a7da33f1d81131b86',
    messagingSenderId: '340738288883',
    projectId: 'chatkuyyy',
    authDomain: 'chatkuyyy.firebaseapp.com',
    storageBucket: 'chatkuyyy.appspot.com',
    measurementId: 'G-0JCXRC8M5D',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCyMUg91y_TNVQTImCgM1PT4G36csvAQPw',
    appId: '1:340738288883:android:6da92090265dc30d131b86',
    messagingSenderId: '340738288883',
    projectId: 'chatkuyyy',
    storageBucket: 'chatkuyyy.appspot.com',
  );
}
