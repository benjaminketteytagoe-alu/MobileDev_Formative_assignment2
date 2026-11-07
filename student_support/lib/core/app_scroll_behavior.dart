import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Lets every scrollable in the app scroll with touch, a mouse, a trackpad or
/// a stylus, so lists and pages also scroll in the Android emulator with the
/// computer's mouse. A scrollbar shows while scrolling, which tells the user
/// how much more there is in that direction.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return Scrollbar(controller: details.controller, child: child);
  }
}
