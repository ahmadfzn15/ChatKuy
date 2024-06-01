import 'package:cloud_firestore/cloud_firestore.dart';

String formatTime(Timestamp? timestamp) {
  if (timestamp != null) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(
        timestamp.seconds * 1000 + timestamp.nanoseconds ~/ 1000000);
    date = date.toLocal();

    String hours = date.hour.toString().padLeft(2, '0');
    String minutes = date.minute.toString().padLeft(2, '0');

    String time = '$hours:$minutes';

    return time;
  } else {
    return "";
  }
}
