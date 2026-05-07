import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class RatingWidget extends StatefulWidget {
  final double rating;
  final bool readOnly;
  final ValueChanged<double>? onRatingChanged;
  final double size;

  const RatingWidget({
    super.key,
    required this.rating,
    this.readOnly = true,
    this.onRatingChanged,
    this.size = 24,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late double _current;

  @override
  void initState() {
    super.initState();
    _current = widget.rating;
  }

  void _onTap(int index) {
    if (widget.readOnly) return;
    final val = index.toDouble();
    setState(() => _current = val);
    widget.onRatingChanged?.call(val);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = _current >= i + 1;
        return GestureDetector(
          onTap: () => _onTap(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              filled ? Icons.star : Icons.star_border,
              color: AppTheme.accentColor,
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}
