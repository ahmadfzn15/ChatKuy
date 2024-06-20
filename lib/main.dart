import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat/auth/auth.dart';
import 'package:chat/layout.dart';
import 'package:chat/etc/startup.dart';
import 'package:chat/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeFirebase();

  runApp(const MainApp());
}

Future<void> initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
        // ignore: avoid_print
      ).whenComplete(() => print('Firebase initialized successfully'));
    } else {
      // ignore: avoid_print
      print('Firebase already initialized');
    }
  } catch (e) {
    // ignore: avoid_print
    print('Failed to initialize Firebase: $e');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Reminder",
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: const MainAppScreen(),
    );
  }
}

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen>
    with WidgetsBindingObserver {
  ThemeMode themeMode = ThemeMode.system;

  Future<void> saveUserUID(String uid) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("user_uid", uid);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkToken(),
      builder: (context, tokenSnapshot) {
        if (tokenSnapshot.connectionState == ConnectionState.done) {
          if (tokenSnapshot.hasError) {
            // ignore: avoid_print
            print('Error during auth state changes');
            return const Auth();
          }
          if (tokenSnapshot.data == true) {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  return const Startup();
                } else {
                  if (authSnapshot.hasError) {
                    // ignore: avoid_print
                    print(
                        'Error during auth state changes: ${authSnapshot.error}');
                    return const Auth();
                  }
                  if (authSnapshot.data != null) {
                    saveUserUID(authSnapshot.data!.uid);
                    return Layout(user: authSnapshot.data!);
                  } else {
                    return const Auth();
                  }
                }
              },
            );
          } else {
            return const Auth();
          }
        } else {
          return const Startup();
        }
      },
    );
  }
}

Future<bool> checkToken() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var containsKey = prefs.containsKey('token');
    return containsKey;
  } catch (e) {
    // ignore: avoid_print
    print('Error checking token: $e');
    return false;
  }
}
