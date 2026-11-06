import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../utils/incident_labels.dart';
import '../dicebear.dart';
import '../theme/app_radius.dart';
import 'animated_svg_view.dart';
import 'motion.dart';

/// A category's DiceBear icon on its category color. Bundled, so it needs no
/// network. Decorative: the category name is always shown beside it.
class CategoryIconBadge extends StatelessWidget {
  final String category;
  final double size;

  const CategoryIconBadge({super.key, required this.category, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: SvgPicture.asset(
        DiceBear.categoryIcon(category),
        width: size,
        height: size,
        excludeFromSemantics: true,
        placeholderBuilder: (_) => SizedBox.square(
          dimension: size,
          child: ColoredBox(color: IncidentLabels.categoryColor(category)),
        ),
        errorBuilder: (_, _, _) => ColoredBox(
          color: IncidentLabels.categoryColor(category),
          child: Icon(
            IncidentLabels.categoryIcon(category),
            size: size * 0.7,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Friendly bundled character for empty and error states. It pops in, then
/// plays DiceBear's animation where a WebView is available.
class DiceBearMascot extends StatefulWidget {
  final String asset;
  final double size;

  const DiceBearMascot(this.asset, {super.key, this.size = 128});

  @override
  State<DiceBearMascot> createState() => _DiceBearMascotState();
}

class _DiceBearMascotState extends State<DiceBearMascot> {
  String? _svg;

  @override
  void initState() {
    super.initState();
    if (AnimatedSvgView.isSupported) _load();
  }

  Future<void> _load() async {
    final svg = await rootBundle.loadString(widget.asset);
    if (mounted) setState(() => _svg = svg);
  }

  @override
  Widget build(BuildContext context) {
    final still = SvgPicture.asset(
      widget.asset,
      width: widget.size,
      height: widget.size,
      excludeFromSemantics: true,
    );
    final svg = _svg;
    return PopIn(
      child: SizedBox.square(
        dimension: widget.size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: svg == null
              ? still
              : AnimatedSvgView(svg: svg, placeholder: still),
        ),
      ),
    );
  }
}
