import 'package:chat/components/loading.dart';
import 'package:chat/etc/alarm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chat/auth/auth.dart';
import 'package:chat/etc/messaging.dart';
import 'package:chat/firebase_options.dart';
import 'package:chat/layout.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  ThemeMode themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    initializeAsyncTasks();
  }

  Future<void> initializeAsyncTasks() async {
    try {
      await Messaging().initMessaging();
      await Alarm().scheduleAllAlarms();
    } catch (e) {
      // ignore: avoid_print
      print('Error during async tasks initialization: $e');
    }
  }

  Future<void> saveUserUID(String uid) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'user_uid', value: uid);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "ChatKuy",
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: FutureBuilder<bool>(
        future: checkToken(),
        builder: (context, tokenSnapshot) {
          if (tokenSnapshot.connectionState == ConnectionState.done) {
            if (tokenSnapshot.data == true) {
              return StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, authSnapshot) {
                  if (authSnapshot.connectionState == ConnectionState.waiting) {
                    return const Loading();
                  } else {
                    if (authSnapshot.data != null) {
                      saveUserUID(authSnapshot.data!.uid);
                      return Layout(user: authSnapshot.data);
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
            return const Loading();
          }
        },
      ),
    );
  }
}

Future<bool> checkToken() async {
  try {
    return await const FlutterSecureStorage().containsKey(key: 'token');
  } catch (e) {
    // ignore: avoid_print
    print('Error checking token: $e');
    return false;
  }
}
