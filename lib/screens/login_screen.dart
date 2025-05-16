
import 'package:crud_app/screens/home_screen.dart';
import 'package:crud_app/widgets/snakbar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;

  Future<void> _submit() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        showCustomSnackBar(context: context, message: "Login successful");
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        showCustomSnackBar(context: context, message: "Registration successful");
      }
    } catch (e) {
      showCustomSnackBar(context: context, message: "Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    showCustomSnackBar(context: context, message: "Signing in with Google...");
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final FirebaseAuth auth = FirebaseAuth.instance;

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        showCustomSnackBar(context: context, message: "Welcome, ${user.displayName}!");
      }
    } catch (e) {
      showCustomSnackBar(context: context, message: "Google Sign-In failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(children: [
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: Text(isLogin ? 'Login' : 'Register'),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : () => setState(() => isLogin = !isLogin),
                    child: Text(isLogin ? "Create account" : "Already have account? Login"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    
                    label: const Text('Sign in with Google'),
                    onPressed: isLoading ? null : _signInWithGoogle,
                  ),
                ]),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

