import 'package:flutter/material.dart';

class MyAppColors {
  static const Color redDamask = Color(0xFFF15922);
  static const Color nobel = Color(0xFFB3B2B2);
  static const Color codGray = Color(0xFF161616);
}

final ThemeData appTheme = ThemeData(
  primaryColor: MyAppColors.redDamask,
  scaffoldBackgroundColor: MyAppColors.nobel,
  appBarTheme: AppBarTheme(
    backgroundColor: MyAppColors.redDamask,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      color: MyAppColors.codGray,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: MyAppColors.redDamask,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: MyAppColors.nobel),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: MyAppColors.nobel),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: MyAppColors.redDamask, width: 2),
    ),
    labelStyle: const TextStyle(color: MyAppColors.codGray, fontWeight: FontWeight.w500),
  ),
);
