import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/incident_model.dart';
import '../../utils/incident_labels.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'category_art.dart';

/// Horizontally scrolling picture cards, one per category. Used to choose a
/// category on the report form and, with [showAll], to filter the feed.
class CategoryPicker extends StatelessWidget {
  /// The selected category, or '' for "All" when [showAll] is true.
  final String selected;
  final ValueChanged<String> onChanged;

  /// Adds an "All" card first that reports ''.
  final bool showAll;

  final double tileWidth;
  final double tileHeight;

  /// Padding at both ends of the scroll view, so the first card lines up with
  /// the page content but cards can still scroll edge to edge.
  final double sidePadding;

  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.showAll = false,
    this.tileWidth = 128,
    this.tileHeight = 96,
    this.sidePadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final options = [if (showAll) '', ...IncidentModel.categories];
    return SizedBox(
      height: tileHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: sidePadding),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = options[index];
          return SizedBox(
            width: tileWidth,
            child: _CategoryTile(
              category: category,
              selected: category == selected,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(category);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  /// '' is the "All" card.
  final String category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  bool get _isAll => category.isEmpty;

  @override
  Widget build(BuildContext context) {
    final color = _isAll
        ? context.palette.accent
        : IncidentLabels.categoryColor(category);
    final label = _isAll ? 'All' : IncidentLabels.category(category);
    final radius = BorderRadius.circular(AppRadius.sm + AppSpacing.xs);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      hint: _isAll ? 'Show every category' : IncidentLabels.categoryHint(category),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isAll)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.apps_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    )
                  else
                    CategoryArt(category: category),
                  // Dark scrim so the white label stays readable on any photo.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.45, 1],
                        colors: [Colors.transparent, Color(0xCC000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.check, size: 15, color: color),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
