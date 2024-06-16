import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat/auth/auth.dart';
import 'package:chat/components/popup.dart';
import 'package:chat/controller/reminder_controller.dart';
import 'package:chat/home.dart';
import 'package:chat/setting.dart';
import 'package:chat/reminder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Layout extends StatefulWidget {
  const Layout({super.key, required this.user});
  final User? user;

  @override
  // ignore: library_private_types_in_public_api
  _LayoutState createState() => _LayoutState();
}

Route _goPage(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    opaque: false,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
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

class _LayoutState extends State<Layout> {
  final ReminderController reminderController = Get.put(ReminderController());
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;
  bool searchBar = false;
  List<Widget> page = [];
  final Battery _battery = Battery();
  bool _isPowerSaveMode = false;

  @override
  void initState() {
    super.initState();

    _requestPermissionsIfNeeded();
    _checkPowerSaveMode();
    page = [
      Reminder(user: widget.user),
      Home(user: widget.user),
    ];
  }

  Future<void> _checkPowerSaveMode() async {
    final isPowerSaveMode = await _battery.isInBatterySaveMode;
    setState(() {
      _isPowerSaveMode = isPowerSaveMode;
    });

    if (_isPowerSaveMode) {
      openDialog(
          // ignore: use_build_context_synchronously
          context,
          CupertinoAlertDialog(
            title: const Text("Peringatan"),
            content: const Text(
                "Reminder mungkin tidak dapat berjalan dengan semestinya jika mengaktifkan mode hemat daya, harap matikan mode hemat daya."),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Ok"),
              ),
            ],
          ));
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.speech.request();
    await Permission.notification.request();
    await Permission.ignoreBatteryOptimizations.request();
    await Permission.scheduleExactAlarm.request();
  }

  Future<void> _requestPermissionsIfNeeded() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var permissionRequested = prefs.getBool('permission_requested');

      if (permissionRequested == null) {
        await _requestPermissions();
        await prefs.setBool('permission_requested', true);
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  void _onPageChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("user_uid");

    Navigator.pushAndRemoveUntil(
      // ignore: use_build_context_synchronously
      context,
      _goPage(const Auth()),
      (route) => false,
    );

    // ignore: use_build_context_synchronously
    Popup().show(context, "Sign out Successfully", true);
  }

  void openDialog(BuildContext context, CupertinoAlertDialog dialog) {
    showCupertinoModalPopup(context: context, builder: (context) => dialog);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
        title: const Text(
          "Reminder",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Obx(() {
            bool hasSelected =
                reminderController.data.any((element) => element['selected']);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: hasSelected
                  ? TextButton(
                      onPressed: () {
                        openDialog(
                            context,
                            CupertinoAlertDialog(
                              title: const Text("Delete reminder"),
                              content: Text(
                                  "Are you sure to delete ${reminderController.data.where((e) => e['selected']).length} reminder?"),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text("No"),
                                ),
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () {
                                    reminderController.deleteData(
                                      context,
                                      reminderController.data
                                          .where((e) => e['selected'])
                                          .map((e) => e['id'])
                                          .toList(),
                                    );
                                  },
                                  child: const Text("Yes"),
                                ),
                              ],
                            ));
                      },
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : Wrap(
                      direction: Axis.horizontal,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              searchBar = !searchBar;
                            });
                          },
                          icon: const Icon(CupertinoIcons.search),
                        ),
                        MenuAnchor(
                          builder: (context, controller, child) {
                            return IconButton(
                              onPressed: () {
                                if (controller.isOpen) {
                                  controller.close();
                                } else {
                                  controller.open();
                                }
                              },
                              icon:
                                  const Icon(CupertinoIcons.ellipsis_vertical),
                            );
                          },
                          menuChildren: [
                            MenuItemButton(
                              onPressed: () {
                                Navigator.push(
                                    context, _goPage(const Setting()));
                              },
                              child: const Text("Setting"),
                            ),
                            MenuItemButton(
                              onPressed: () {
                                openDialog(
                                    context,
                                    CupertinoAlertDialog(
                                      title: const Text("Logout"),
                                      content: const Text(
                                          "Are you sure to logout now?"),
                                      actions: [
                                        CupertinoDialogAction(
                                          isDefaultAction: true,
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("No"),
                                        ),
                                        CupertinoDialogAction(
                                          isDefaultAction: true,
                                          onPressed: () {
                                            signOut();
                                          },
                                          child: const Text("Yes"),
                                        ),
                                      ],
                                    ));
                              },
                              child: const Text("Sign out"),
                            ),
                          ],
                        ),
                      ],
                    ),
            );
          })
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onItemTapped,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        backgroundColor: Colors.purple.shade400,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            label: "Reminder",
            activeIcon: Icon(CupertinoIcons.bell_fill),
            icon: Icon(CupertinoIcons.bell),
          ),
          BottomNavigationBarItem(
            label: "Chat",
            activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
            icon: Icon(CupertinoIcons.chat_bubble_2),
          ),
        ],
      ),
      body: PageView(
        physics: const BouncingScrollPhysics(),
        controller: _pageController,
        onPageChanged: _onPageChange,
        children: page,
      ),
    );
  }
}
