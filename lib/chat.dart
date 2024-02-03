import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _inputMessage = TextEditingController();
  List<String> message = [];

  void sendMessage() {
    if (_inputMessage.text != "") {
      message.add(_inputMessage.text);
    }
  }

  XFile? _image;

  void _openFileManager() async {
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      XFile? pickImg =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      setState(() {
        _image = pickImg;
      });
    } else {
      // ignore: use_build_context_synchronously
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoAlertDialog(
            title: const Text("Access denied"),
            content: const Text("Please allow storage usage to upload images."),
            actions: [
              CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Ok"))
            ]),
      );
    }
  }

  void _openCamera() async {
    PermissionStatus status = await Permission.camera.request();

    if (status.isGranted) {
      XFile? pickImg =
          await ImagePicker().pickImage(source: ImageSource.camera);
      setState(() {
        _image = pickImg;
      });
    } else {
      // ignore: use_build_context_synchronously
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoAlertDialog(
            title: const Text("Access denied"),
            content: const Text("Please allow camera to upload images."),
            actions: [
              CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Ok"))
            ]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: PopupMenuButton(
                icon: const Icon(Icons.menu),
                itemBuilder: (context) {
                  return [const PopupMenuItem(child: Text("Clear Chat"))];
                },
              ),
            )
          ],
          elevation: 1,
          surfaceTintColor: Colors.white,
          shadowColor: Colors.black,
          leadingWidth: 500,
          leading: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.chevron_left_rounded),
                CircleAvatar(
                  backgroundImage: AssetImage("/img/lusi.jpeg"),
                ),
                SizedBox(
                  width: 10,
                ),
                Text("Lusi Kuraisin")
              ],
            ),
          )),
      body: const SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(5.0),
                child: Text("Hello"),
              ),
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(5.0),
                child: Text("Hello"),
              ),
            )
          ]),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
          elevation: 15,
          shadowColor: Colors.black,
          height: 75,
          surfaceTintColor: Colors.white,
          child: TextField(
            controller: _inputMessage,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10),
                hintText: "Type here...",
                suffixIcon: GestureDetector(
                    onTap: sendMessage, child: const Icon(Icons.send)),
                icon: PopupMenuButton(
                  offset: const Offset(0, -100),
                  icon: const Icon(Icons.photo),
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                          onTap: _openFileManager,
                          child: const Text("Pick Images")),
                      PopupMenuItem(
                          onTap: _openCamera, child: const Text("Open Camera"))
                    ];
                  },
                ),
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)))),
          )),
    );
  }
}
