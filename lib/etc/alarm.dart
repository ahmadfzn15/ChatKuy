import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sioren/main.dart';

final FlutterTts flutterTts = FlutterTts();

Future<void> initializeTts() async {
  await flutterTts.setLanguage("id-ID");
  await flutterTts.setSpeechRate(0.6);
  await flutterTts.setVolume(1.0);
  await flutterTts.setPitch(1.05);
}

Future<void> activateAllAlarms(data) async {
  for (var reminder in data) {
    if (reminder['active']) {
      DateTime alarmTime = DateTime.parse(reminder['time']);
      int alarmId = reminder['id'].hashCode;

      await AndroidAlarmManager.oneShotAt(
        alarmTime,
        alarmId,
        () => alarmCallback(alarmId, reminder['reminder_message']),
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    }
  }
}

void alarmCallback(int id, String body) async {
  await flutterTts.speak(body);
  await Future.delayed(const Duration(minutes: 1));
  await flutterLocalNotificationsPlugin.cancel(id);
}

void speak(String text) async {
  await flutterTts.speak(text);
}
