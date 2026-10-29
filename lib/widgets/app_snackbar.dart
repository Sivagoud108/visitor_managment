import 'package:flutter/material.dart';

SnackBar appSnackBar(String message, {bool isError = false}) {
  return SnackBar(
    content: Text(message),
    backgroundColor: isError ? Colors.red.shade700 : null,
    behavior: SnackBarBehavior.floating,
  );
}
