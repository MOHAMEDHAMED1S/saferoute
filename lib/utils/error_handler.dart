import 'package:flutter/material.dart';

class ErrorHandler {
  static void handleError(BuildContext context, dynamic error) {
    String errorMessage = handleApiErrorEnglish(error);
    showErrorSnackBar(context, errorMessage);
  }
  
  static String handleApiErrorEnglish(dynamic error) {
    if (error is String) {
      return error;
    } else if (error is Map && error.containsKey('message')) {
      return error['message'];
    } else if (error is Exception) {
      return error.toString();
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}