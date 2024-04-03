import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sioren/chat.dart';
import 'package:sioren/friend.dart';
import 'package:sioren/model/selection.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.user});
  final User? user;

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
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

class _HomeState extends State<Home> {
  bool loading = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? dataSnapshot;

  @override
  void initState() {
    super.initState();

    dataSnapshot = FirebaseFirestore.instance
        .collection('chatRoom')
        .where("participants", arrayContains: widget.user!.uid)
        .where("active", isEqualTo: true)
        .snapshots();

    getData();
  }

  Future<void> getData() async {
    setState(() {
      loading = true;
    });
  }

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
          CupertinoIcons.chat_bubble_text_fill,
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: StreamBuilder(
                stream: dataSnapshot,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.purple.shade400,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text("Error : ${snapshot.error}"),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      List<Map<String, dynamic>> data = snapshot.data!.docs
                          .map((e) => {"selected": false, ...e.data()})
                          .toList();
                      return ListTile(
                        onTap: () {
                          if (data[index]['selected']) {
                            setState(() {
                              data[index]['selected'] = false;
                            });
                          } else if (snapshot.data!.docs
                                  .any((element) => element['selected']) ||
                              Provider.of<Selection>(context).isSelected) {
                            setState(() {
                              data[index]['selected'] = true;
                            });
                          } else {
                            // Navigator.push(context, _goPage(const Chat()));
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            data[index]['selected'] = true;
                          });
                          final selectionModel =
                              Provider.of<Selection>(context, listen: false);
                          selectionModel.setSelected(true);
                        },
                        selected: data[index]['selected'] &&
                            Provider.of<Selection>(context).isSelected,
                        selectedTileColor: Colors.black12,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        title: Text(data[index]['participants'][0]),
                        leading: GestureDetector(
                          onTap: () {},
                          child: const CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage("assets/img/lusi.jpeg"),
                          ),
                        ),
                        // title: Text(data['name']),
                        // subtitle: Text(data['message']),
                      );
                    },
                  );
                },
              ),
            ),
          )),
    );
  }
}
