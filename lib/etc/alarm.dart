import 'dart:async';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:chat/main.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

final FlutterTts flutterTts = FlutterTts();
final stt.SpeechToText speech = stt.SpeechToText();
Timer? _timer;
bool isAlarmActive = false;

Future<void> initializeTts() async {
  await flutterTts.setLanguage("id-ID");
  await flutterTts.setSpeechRate(0.6);
  await flutterTts.setVolume(1.0);
  await flutterTts.setPitch(1.05);
}

Future<void> activateAllAlarms(List<Map<String, dynamic>> data) async {
  for (var reminder in data) {
    if (reminder['active']) {
      var time = reminder['time'];
      DateTime alarmTime = DateTime.fromMillisecondsSinceEpoch(
          time.seconds * 1000 + time.nanoseconds ~/ 1000000);

      int alarmId = reminder['id'].hashCode;
      DateTime now = DateTime.now();

      // await AndroidAlarmManager.periodic(
      //   const Duration(hours: 24),
      //   alarmId,
      //   alarmCallback,
      //   allowWhileIdle: true,
      //   exact: true,
      //   wakeup: true,
      //   rescheduleOnReboot: true,
      //   startAt: DateTime(
      //       now.year, now.month, now.day, alarmTime.hour, alarmTime.minute),
      //   params: {
      //     "id": alarmId,
      //     "event": reminder['event'],
      //     "reminder_message": reminder['reminder_message'],
      //     "stop_message": reminder['stop_message']
      //   },
      // );

      print("Successfully");
    }
  }
}

Future<void> reinitializeAlarms() async {
  var reminders = await FirebaseFirestore.instance
      .collection("reminder")
      .orderBy("created_at", descending: true)
      .get();

  for (var reminder in reminders.docs) {
    if (reminder['active']) {
      DateTime alarmTime = DateTime.fromMillisecondsSinceEpoch(
          reminder['time'].seconds * 1000 +
              reminder['time'].nanoseconds ~/ 1000000);

      int alarmId = reminder.id.hashCode;
      DateTime now = DateTime.now();

      // await AndroidAlarmManager.periodic(
      //   const Duration(seconds: 10),
      //   alarmId,
      //   alarmCallback,
      //   allowWhileIdle: true,
      //   exact: true,
      //   wakeup: true,
      //   rescheduleOnReboot: true,
      //   startAt: DateTime(
      //       now.year, now.month, now.day, alarmTime.hour, alarmTime.minute),
      //   params: {
      //     "id": alarmId,
      //     "event": reminder['event'],
      //     "reminder_message": reminder['reminder_message'],
      //     "stop_message": reminder['stop_message']
      //   },
      // );
    } else {
      // ignore: avoid_print
      print("No reminder active");
    }
  }
}

@pragma('vm:entry-point')
void alarmCallback(int id, Map<String, dynamic> data) async {
  if (isAlarmActive) return;
  isAlarmActive = true;
  await flutterTts.setLanguage("id-ID");
  await flutterTts.setSpeechRate(0.6);
  await flutterTts.setVolume(1.0);
  await flutterTts.setPitch(1.05);

  AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(id.toString(), 'alarm',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          actions: [const AndroidNotificationAction("1", "Stop")]);

  NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(id, data['event'] ?? '',
      data['reminder_message'] ?? '', platformChannelSpecifics,
      payload: id.toString());

  _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
    await flutterTts.speak(data['reminder_message'] ?? '');
  });
}

// startListening(id.toString(), data['stop_message']);
void startListening(String id, String message,
    {int attempts = 0, int maxAttempts = 60}) async {
  bool available = await speech.initialize(onStatus: (val) {
    if (val == 'done' && attempts < maxAttempts) {
      startListening(id, message,
          attempts: attempts + 1, maxAttempts: maxAttempts);
    }
  });

  if (available && !speech.isListening) {
    speech.listen(
      onResult: (val) {
        if (val.recognizedWords.toLowerCase() == message) {
          cancelAlarm(id);
        }
      },
      listenFor: const Duration(seconds: 60),
      localeId: 'id-ID',
    );
  } else if (attempts < maxAttempts) {
    startListening(id, message,
        attempts: attempts + 1, maxAttempts: maxAttempts);
  } else {
    cancelAlarm(id);
  }
}

void cancelAlarm(String id) {
  _timer?.cancel();
  flutterLocalNotificationsPlugin.cancel(int.parse(id));
  speech.stop();
  flutterTts.stop();
  isAlarmActive = false;
}

void notificationTapBackground(NotificationResponse notificationResponse) {
  if (notificationResponse.payload != null) {
    handleNotificationResponse(notificationResponse.payload!);
  }
}

void handleNotificationResponse(String payload) {
  cancelAlarm(payload);
}

void speak() async {
  await flutterTts.speak("Halo guys lagi ngapain?");
}
