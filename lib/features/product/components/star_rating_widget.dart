import 'package:flutter/material.dart';

/// Star rating widget that displays rating as yellow stars
/// Matches mockup design exactly
class StarRatingWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final int maxStars;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.size = 18.0,
    this.color = const Color(0xFFFBBF24), // Yellow from mockup
    this.maxStars = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        IconData iconData;
        
        if (index < rating.floor()) {
          // Full star
          iconData = Icons.star;
        } else if (index < rating && rating - index >= 0.5) {
          // Half star
          iconData = Icons.star_half;
        } else {
          // Empty star
          iconData = Icons.star_border;
        }
        
        return Icon(
          iconData,
          color: color,
          size: size,
        );
      }),
    );
  }
}
