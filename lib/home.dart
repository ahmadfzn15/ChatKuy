import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sioren/chat.dart';
import 'package:sioren/friend.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.user});
  final User? user;

  @override
  _HomeState createState() => _HomeState();
}

Route _goPage(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
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
        .orderBy("updated_at", descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>> getUser(Map<String, dynamic> chatRoom) async {
    List<dynamic> participants = chatRoom['participants'];
    for (String userId in participants) {
      if (userId != widget.user!.uid) {
        QuerySnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where("uid", isEqualTo: userId)
            .get();

        return userDoc.docs.first.data() as Map<String, dynamic>;
      }
    }
    return {};
  }

  Future<Map<String, dynamic>> getMessage(chatRoom) async {
    QuerySnapshot messageDoc = await FirebaseFirestore.instance
        .collection('message')
        .where("room_id", isEqualTo: chatRoom['id'])
        .orderBy("created_at", descending: true)
        .get();

    if (messageDoc.docs.isNotEmpty) {
      return messageDoc.docs.first.data() as Map<String, dynamic>;
    } else {
      return {"message": "No message available"};
    }
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
        shape: const CircleBorder(),
        child: const Icon(
          CupertinoIcons.chat_bubble_text_fill,
        ),
      ),
      body: RefreshIndicator(
        color: Colors.purple.shade400,
        onRefresh: refresh,
        child: SizedBox(
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: StreamBuilder<QuerySnapshot>(
              stream: dataSnapshot,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Chat kamu masih kosong nih"),
                  );
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var chatRoom = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                      var chatId = snapshot.data!.docs[index].id;
                      chatRoom = {...chatRoom, "selected": false, "id": chatId};

                      return FutureBuilder<Map<String, dynamic>>(
                        future: Future.wait(
                                [getUser(chatRoom), getMessage(chatRoom)])
                            .then((List<dynamic> value) {
                          return value.asMap().map((index, data) {
                            return MapEntry(
                                index == 0 ? 'user' : 'message', data);
                          });
                        }),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.hasError) {
                            return Container();
                          }

                          var user = snapshot.data!['user']!;
                          var message = snapshot.data!['message']!;

                          return ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                _goPage(Chat(
                                  id: chatId,
                                  userId: user['uid'],
                                  user: widget.user,
                                )),
                              );
                            },
                            title: Text(user['name'] ?? "Unknown User"),
                            subtitle: Text(message['message'] ?? "No Message"),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            leading: GestureDetector(
                              onTap: () {},
                              child: const CircleAvatar(
                                radius: 30,
                                backgroundImage:
                                    AssetImage("assets/img/lusi.jpeg"),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
