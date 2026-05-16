import 'package:flutter/material.dart';

class Responsive {
  static late double width;
  static late double height;
  static late bool isMobile;
  static late bool isTablet;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;

    width = size.width;
    height = size.height;

    // You can tweak these breakpoints
    isMobile = width < 600;
    isTablet = width >= 600;
  }

  // Handy helpers
  static double wp(double percent) => width * percent / 100;
  static double hp(double percent) => height * percent / 100;
}
