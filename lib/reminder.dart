import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:get/get.dart';
import 'package:sioren/add_reminder.dart';
import 'package:sioren/controller/reminder_controller.dart';
import 'package:sioren/edit_reminder.dart';
import 'package:sioren/etc/alarm.dart';
import 'package:sioren/etc/format_time.dart';

class Reminder extends StatefulWidget {
  const Reminder({super.key, required this.user});
  final User? user;

  @override
  // ignore: library_private_types_in_public_api
  _ReminderState createState() => _ReminderState();
}

class _ReminderState extends State<Reminder> {
  final reminderController = Get.put(ReminderController());

  @override
  void initState() {
    super.initState();
    getData().then((_) {
      activateAllAlarms(reminderController.data);
    });
  }

  Future<void> getData() async {
    await reminderController.fetchData();
  }

  Future<void> changeStatus(String id, bool status, int index) async {
    setState(() {
      reminderController.data[index]['active'] = status;
    });

    try {
      await FirebaseFirestore.instance
          .collection("reminder")
          .doc(id)
          .update({"active": status});

      int alarmId = id.hashCode;

      if (status) {
        DateTime alarmTime =
            DateTime.parse(reminderController.data[index]['time']);
        await AndroidAlarmManager.oneShotAt(
          alarmTime,
          alarmId,
          () => alarmCallback(
              alarmId, reminderController.data[index]['reminder_message']),
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
      } else {
        await AndroidAlarmManager.cancel(alarmId);
      }
    } catch (e) {
      setState(() {
        reminderController.data[index]['active'] = !status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            _goPage(AddReminder(
              user: widget.user,
            )),
          ).then((_) => refresh());
        },
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
        shape: const CircleBorder(eccentricity: 0),
        child: const Icon(
          Icons.add,
        ),
      ),
      body: RefreshIndicator(
        color: Colors.purple.shade400,
        onRefresh: refresh,
        child: SizedBox(
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: GetBuilder<ReminderController>(
              builder: (controller) {
                if (controller.data.isEmpty) {
                  return const Center(child: Text("No reminders found."));
                }

                return ListView.builder(
                  itemCount: reminderController.data.length,
                  itemBuilder: (context, index) {
                    var data = reminderController.data[index];
                    var slctd = data['selected'];
                    return ListTile(
                      key: ValueKey(data['id']),
                      onLongPress: () {
                        setState(() {
                          data['selected'] = !slctd;
                        });
                      },
                      onTap: () {
                        if (reminderController.data
                                .any((element) => element['selected']) &&
                            data['selected']) {
                          setState(() {
                            data['selected'] = false;
                          });
                        } else if (reminderController.data
                                .any((element) => element['selected']) &&
                            !data['selected']) {
                          setState(() {
                            data['selected'] = true;
                          });
                        } else {
                          Navigator.push(
                              context,
                              _goPage(
                                  EditReminder(data: data, user: widget.user)));
                        }
                      },
                      tileColor:
                          data['selected'] ? Colors.black12 : Colors.white,
                      title: Text(
                        formatTime(data['time']),
                        style: TextStyle(
                          color: data['active'] ? Colors.purple : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                      subtitle: Text(
                        data['event'],
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      trailing: Switch(
                        value: data['active'],
                        activeColor: Colors.purple,
                        onChanged: (value) {
                          changeStatus(data['id'], value, index);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> refresh() async {
    await getData();
  }

  Route _goPage(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      opaque: false,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOutExpo));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
