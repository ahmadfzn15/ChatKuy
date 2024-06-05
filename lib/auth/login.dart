import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chat/auth/forgot_password.dart';
import 'package:chat/components/popup.dart';
import 'package:chat/layout.dart';

class Login extends StatefulWidget {
  const Login({super.key, required this.pageController});
  final PageController pageController;

  @override
  // ignore: library_private_types_in_public_api
  _LoginState createState() => _LoginState();
}

Route _goPage(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 500),
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

class _LoginState extends State<Login> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  bool loading = false;
  bool showPwd = false;

  void _loginUser(BuildContext context) async {
    try {
      setState(() {
        loading = true;
      });

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        User user = userCredential.user!;
        await user.reload();
        if (user.emailVerified) {
          final String? token = await user.getIdToken();
          await storage.write(key: "token", value: token);
          saveTokenToDatabase(user.uid);

          Navigator.pushAndRemoveUntil(
            // ignore: use_build_context_synchronously
            context,
            _goPage(Layout(user: user)),
            (route) => false,
          );

          // ignore: use_build_context_synchronously
          Popup().show(context, "Sign in successfully", true);

          setState(() {
            _emailController.clear();
            _passwordController.clear();
            loading = false;
          });
        } else {
          setState(() {
            loading = false;
          });
          // ignore: use_build_context_synchronously
          _showEmailVerificationDialog(context, user);
        }
      } else {
        setState(() {
          _passwordController.clear();
          loading = false;
        });
        // ignore: use_build_context_synchronously
        Popup().show(context, "Sign in failed", false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _passwordController.clear();
        loading = false;
      });
      // ignore: use_build_context_synchronously
      Popup().show(context, e.message!, false);
    } catch (e) {
      setState(() {
        _passwordController.clear();
        loading = false;
      });
      // ignore: use_build_context_synchronously
      Popup().show(context, "An unexpected error occurred", false);
    }
  }

  Future<void> _showEmailVerificationDialog(
      BuildContext context, User user) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Email not verified"),
          content: const Text("Please verify your email to continue."),
          actions: [
            TextButton(
              onPressed: () async {
                await user.sendEmailVerification();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              },
              child: const Text("Resend Verification Email"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveTokenToDatabase(String userId) async {
    String? token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      var tokensRef = await FirebaseFirestore.instance
          .collection('users')
          .where("uid", isEqualTo: userId)
          .get();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(tokensRef.docs.first.id)
          .update({
        'fcmToken': FieldValue.arrayUnion([token]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back",
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
                    keyboardType: TextInputType.emailAddress,
                    placeholder: "Enter your email",
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
                    obscuringCharacter: "*",
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context, _goPage(const ForgotPassword()));
                        },
                        child: const Text(
                          "Forgot password?",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CupertinoButton(
                        onPressed: () => loading ? null : {_loginUser(context)},
                        color: Colors.purple.shade400,
                        child: const Text("Sign in",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      )),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutExpo);
                        },
                        child: const Text(
                          "Sign up",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
