import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sioren/chat.dart';
import 'package:sioren/model/friend_model.dart';

class Friend extends StatefulWidget {
  const Friend({super.key, required this.user});
  final User? user;

  @override
  // ignore: library_private_types_in_public_api
  _FriendState createState() => _FriendState();
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

class _FriendState extends State<Friend> {
  final TextEditingController _search = TextEditingController();
  List<FriendModel> friend = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();

    getData();
  }

  Future<void> getData() async {
    setState(() {
      loading = true;
    });

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isNotEqualTo: widget.user!.uid)
        .get();

    setState(() {
      friend.clear();
      friend.addAll(querySnapshot.docs
          .map((doc) => FriendModel.fromJson(
              {if (doc.data() != null) ...doc.data() as Map<String, dynamic>}))
          .toList());

      loading = false;
    });
  }

  Future<void> searchFriend(String value) async {
    setState(() {
      loading = true;
    });

    String searchValue = value.toLowerCase();

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: widget.user!.uid)
          .where("name", isGreaterThanOrEqualTo: searchValue)
          .where("name", isLessThanOrEqualTo: "$searchValue\uf8ff")
          .get();

      setState(() {
        friend.clear();
        friend.addAll(querySnapshot.docs.map((doc) {
          return FriendModel.fromJson(doc.data() as Map<String, dynamic>);
        }).toList());
      });
    } catch (e) {
      print("Error fetching friends: $e");
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> goToChat(String id) async {
    final checkRoom = await FirebaseFirestore.instance
        .collection('chatRoom')
        .where("participants", arrayContains: widget.user!.uid)
        .get();

    final filterRoom = checkRoom.docs.where((element) {
      List participants = element['participants'];
      return participants.contains(id);
    }).toList();

    if (filterRoom.isNotEmpty) {
      Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          _goPage(
              Chat(id: filterRoom.first.id, userId: id, user: widget.user)));
    } else {
      var res = await FirebaseFirestore.instance.collection('chatRoom').add({
        "participants": [widget.user!.uid, id],
        "active": false,
        "reader": [],
        "pinned_id": [],
        "deleted_id": [],
        "updated_at": null,
        "created_at": Timestamp.now()
      });

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          _goPage(Chat(
            id: res.id,
            userId: id,
            user: widget.user,
          )));
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
              size: 40,
            )),
        title: const Text(
          "Your Friend",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: SizedBox(
            child: Wrap(
              alignment: WrapAlignment.start,
              children: [
                CupertinoTextField(
                  controller: _search,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(Icons.search),
                  ),
                  placeholder: "Search another friend . . .",
                  onChanged: (value) {
                    searchFriend(value);
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border:
                        Border.all(color: const Color(0xFF94a3b8), width: 0.5),
                  ),
                ),
                !loading
                    ? ListView.builder(
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: friend.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return ListTile(
                            onTap: () {
                              goToChat(friend[index].uid);
                            },
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 0),
                            leading: GestureDetector(
                              onTap: () {},
                              child: const CircleAvatar(
                                backgroundImage:
                                    AssetImage('assets/img/lusi.jpeg'),
                              ),
                            ),
                            title: Text(friend[index].name),
                          );
                        },
                      )
                    // : const Padding(
                    //     padding: EdgeInsets.all(20),
                    //     child: Center(
                    //       child: Text("Friend empty"),
                    //     ),
                    //   )
                    : Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.purple.shade400,
                          ),
                        ),
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
