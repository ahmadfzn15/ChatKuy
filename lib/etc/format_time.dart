import 'package:cloud_firestore/cloud_firestore.dart';

String formatTime(Timestamp? timestamp) {
  if (timestamp != null) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(
        timestamp!.seconds * 1000 + timestamp.nanoseconds ~/ 1000000);
    date = date.toLocal();

    String hours = date.hour.toString().padLeft(2, '0');
    String minutes = date.minute.toString().padLeft(2, '0');

    String time = '$hours:$minutes';

    return time;
  } else {
    return "";
  }
}

String formatTime2(timestamp) {
  DateTime date = DateTime.parse(timestamp);
  date = date.toLocal();

  final List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  int day = date.day;
  String time = '${date.hour}:${date.minute}:${date.second}';
  String month = months[date.month - 1];
  int year = date.year;

  String formattedDate = '$time, $day $month $year';

  return formattedDate;
}

String formatTime3(date) {
  final List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  int day = date.day;
  String month = months[date.month - 1];
  int year = date.year;

  String formattedDate = '$day $month $year';

  return formattedDate;
}
