import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat/friend.dart';

class Group extends StatefulWidget {
  const Group({super.key, required this.user});
  final User? user;

  @override
  // ignore: library_private_types_in_public_api
  _GroupState createState() => _GroupState();
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

class _GroupState extends State<Group> {
  List<dynamic> data = [
    {
      "foto": "assets/img/lusi.jpeg",
      "name": "Lusi Kuraisin",
      "message": "Ppp",
      "selected": false
    },
  ];
  bool _select = false;

  Future<void> refresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              _goPage(Friend(
                user: widget.user,
              )));
        },
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
        shape: const CircleBorder(eccentricity: 0),
        child: const Icon(
          Icons.group_add_rounded,
        ),
      ),
      body: RefreshIndicator(
          color: Colors.purple.shade400,
          onRefresh: () {
            return refresh();
          },
          child: SizedBox(
            height: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: ListView.builder(
                itemCount: data.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      if (data[index]['selected']) {
                        setState(() {
                          data[index]['selected'] = false;
                        });
                      } else if (data.any((element) => element['selected'])) {
                        setState(() {
                          data[index]['selected'] = true;
                        });
                      } else {
                        // Navigator.push(context, _goPage(const Chat()));
                      }
                    },
                    onLongPress: () {
                      setState(() {
                        _select = true;
                        data[index]['selected'] = true;
                      });
                    },
                    selected: data[index]['selected'],
                    selectedTileColor: Colors.black12,
                    leading: GestureDetector(
                      onTap: () {},
                      child: CircleAvatar(
                        backgroundImage: AssetImage(data[index]['foto']),
                      ),
                    ),
                    title: Text(data[index]['name']),
                    subtitle: Text(data[index]['message']),
                  );
                },
              ),
            ),
          )),
    );
  }
}
