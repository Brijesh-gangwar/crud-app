import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/task/task_bloc.dart';
import 'blocs/task/task_event.dart';

import 'blocs/theme/theme_bloc.dart';
import 'data/local_db/task_local_db.dart';
import 'theme_notifier.dart';
import 'ui/screens/Splash_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/login_screen.dart';

final themeNotifier = ThemeNotifier();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, themeMode, __) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (_) =>
                  AuthBloc(FirebaseAuth.instance, GoogleSignIn())..add(AuthCheckRequested()),
            ),

            BlocProvider<ThemeBloc>(
      create: (_) => ThemeBloc()..add(LoadThemeEvent()),
    ),
          ],
          child: BlocBuilder<ThemeBloc, ThemeState>(
  builder: (context, themeState) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeState.mode,
      home: const  SplashWrapper(),
    );
  },
),

        );
      },
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _isSplashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isSplashDone = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isSplashDone ? const AuthFlow() : const SplashScreen();
  }
}

class AuthFlow extends StatelessWidget {
  const AuthFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is Authenticated) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            return const LoginScreen(); // fallback in rare case user is null
          }

          return BlocProvider<TaskBloc>(
            create: (_) => TaskBloc(
              localDb: TaskLocalDb.instance,
              user: currentUser,
            )..add(LoadTasksEvent()),
            child: const HomeScreen(),
          );
        }

        return const LoginScreen();
      },
    );
  }
}
