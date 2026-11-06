import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> softShadowLg = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> navShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, -4)),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(color: Color(0x330B2A5B), blurRadius: 8, offset: Offset(0, 4)),
  ];
}
