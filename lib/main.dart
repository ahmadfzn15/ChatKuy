import 'dart:isolate';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chat/auth/auth.dart';
import 'package:chat/etc/alarm.dart';
import 'package:chat/etc/background.dart';
import 'package:chat/etc/messaging.dart';
import 'package:chat/firebase_options.dart';
import 'package:chat/layout.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
ReceivePort port = ReceivePort();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
    if (notificationResponse.payload != null) {
      handleNotificationResponse(notificationResponse.payload!);
    }
  }, onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
}

Future<void> _requestPermissions() async {
  await Permission.microphone.request();
  await Permission.notification.request();
  await Permission.ignoreBatteryOptimizations.request();
}

Future<void> _requestPermissionsIfNeeded() async {
  const storage = FlutterSecureStorage();
  String? permissionRequested = await storage.read(key: 'permission_requested');

  if (permissionRequested == null) {
    await _requestPermissions();
    await storage.write(key: 'permission_requested', value: 'true');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Messaging().initMessaging();
  await AndroidAlarmManager.initialize();
  await initializeNotifications();
  await _requestPermissionsIfNeeded();

  await initializeService();

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
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "ChatKuy",
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
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
                    return const CircularProgressIndicator();
                  } else {
                    if (authSnapshot.data != null) {
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
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

Future<bool> checkToken() async {
  return await const FlutterSecureStorage().containsKey(key: 'token');
}
