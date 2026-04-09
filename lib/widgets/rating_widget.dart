import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../core/theme/app_theme.dart';

class RatingWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: size,
      ignoreGestures: readOnly,
      itemBuilder: (_, __) => const Icon(Icons.star, color: AppTheme.accentColor),
      onRatingUpdate: onRatingChanged ?? (_) {},
    );
  }
}
