import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _email = TextEditingController();

  Future<void> sendEmail() async {
    // if (res.statusCode == 200) {
    //   // ignore: use_build_context_synchronously
    //   Navigator.pop(context);
    //   // ignore: use_build_context_synchronously
    //   Popup().show(context, result['message'], true);
    // } else {
    //   print(result['message']);
    //   // ignore: use_build_context_synchronously
    //   Popup().show(context, result['message'], false);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        shadowColor: Colors.grey,
        elevation: 1,
        title: const Text(
          "Forgot Password",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.close,
            )),
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Form(
                child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Email",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(
                  height: 6,
                ),
                CupertinoTextField(
                  controller: _email,
                  placeholder: "Enter your email",
                  keyboardType: TextInputType.emailAddress,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(Icons.email),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFcbd5e1), width: 0.5),
                  ),
                ),
              ],
            ))),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: CupertinoButton(
              color: Colors.purple,
              onPressed: () {
                sendEmail();
              },
              child: const Text("Send")),
        ),
      ),
    );
  }
}
