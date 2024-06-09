import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Messaging {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final api = dotenv.env['API_CLOUD_MESSAGING'];
  final authorization = dotenv.env['AUTHORIZATION'];

  Future<void> initMessaging() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // ignore: avoid_print
        print('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        // ignore: avoid_print
        print('User granted provisional permission');
      } else {
        // ignore: avoid_print
        print('User declined or has not accepted permission');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error initializing messaging: $e');
    }
  }

  Future<void> sendNotif(String token, String title, String body) async {
    try {
      await http.post(Uri.parse(api!),
          headers: {
            "Authorization": authorization!,
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "message": {
              "token": token,
              "notification": {
                "title": title,
                "body": body,
              }
            }
          }));
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }
}
