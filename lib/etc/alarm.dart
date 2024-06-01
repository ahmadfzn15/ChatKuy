import 'dart:async';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sioren/main.dart';
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

      if (alarmTime.isAfter(DateTime.now())) {
        int alarmId = reminder['id'].hashCode;

        await AndroidAlarmManager.oneShotAt(
          alarmTime,
          alarmId,
          alarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: {
            "id": alarmId,
            "event": reminder['event'],
            "reminder_message": reminder['reminder_message'],
            "stop_message": reminder['stop_message']
          },
        );
      }
    }
  }
}

void alarmCallback(int id, Map<String, dynamic> data) async {
  if (isAlarmActive) return;
  isAlarmActive = true;
  await flutterTts.setLanguage("id-ID");
  await flutterTts.setSpeechRate(0.6);
  await flutterTts.setVolume(1.0);
  await flutterTts.setPitch(1.05);

  AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    id.toString(),
    'alarm',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
  );

  NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    id,
    data['event'] ?? '',
    data['reminder_message'] ?? '',
    platformChannelSpecifics,
  );

  _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
    await flutterTts.speak(data['reminder_message'] ?? '');
  });

  startListening(id, data['stop_message']);
}

void startListening(int id, String message) async {
  bool available = await speech.initialize(
      // ignore: avoid_print
      onStatus: (val) => print('onStatus: $val'),
      // ignore: avoid_print
      onError: (val) => print('onError: $val'));

  if (available) {
    speech.listen(
      onResult: (val) {
        if (val.recognizedWords.toLowerCase() == message) {
          cancelAlarm(id);
        } else {
          startListening(id, message);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
      ),
      listenFor: const Duration(minutes: 1),
      localeId: 'id-ID',
    );
  } else {
    startListening(id, message);
  }
}

void cancelAlarm(int id) {
  _timer?.cancel();
  flutterLocalNotificationsPlugin.cancel(id);
  speech.stop();
  flutterTts.stop();
  isAlarmActive = false;
}
