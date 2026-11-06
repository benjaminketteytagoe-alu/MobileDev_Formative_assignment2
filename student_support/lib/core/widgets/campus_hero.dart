import 'package:flutter/material.dart';

import '../app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Top of the home feed: the ALU campus photo with a navy wash for legible
/// text, fading into the page background at the bottom so the hero and the
/// content below read as one surface.
///
/// Add the photo as assets/images/campus_hero.jpg. Until then the brand
/// gradient is shown.
class CampusHero extends StatelessWidget {
  final String greeting;
  final String message;

  /// Shown beside the greeting, e.g. the user's avatar.
  final Widget? leading;

  /// Optional call to action, e.g. "Report an issue" for students.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Height of the fade at the bottom edge. Text is kept above it.
  static const double fadeHeight = 72;

  const CampusHero({
    super.key,
    required this.greeting,
    required this.message,
    this.leading,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final photo = AppAssets.campusHero;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fadeStart = constraints.maxHeight <= fadeHeight
            ? 0.0
            : 1 - fadeHeight / constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            // The photo and its wash fade out together, revealing the
            // scaffold background underneath.
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, fadeStart, 1],
                colors: const [Colors.black, Colors.black, Colors.transparent],
              ).createShader(rect),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photo != null)
                    Image.asset(
                      photo,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                        ),
                      ),
                    )
                  else
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryDark.withValues(alpha: 0.75),
                          AppColors.aluNavy.withValues(alpha: 0.45),
                          AppColors.aluNavy.withValues(alpha: 0.65),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: fadeHeight - AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                      ],
                      Expanded(
                        child: Text(
                          greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(color: Colors.black38, blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 14,
                      height: 1.4,
                      shadows: const [
                        Shadow(color: Colors.black38, blurRadius: 6),
                      ],
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: Text(actionLabel!),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.aluGold,
                        foregroundColor: AppColors.primaryDark,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + AppSpacing.xs,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
