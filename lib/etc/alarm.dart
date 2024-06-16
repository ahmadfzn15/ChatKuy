import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Alarm {
  static const platform = MethodChannel('com.example.app/alarm');

  Future<void> scheduleAllAlarms() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var uid = prefs.getString('user_uid');

      if (uid!.isNotEmpty) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('reminder')
            .where("active", isEqualTo: true)
            .where("uid", isEqualTo: uid)
            .get();
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          var i = doc.id;

          var timestamp = data['time'];
          DateTime time = DateTime.fromMillisecondsSinceEpoch(
              timestamp.seconds * 1000 + timestamp.nanoseconds ~/ 1000000);

          int requestCode = i.hashCode;

          await platform.invokeMethod('scheduleAlarm', {
            "requestCode": requestCode,
            "hour": time.hour,
            "minute": time.minute,
            "title": data['event'],
            "message": data['reminder_message'],
            "stop_message": data['stop_message'],
            "repeat": data['repeat'],
          });

          // ignore: avoid_print
          print("Scheduler successfully for ${data['event']}");
        }
      } else {
        // ignore: avoid_print
        print("uid is empty");
      }
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print("Failed to schedule alarm: ${e.message}");
    }
  }

  Future<void> cancelAlarm(int requestCode) async {
    try {
      await platform.invokeMethod('cancelAlarm', {
        "requestCode": requestCode,
      });
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print("Failed to cancel alarm: ${e.message}");
    }
  }
}
