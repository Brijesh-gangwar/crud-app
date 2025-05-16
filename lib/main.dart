
import 'dart:async';
import 'package:crud_app/widgets/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

final themeNotifier = ThemeNotifier();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Wait for theme to load before running app
  await Future.delayed(const Duration(milliseconds: 100));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, themeMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Task Manager',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          home: const AuthGateWithConnectivity(),
        );
      },
    );
  }
}

class AuthGateWithConnectivity extends StatefulWidget {
  const AuthGateWithConnectivity({super.key});

  @override
  State<AuthGateWithConnectivity> createState() =>
      _AuthGateWithConnectivityState();
}

class _AuthGateWithConnectivityState extends State<AuthGateWithConnectivity> {
  late StreamSubscription<ConnectivityResult> _subscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();

   _subscription = Connectivity().onConnectivityChanged.cast<ConnectivityResult>().listen((result) {
      final nowOnline = result != ConnectivityResult.none;
      if (_isOnline != nowOnline) {
        setState(() {
          _isOnline = nowOnline;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nowOnline ? 'Back online' : 'You are offline'),
            backgroundColor: nowOnline ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No internet connection.\nPlease connect and restart the app.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return const AuthGate();
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          return snapshot.data == null ? const LoginScreen() : const HomeScreen();
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
