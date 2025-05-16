import 'package:crud_app/main.dart';
import 'package:flutter/material.dart';


void showCustomSnackBar({
  required BuildContext context,
  required String message,
 
}) {
  final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: themeNotifier.value == ThemeMode.dark ? Colors.white: Colors.black ),
      ),
      backgroundColor: themeNotifier.value == ThemeMode.dark ? Colors.black : Colors.white,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(snackBar);
}
