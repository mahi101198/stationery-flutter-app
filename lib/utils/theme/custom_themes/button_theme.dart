import 'package:flutter/material.dart';

class AppButtonTheme {
  AppButtonTheme._();

  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: Colors.white,
      backgroundColor: Colors.tealAccent
    )
  );
}
