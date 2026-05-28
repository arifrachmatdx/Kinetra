import 'package:flutter/material.dart';

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message);

  static void error(BuildContext context, String message) =>
      show(context, message: message, isError: true);
}
