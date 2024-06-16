import 'package:chat/etc/alarm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat/components/popup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderController extends GetxController {
  RxList<Map<String, dynamic>> data = <Map<String, dynamic>>[].obs;
  String? url;

  RxBool selectAll = false.obs;
  RxBool select = false.obs;

  @override
  void onInit() {
    super.onInit();

    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var uid = prefs.getString('user_uid');

      var res = await FirebaseFirestore.instance
          .collection("reminder")
          .where('uid', isEqualTo: uid)
          .orderBy("created_at", descending: true)
          .get();

      data.value = res.docs
          .map((e) => {"id": e.id, "selected": false, ...e.data()})
          .toList();

      await Alarm().scheduleAllAlarms();
      update();
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching data: $e");
    }
  }

  Future<void> addData(BuildContext context, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection("reminder").add({
        "event": data['event'],
        "time": data['time'],
        "repeat": FieldValue.arrayUnion(data['repeat']),
        "reminder_message": data['reminder_message'],
        "stop_message": data['stop_message'],
        "active": true,
        "uid": data['uid'],
        "created_at": Timestamp.now(),
      });
      await fetchData();

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      // ignore: use_build_context_synchronously
      Popup().show(context, "Reminder created successfully", true);
    } catch (e) {
      // ignore: use_build_context_synchronously
      Popup().show(context, "Reminder failed to create", false);
    }
  }

  Future<void> editData(BuildContext context, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection("reminder")
          .doc(data['id'])
          .update({
        "event": data['event'],
        "time": data['time'],
        "repeat": FieldValue.arrayUnion(data['repeat']),
        "reminder_message": data['reminder_message'],
        "stop_message": data['stop_message'],
        "updated_at": Timestamp.now(),
      });
      await fetchData();

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      // ignore: use_build_context_synchronously
      Popup().show(context, "Reminder updated successfully", true);
    } catch (e) {
      // ignore: use_build_context_synchronously
      Popup().show(context, "Reminder failed to update", false);
    }
  }

  Future<void> deleteData(BuildContext context, List<dynamic> ids) async {
    try {
      for (var id in ids) {
        await Alarm().cancelAlarm(id.hashCode);
        await FirebaseFirestore.instance
            .collection("reminder")
            .doc(id)
            .delete();
      }
      await fetchData();

      // ignore: use_build_context_synchronously
      Popup().show(context, "Reminder deleted successfully", true);
    } catch (e) {
      // ignore: use_build_context_synchronously
      Popup().show(context, "Reminder failed to delete", false);
    }
  }
}
