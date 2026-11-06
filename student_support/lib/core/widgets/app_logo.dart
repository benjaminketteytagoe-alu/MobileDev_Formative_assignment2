import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The CampusSupport mark: a "CS" monogram. To use your own logo, replace
/// assets/images/logo.svg; tool/generate_brand_assets.py documents the icons.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      width: size,
      height: size,
      semanticsLabel: 'CampusSupport logo',
    );
  }
}
