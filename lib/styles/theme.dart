import 'package:flutter/material.dart';

// PALETTE
class AsanColorScheme {
  // main colors
  static const Color primary = Color(0xFF28B873);
  static const Color secondary = Color(0xFF1B0808);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFEE0000);
  static const Color container = Color(0xFFF0F0F0);
  static const Color inactive = Color(0xFF999999);
  static const Color shadow = Color(0x40000000);
  // on colors
  static const Color onPrimary = Color(0xFF1B0808);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1B0808);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onContainer = Color(0xFF1B0808);
  // accent colors
  static const Color yellow = Color(0xFFF4E285);
  static const Color pink = Color(0xFFFF99C8);
  static const Color blue = Color(0xFFA9DEF9);
  static const Color orange = Color(0xFFFF8552);
  static const Color purple = Color(0xFFE4C1F9);
}

// TYPE SCALE
class AsanTextTheme {
  // heading
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'BricolageGrotesque',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.4,
  );
  // body
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'BricolageGrotesque',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  // capption
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'BricolageGrotesque',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
}

// SPACING
class AsanSpacing {
  // base unit
  static const double xs = 4;
  // between list items
  static const double sm = 8;
  // between sections
  static const double md = 16;
  // screen edge padding
  static const double lg = 24;
}
