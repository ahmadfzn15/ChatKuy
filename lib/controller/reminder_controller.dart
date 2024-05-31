import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:sioren/components/popup.dart';

class ReminderController extends GetxController {
  RxList<dynamic> data = [].obs;
  String url = dotenv.env['API_URL']!;
  RxBool selectAll = false.obs;
  RxBool select = false.obs;

  Future<void> fetchData() async {
    var res = await FirebaseFirestore.instance
        .collection("reminder")
        .orderBy("created_at", descending: true)
        .get();

    data = res.docs
        .map((e) => {"id": e.id, "selected": false, ...e.data()})
        .toList()
        .obs;
    update();
  }

  Future<void> addData(BuildContext context, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection("reminder").add({
        "event": data['event'],
        "time": data['time'],
        "reminder_message": data['reminder_message'],
        "stop_message": data['stop_message'],
        "active": true,
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
        "reminder_message": data['reminder_message'],
        "stop_message": data['stop_message'],
        "active": data['active'],
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

  Future<void> deleteData(BuildContext context, List<String> ids) async {
    try {
      for (var id in ids) {
        await FirebaseFirestore.instance
            .collection("reminder")
            .doc(id)
            .delete();
      }
      await fetchData();

      // ignore: use_build_context_synchronously
      Popup().show(context, "Reminder(s) deleted successfully", true);
    } catch (e) {
      // ignore: use_build_context_synchronously
      Popup().show(context, "Reminder(s) failed to delete", false);
    }
  }
}
