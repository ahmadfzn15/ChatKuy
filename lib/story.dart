import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Story extends StatefulWidget {
  const Story({super.key, required this.user});
  final User? user;

  @override
  // ignore: library_private_types_in_public_api
  _StoryState createState() => _StoryState();
}

class _StoryState extends State<Story> {
  Future<void> refresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: RefreshIndicator(
      color: Colors.orange,
      onRefresh: () {
        return refresh();
      },
      child: const SizedBox(
        height: double.infinity,
        child: Center(
          child: Text("Hello"),
        ),
      ),
    ));
  }
}
