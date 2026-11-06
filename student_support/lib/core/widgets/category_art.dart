import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../utils/incident_labels.dart';
import '../app_assets.dart';

/// Picture for a report category, used in the category picker and wherever
/// a report has no photo. Uses the photo in assets/images/categories/ when
/// there is one, otherwise the built-in illustration, otherwise the category
/// icon on the category color.
class CategoryArt extends StatelessWidget {
  final String category;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const CategoryArt({
    super.key,
    required this.category,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final color = IncidentLabels.categoryColor(category);
    final illustration = IncidentLabels.categoryAsset(category);
    final photo = AppAssets.categoryPhoto(category);
    final fallback = ColoredBox(
      color: color,
      child: Center(
        child: Icon(
          IncidentLabels.categoryIcon(category),
          color: Colors.white,
          size: 28,
        ),
      ),
    );

    Widget svgOrFallback() => illustration == null
        ? fallback
        : SvgPicture.asset(
            illustration,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            placeholderBuilder: (_) => ColoredBox(color: color),
            errorBuilder: (_, _, _) => fallback,
          );

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Semantics(
        label: '${IncidentLabels.category(category)} illustration',
        image: true,
        child: photo == null
            ? svgOrFallback()
            : Image.asset(
                photo,
                fit: fit,
                width: double.infinity,
                height: double.infinity,
                // Decode at display size, not the photo's full resolution.
                cacheWidth: 600,
                errorBuilder: (_, _, _) => svgOrFallback(),
              ),
      ),
    );
  }
}
