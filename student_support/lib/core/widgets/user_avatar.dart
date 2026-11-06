import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/avatar_provider.dart';
import '../theme/app_colors.dart';
import 'animated_svg_view.dart';

/// A person's DiceBear avatar. Initials show until it loads, and stay if it
/// cannot load, so the avatar never depends on the network.
class UserAvatar extends ConsumerWidget {
  final String userId;
  final String name;
  final double size;

  /// Plays DiceBear's animation. Uses a WebView, so keep it to the one large
  /// avatar on a screen.
  final bool animated;

  const UserAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.size = 40,
    this.animated = false,
  });

  /// "Ama Mensah" gives "AM", "Ama" gives "A".
  static String initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final letters = words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.substring(0, 1).toUpperCase());
    return letters.isEmpty ? '?' : letters.join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svg = userId.isEmpty
        ? null
        : ref.watch(avatarSvgProvider(userId)).valueOrNull;

    final Widget image;
    if (svg == null) {
      image = _Initials(
        key: const ValueKey('initials'),
        text: initials(name),
        size: size,
      );
    } else {
      final still = SvgPicture.string(
        svg,
        key: const ValueKey('avatar-still'),
        width: size,
        height: size,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      );
      image = animated
          ? AnimatedSvgView(
              key: const ValueKey('avatar-animated'),
              svg: svg,
              placeholder: still,
            )
          : still;
    }

    return Semantics(
      label: name.isEmpty ? 'Avatar' : 'Avatar of $name',
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: image,
          ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  final double size;

  const _Initials({super.key, required this.text, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * (text.length > 1 ? 0.36 : 0.44),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
