import 'package:flutter/material.dart';

/// A global theme notifier to track theme mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void showCustomSnackBar({
  required BuildContext context,
  required String message,
}) {
  final isDarkMode = themeNotifier.value == ThemeMode.dark;

  final snackBar = SnackBar(
    content: Text(
      message,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    ),
    backgroundColor: isDarkMode ? Colors.black : Colors.white,
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
