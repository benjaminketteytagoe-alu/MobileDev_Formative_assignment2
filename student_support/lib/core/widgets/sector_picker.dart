import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/incident_model.dart';
import '../../utils/incident_labels.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Horizontally scrolling cards for the four ALU campus sectors.
class SectorPicker extends StatelessWidget {
  /// The selected sector, or '' for none / "All".
  final String selected;
  final ValueChanged<String> onChanged;

  /// Adds an "All sectors" card first that reports ''. Used by the feed.
  final bool showAll;

  /// Red outline and message under the cards, as a form field would show.
  final String? errorText;

  final double sidePadding;

  const SectorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.showAll = false,
    this.errorText,
    this.sidePadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final options = [if (showAll) '', ...IncidentModel.sectors];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final sector = options[index];
              return _SectorChip(
                sector: sector,
                selected: sector == selected,
                hasError: errorText != null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(sector);
                },
              );
            },
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              sidePadding + AppSpacing.sm,
              AppSpacing.xs,
              sidePadding,
              0,
            ),
            child: Text(
              errorText!,
              style: context.text.caption.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

class _SectorChip extends StatelessWidget {
  final String sector;
  final bool selected;
  final bool hasError;
  final VoidCallback onTap;

  const _SectorChip({
    required this.sector,
    required this.selected,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final label = sector.isEmpty
        ? 'All sectors'
        : IncidentLabels.sector(sector);
    final icon = sector.isEmpty
        ? Icons.map_outlined
        : IncidentLabels.sectorIcon(sector);
    final idleBorder = hasError
        ? AppColors.error
        : (isDark ? AppColors.darkBorder : context.palette.border);
    final radius = BorderRadius.circular(AppRadius.sm);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? accent
            : (isDark ? AppColors.darkSurface : context.palette.surface),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: selected ? accent : idleBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: selected ? Colors.white : accent),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: context.text.body.copyWith(
                    color: selected
                        ? Colors.white
                        : (isDark
                              ? AppColors.darkTextPrimary
                              : context.palette.textPrimary),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
