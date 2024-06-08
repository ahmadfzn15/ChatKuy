import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat/components/popup.dart';
import 'package:chat/controller/reminder_controller.dart';

class EditReminder extends StatefulWidget {
  const EditReminder({super.key, required this.data, required this.user});
  final User? user;
  final Map<String, dynamic> data;

  @override
  // ignore: library_private_types_in_public_api
  _EditReminderState createState() => _EditReminderState();
}

class _EditReminderState extends State<EditReminder> {
  final reminderController = Get.put(ReminderController());
  TimeOfDay? selectedTime;
  String? id;
  final TextEditingController _event = TextEditingController();
  final TextEditingController _reminderMessage = TextEditingController();
  final TextEditingController _stopMessage = TextEditingController();
  DateTime time = DateTime.now();
  bool allDay = false;
  List<Map<String, dynamic>> days = [
    {"selected": false, "id": 1, "day": "Monday"},
    {"selected": false, "id": 2, "day": "Tuesday"},
    {"selected": false, "id": 3, "day": "Wednesday"},
    {"selected": false, "id": 4, "day": "Thursday"},
    {"selected": false, "id": 5, "day": "Friday"},
    {"selected": false, "id": 6, "day": "Saturday"},
    {"selected": false, "id": 7, "day": "Sunday"},
  ];

  @override
  void initState() {
    super.initState();

    id = widget.data['id'];
    _event.value = TextEditingValue(text: widget.data['event']);
    _reminderMessage.value =
        TextEditingValue(text: widget.data['reminder_message']);
    _stopMessage.value = TextEditingValue(text: widget.data['stop_message']);
    time = DateTime.fromMillisecondsSinceEpoch(
        widget.data['time'].seconds * 1000 +
            widget.data['time'].nanoseconds ~/ 1000000);

    List<dynamic> repeat = widget.data['repeat'];
    for (var element in days) {
      if (repeat.contains(element['id'])) {
        element['selected'] = true;
      }
    }
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

  Future<void> editReminder() async {
    if (_event.text.isNotEmpty &&
        _reminderMessage.text.isNotEmpty &&
        _stopMessage.text.isNotEmpty) {
      var now = DateTime.now();
      time = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime?.hour ?? time.hour,
        selectedTime?.minute ?? time.minute,
      );

      // ignore: use_build_context_synchronously
      await reminderController.editData(context, {
        "id": id,
        "event": _event.text,
        "time": time,
        "repeat": days
            .where((element) => element['selected'])
            .map((e) => e['id'])
            .toList(),
        "reminder_message": _reminderMessage.text,
        "stop_message": _stopMessage.text,
      });
    } else {
      // ignore: use_build_context_synchronously
      Popup().show(context, "Please fill in all fields", false);
    }
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
          "Edit Reminder",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
              onPressed: () {
                editReminder();
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
                  onTap: () => _selectTime(context),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: const Text("Time",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  trailing: Text(
                      selectedTime != null
                          ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
                          : "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.purple)),
                ),
                const Divider(
                  thickness: 0.5,
                ),
                ListTile(
                  onTap: () => _showDialog(StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Material(
                        child: ListView(
                          children: [
                            SwitchListTile(
                              value:
                                  days.every((element) => element['selected']),
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              title: const Text("Every Day"),
                              activeColor: Colors.purple,
                              onChanged: (value) {
                                setState(() {
                                  allDay = value;
                                  if (value) {
                                    for (var element in days) {
                                      element['selected'] = true;
                                    }
                                  } else {
                                    for (var element in days) {
                                      element['selected'] = false;
                                    }
                                  }
                                });
                              },
                            ),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                itemCount: days.length,
                                itemBuilder: (context, index) {
                                  return CheckboxListTile(
                                    value: days[index]['selected'],
                                    onChanged: (value) {
                                      setState(() {
                                        days[index]['selected'] = value;
                                        if (!days.every(
                                            (element) => element['selected'])) {
                                          allDay = false;
                                        } else {
                                          allDay = true;
                                        }
                                      });
                                    },
                                    title: Text(days[index]['day']),
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                      );
                    },
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
