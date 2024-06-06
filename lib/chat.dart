import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chat/etc/format_time.dart';
import 'package:chat/etc/messaging.dart';

class Chat extends StatefulWidget {
  const Chat(
      {super.key, required this.id, required this.userId, required this.user});
  final String id;
  final String userId;
  final User? user;

  @override
  // ignore: library_private_types_in_public_api
  _ChatState createState() => _ChatState();
}

Route _goPage(Widget widget) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => widget,
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

class _ChatState extends State<Chat> {
  final TextEditingController _message = TextEditingController();
  Map<String, dynamic>? user;
  bool loading = true;
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();

    getData();
    fetchMessages();
  }

  Future<void> getData() async {
    try {
      QuerySnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where("uid", isEqualTo: widget.userId)
          .get();
      var data = userDoc.docs.first.data() as Map<String, dynamic>;

      setState(() {
        user = null;
        user = data;
        loading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error getting user data: $e');
    }
  }

  void fetchMessages() {
    FirebaseFirestore.instance
        .collection('message')
        .where("room_id", isEqualTo: widget.id)
        .orderBy('created_at')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        messages = snapshot.docs.map((doc) => doc.data()).toList();
        loading = false;
      });
    });
  }

  Future<void> updateStatusRoom() async {
    if (messages.length == 1) {
      await FirebaseFirestore.instance
          .collection('chatRoom')
          .doc(widget.id)
          .update({"active": true});
    }

    await FirebaseFirestore.instance
        .collection('chatRoom')
        .doc(widget.id)
        .update({"updated_at": Timestamp.now()});
  }

  Future<void> sendMessage() async {
    if (_message.text != "") {
      await FirebaseFirestore.instance.collection("message").add({
        "room_id": widget.id,
        "sender_id": widget.user!.uid,
        "receipent_id": widget.userId,
        "message": _message.text,
        "readed": false,
        "deleted_id": [],
        "created_at": Timestamp.now()
      }).then((value) async {
        _message.clear();
        fetchMessages();
        await updateStatusRoom();

        await Messaging().sendNotif(
            "dK5A7R4cSKa08MtHIf45LI:APA91bHtTPx2cxO9rIWauTTVRvUvm_Uaa-Df8byKnVejA6TRx_LrW7sx3b0Usnr3tp-2YGlG0Lk0FDRVtQw-ypvZLN_p61XG1oF-txZTxu3Mn90nn7IZj6sP5P-UUFT2mnrp4p4vYV9k",
            "Ahmad Fauzan",
            _message.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey,
        surfaceTintColor: Colors.white,
        title: TextButton(
            onPressed: () {},
            style: const ButtonStyle(
                padding: MaterialStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 0, vertical: 10),
            )),
            child: Text(
              user != null ? user!['name'] : "",
              style: const TextStyle(fontSize: 18, color: Colors.white),
            )),
        titleSpacing: 0,
        leadingWidth: 95,
        leading: Padding(
          padding: const EdgeInsets.all(4),
          child: TextButton(
              style: const ButtonStyle(
                  padding: MaterialStatePropertyAll(EdgeInsets.zero)),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Row(
                children: [
                  Icon(
                    Icons.chevron_left,
                    size: 40,
                    color: Colors.white,
                  ),
                  CircleAvatar(
                    backgroundImage: AssetImage("assets/img/user.png"),
                  )
                ],
              )),
        ),
        actions: [
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
              menuChildren: const [])
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.purple,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: messages.length,
                    padding: const EdgeInsets.all(10),
                    itemBuilder: (context, index) {
                      return Row(
                        mainAxisAlignment:
                            messages[index]['sender_id'] == widget.userId
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.end,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.8),
                            child: Card(
                              elevation: 1,
                              color: Colors.white,
                              surfaceTintColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                    topLeft: messages[index]['sender_id'] ==
                                            widget.userId
                                        ? Radius.zero
                                        : const Radius.circular(15),
                                    topRight: messages[index]['sender_id'] !=
                                            widget.userId
                                        ? Radius.zero
                                        : const Radius.circular(15),
                                    bottomLeft: const Radius.circular(15),
                                    bottomRight: const Radius.circular(15)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(7),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(messages[index]['message'],
                                        style: const TextStyle(
                                            fontSize: 16,
                                            overflow: TextOverflow.clip)),
                                    Text(
                                        formatTime(
                                            messages[index]['created_at']),
                                        style: const TextStyle(
                                            fontSize: 10,
                                            overflow: TextOverflow.clip)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
          ),
          Container(
            padding:
                const EdgeInsets.only(bottom: 10, left: 10, right: 10, top: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                        color: Colors.purple.shade400,
                        icon: const Icon(
                          Icons.photo,
                        ),
                      );
                    },
                    menuChildren: const [
                      MenuItemButton(child: Text("Gambar"))
                    ]),
                Expanded(
                    child: CupertinoTextField(
                  controller: _message,
                  keyboardType: TextInputType.emailAddress,
                  placeholder: "Type here . . .",
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border:
                        Border.all(color: const Color(0xFF94a3b8), width: 0.5),
                  ),
                )),
                IconButton(
                    onPressed: () {
                      sendMessage();
                    },
                    color: Colors.purple.shade400,
                    icon: const Icon(Icons.send))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
