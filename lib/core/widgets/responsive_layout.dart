import 'package:flutter/material.dart';

class ResponsiveLayout {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileBreakpoint && w < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileBreakpoint) return 2;
    if (w < tabletBreakpoint) return 3;
    return 4;
  }

  static double bannerHeight(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileBreakpoint) return 160;
    if (w < tabletBreakpoint) return 220;
    return 300;
  }

  static double cardWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileBreakpoint) return (w - 32) / 2;
    if (w < tabletBreakpoint) return (w - 48) / 3;
    return (w - 80) / 4;
  }
}
