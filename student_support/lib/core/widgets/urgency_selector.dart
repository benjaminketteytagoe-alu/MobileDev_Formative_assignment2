import 'package:flutter/material.dart';

import '../../utils/incident_labels.dart';
import '../theme/app_spacing.dart';
import '../theme/app_palette.dart';

/// Chip-based urgency selector for Low / Medium / High.
class UrgencySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const UrgencySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Urgency Level', style: context.text.caption),
        SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          children: ['low', 'medium', 'high'].map((level) {
            final isSelected = selected.toLowerCase() == level;
            return ChoiceChip(
              label: Text(
                IncidentLabels.urgency(level),
                style: context.text.body.copyWith(
                  color: isSelected
                      ? Colors.white
                      : IncidentLabels.urgencyColor(level),
                ),
              ),
              selected: isSelected,
              selectedColor: IncidentLabels.urgencyColor(level),
              backgroundColor: Theme.of(context).cardColor,
              side: BorderSide(
                color: IncidentLabels.urgencyColor(level),
                width: isSelected ? 2 : 1,
              ),
              onSelected: (_) => onChanged(level),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
