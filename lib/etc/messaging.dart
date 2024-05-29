import 'package:firebase_messaging/firebase_messaging.dart';

class Messaging {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initMessaging() async {
    await _firebaseMessaging.requestPermission();

    final token = await _firebaseMessaging.getToken();
  }
}
