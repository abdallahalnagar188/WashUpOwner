import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// The owner app's entries in the shared Firebase project. These are public
/// client identifiers, not secrets.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ? _ios : _android;

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'AIzaSyBD-Fzlas_2aXXxFD4kgGAyKsodAlKwX3M',
    appId: '1:811849169779:ios:2d312fed4fe1f513bea306',
    messagingSenderId: '811849169779',
    projectId: 'chatapp-188',
    storageBucket: 'chatapp-188.firebasestorage.app',
    iosBundleId: 'com.alnagar.washup.owner',
  );

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyCQ7Lp-vfgMQirHPkwieqjxqC1znfJNSqw',
    appId: '1:811849169779:android:ee71cc401120a7a2bea306',
    messagingSenderId: '811849169779',
    projectId: 'chatapp-188',
    storageBucket: 'chatapp-188.firebasestorage.app',
  );
}
