import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sioren/auth/auth.dart';
import 'package:sioren/components/popup.dart';
import 'package:sioren/group.dart';
import 'package:sioren/home.dart';
import 'package:sioren/setting.dart';
import 'package:sioren/story.dart';

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
  int _currentIndex = 1;
  bool searchBar = false;
  final PageController _pageController = PageController(initialPage: 1);
  List<Widget> page = [];

  @override
  initState() {
    super.initState();

    page = [
      Story(user: widget.user),
      Home(user: widget.user),
      Group(user: widget.user)
    ];
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
    await const FlutterSecureStorage().delete(key: "token");

    Navigator.pushAndRemoveUntil(
      // ignore: use_build_context_synchronously
      context,
      _goPage(const Auth()),
      (route) => false,
    );

    // ignore: use_build_context_synchronously
    Popup().show(context, "Sign out Successfully", true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
        title: const Text(
          "ChatKuy",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                direction: Axis.horizontal,
                children: [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          searchBar = !searchBar;
                        });
                      },
                      icon: const Icon(CupertinoIcons.search)),
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
                          icon: const Icon(CupertinoIcons.ellipsis_vertical),
                        );
                      },
                      menuChildren: [
                        MenuItemButton(
                            onPressed: () {
                              Navigator.push(context, _goPage(const Setting()));
                            },
                            child: const Text("Setting")),
                        MenuItemButton(
                            onPressed: () {
                              signOut();
                            },
                            child: const Text("Sign out")),
                      ]),
                ],
              ))
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
                label: "Story",
                activeIcon: Icon(CupertinoIcons.book_fill),
                icon: Icon(CupertinoIcons.book)),
            BottomNavigationBarItem(
                label: "Chat",
                activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
                icon: Icon(CupertinoIcons.chat_bubble_2)),
            BottomNavigationBarItem(
                label: "Group",
                activeIcon: Icon(Icons.group),
                icon: Icon(Icons.group_outlined)),
          ]),
      body: PageView(
        physics: const BouncingScrollPhysics(),
        controller: _pageController,
        onPageChanged: _onPageChange,
        children: page,
      ),
    );
  }
}