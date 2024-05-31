import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sioren/components/popup.dart';
import 'package:sioren/controller/reminder_controller.dart';

class AddReminder extends StatefulWidget {
  const AddReminder({super.key, required this.user});
  final User? user;

  @override
  // ignore: library_private_types_in_public_api
  _AddReminderState createState() => _AddReminderState();
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

class _AddReminderState extends State<AddReminder> {
  final reminderController = Get.put(ReminderController());
  TimeOfDay? selectedTime;
  final TextEditingController _event = TextEditingController();
  final TextEditingController _reminderMessage = TextEditingController();
  final TextEditingController _stopMessage = TextEditingController();
  DateTime time = DateTime.now();

  @override
  void initState() {
    super.initState();

    _selectTime(context);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: child,
        ),
      ),
    );
  }

  Future<void> addReminder() async {
    await reminderController.addData(context, {
      "event": _event.text,
      "time": time,
      "reminder_message": _reminderMessage.text,
      "stop_message": _stopMessage.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.close_rounded,
              size: 30,
            )),
        centerTitle: true,
        title: const Text(
          "Add Reminder",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
              onPressed: () {
                addReminder();
              },
              icon: const Icon(
                Icons.check,
                size: 30,
              ))
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("New Reminder",
                        style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Event name",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(
                  height: 6,
                ),
                CupertinoTextField(
                  controller: _event,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(Icons.event),
                  ),
                  placeholder: "Enter your event",
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFcbd5e1), width: 0.5),
                  ),
                ),
                ListTile(
                  onTap: () => _showDialog(
                    CupertinoDatePicker(
                      initialDateTime: time,
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      onDateTimeChanged: (DateTime newTime) {
                        setState(() => time = newTime);
                      },
                    ),
                  ),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: const Text("Time",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  trailing: Text("${time.hour}:${time.minute}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.purple)),
                ),
                const Divider(
                  thickness: 0.5,
                ),
                ListTile(
                  onTap: () => _showDialog(Material(
                    child: ListView(
                      children: [
                        SwitchListTile(
                          value: true,
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          title: const Text("Every Day"),
                          activeColor: Colors.purple,
                          onChanged: (value) {
                            setState(() {
                              // allowVarian = value;
                            });
                          },
                        ),
                        CheckboxListTile(
                          value: true,
                          onChanged: (value) {},
                          title: const Text("Monday"),
                        ),
                        CheckboxListTile(
                          value: true,
                          onChanged: (value) {},
                          title: const Text("Tuesday"),
                        ),
                        CheckboxListTile(
                          value: true,
                          onChanged: (value) {},
                          title: const Text("Wednesday"),
                        ),
                        CheckboxListTile(
                          value: true,
                          onChanged: (value) {},
                          title: const Text("Thursday"),
                        ),
                        CheckboxListTile(
                          value: true,
                          onChanged: (value) {},
                          title: const Text("Friday"),
                        ),
                        CheckboxListTile(
                          value: true,
                          onChanged: (value) {},
                          title: const Text("Saturday"),
                        ),
                        CheckboxListTile(
                          value: true,
                          onChanged: (value) {},
                          title: const Text("Sunday"),
                        )
                      ],
                    ),
                  )),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: const Text("Repeat",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  trailing: const Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    direction: Axis.horizontal,
                    children: [
                      Text("Never",
                          style: TextStyle(fontSize: 15, color: Colors.grey)),
                      Icon(
                        Icons.chevron_right,
                        size: 30,
                      )
                    ],
                  ),
                ),
                const Divider(
                  thickness: 0.5,
                ),
                const SizedBox(
                  height: 10,
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Reminder Message",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(
                  height: 6,
                ),
                CupertinoTextField(
                  controller: _reminderMessage,
                  // prefix: const Padding(
                  //   padding: EdgeInsets.only(left: 10),
                  //   child: Icon(Icons.alarm),
                  // ),
                  placeholder: "Enter reminder message",
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFcbd5e1), width: 0.5),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Stop Message",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(
                  height: 6,
                ),
                CupertinoTextField(
                  controller: _stopMessage,
                  // prefix: const Padding(
                  //   padding: EdgeInsets.only(left: 10),
                  //   child: Icon(Icons.alarm),
                  // ),
                  placeholder: "Enter stop message",
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFcbd5e1), width: 0.5),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
