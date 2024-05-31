import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Messaging {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final api = dotenv.env['API_CLOUD_MESSAGING'];
  final authorization = dotenv.env['AUTHORIZATION'];

  Future<void> initMessaging() async {
    await _firebaseMessaging.requestPermission();

    final token = await _firebaseMessaging.getToken();

    // ignore: avoid_print
    print(token);
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
      print(e);
    }
  }
}
