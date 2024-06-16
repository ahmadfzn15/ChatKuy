import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chat/components/popup.dart';

class Register extends StatefulWidget {
  const Register({super.key, required this.pageController});
  final PageController pageController;

  @override
  // ignore: library_private_types_in_public_api
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordControllerConfirmation =
      TextEditingController();
  bool loading = false;
  bool pwdNotSame = false;
  bool showPwd = false;
  bool showPwdConf = false;

  void _registerUser(BuildContext context) async {
    try {
      loading = true;
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.value.text,
        password: _passwordController.value.text,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.value.text.trim(),
        password: _passwordController.value.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').add({
        "uid": userCredential.user!.uid,
        "photo": null,
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "telephone_number": null,
        "bio": null,
        "created_at": Timestamp.now()
      });

      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        setState(() {
          _emailController.clear();
          _passwordController.clear();
          _passwordControllerConfirmation.clear();
        });

        user.sendEmailVerification();

        Popup()
            // ignore: use_build_context_synchronously
            .show(context, "Email verification has been sent to your email",
                true);
        loading = false;

        widget.pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutExpo);
      } else {
        setState(() {
          _emailController.clear();
        });
        loading = false;
        // ignore: use_build_context_synchronously
        Popup().show(context, "Sign up failed", false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _emailController.clear();
      });
      loading = false;
      // ignore: use_build_context_synchronously
      Popup().show(context, e.message!, false);
    } catch (e) {
      setState(() {
        _emailController.clear();
      });
      loading = false;
      // ignore: use_build_context_synchronously
      Popup().show(context, "An unexpected error occurred", false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome",
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Name",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    CupertinoTextField(
                      controller: _nameController,
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Icon(Icons.person),
                      ),
                      placeholder: "Enter your name",
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF94a3b8), width: 0.5),
                      ),
                    ),
                    const SizedBox(height: 15),
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
                      controller: _emailController,
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Icon(Icons.email),
                      ),
                      placeholder: "Enter your email",
                      keyboardType: TextInputType.emailAddress,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF94a3b8), width: 0.5),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Password",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    CupertinoTextField(
                      controller: _passwordController,
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Icon(Icons.lock),
                      ),
                      obscuringCharacter: "*",
                      onChanged: (value) {
                        if (_passwordControllerConfirmation.text.isNotEmpty) {
                          if (value != _passwordControllerConfirmation.text) {
                            setState(() {
                              pwdNotSame = true;
                            });
                          } else {
                            setState(() {
                              pwdNotSame = false;
                            });
                          }
                        }
                      },
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                            onTap: () {
                              setState(() {
                                showPwd = !showPwd;
                              });
                            },
                            child: showPwd
                                ? const Icon(CupertinoIcons.eye_fill)
                                : const Icon(CupertinoIcons.eye_slash_fill)),
                      ),
                      placeholder: "Enter your password",
                      obscureText: !showPwd,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF94a3b8), width: 0.5),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Repeat Password",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    CupertinoTextField(
                      controller: _passwordControllerConfirmation,
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Icon(Icons.lock),
                      ),
                      obscuringCharacter: "*",
                      onChanged: (value) {
                        if (_passwordController.text.isNotEmpty) {
                          if (value != _passwordController.text) {
                            setState(() {
                              pwdNotSame = true;
                            });
                          } else {
                            setState(() {
                              pwdNotSame = false;
                            });
                          }
                        }
                      },
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                            onTap: () {
                              setState(() {
                                showPwdConf = !showPwdConf;
                              });
                            },
                            child: showPwdConf
                                ? const Icon(CupertinoIcons.eye_fill)
                                : const Icon(CupertinoIcons.eye_slash_fill)),
                      ),
                      placeholder: "Enter again your password",
                      obscureText: !showPwdConf,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF94a3b8), width: 0.5),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        pwdNotSame
                            ? const Text(
                                "Password is't the same",
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.start,
                              )
                            : const Text("")
                      ],
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: CupertinoButton(
                          onPressed: () => !loading && !pwdNotSame
                              ? _registerUser(context)
                              : null,
                          color: Colors.purple.shade400,
                          child: const Text("Sign up",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        )),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already account? ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () {
                            widget.pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutExpo);
                          },
                          child: const Text(
                            "Sign in",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
