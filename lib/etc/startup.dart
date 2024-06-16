import 'package:flutter/material.dart';

class Startup extends StatelessWidget {
  const Startup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.purple,
      child: Center(
        child: SizedBox(
          width: 300,
          height: 150,
          child: Image.asset("assets/img/logo.png"),
        ),
      ),
    );
  }
}
