import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.rating,
    required this.numOfReviews,
    this.numOfFiveStar = 0,
    this.numOfFourStar = 0,
    this.numOfThreeStar = 0,
    this.numOfTwoStar = 0,
    this.numOfOneStar = 0,
  });

  final double rating;
  final int numOfReviews;
  final int numOfFiveStar,
      numOfFourStar,
      numOfThreeStar,
      numOfTwoStar,
      numOfOneStar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      width: double.infinity,
      decoration: BoxDecoration(
        color: (Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.035),
        borderRadius:
            const BorderRadius.all(Radius.circular(defaultBorderRadious)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: "$rating ",
                    style: (Theme.of(context)
                        .textTheme
                        .headlineSmall ?? DefaultTextStyle.of(context).style)
                        .copyWith(fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: "/5",
                        style: Theme.of(context).textTheme.titleMedium ?? DefaultTextStyle.of(context).style,
                      ),
                    ],
                  ),
                ),
                Text("Based on $numOfReviews Reviews"),
                const SizedBox(height: defaultPadding),
                RatingBar.builder(
                  initialRating: rating,
                  itemSize: 20,
                  itemPadding: const EdgeInsets.only(right: defaultPadding / 4),
                  unratedColor: (Theme.of(context)
                      .textTheme
                      .bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface)
                      .withValues(alpha: 0.08),
                  glow: false,
                  allowHalfRating: true,
                  ignoreGestures: true,
                  onRatingUpdate: (value) {},
                  itemBuilder: (context, index) =>
                      SvgPicture.asset("assets/icons/Star_filled.svg"),
                ),
              ],
            ),
          ),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Column(
              children: [
                RateBar(star: 5, value: numOfReviews == 0 ? 0.0 : (numOfFiveStar / numOfReviews).clamp(0.0, 1.0)),
                RateBar(star: 4, value: numOfReviews == 0 ? 0.0 : (numOfFourStar / numOfReviews).clamp(0.0, 1.0)),
                RateBar(star: 3, value: numOfReviews == 0 ? 0.0 : (numOfThreeStar / numOfReviews).clamp(0.0, 1.0)),
                RateBar(star: 2, value: numOfReviews == 0 ? 0.0 : (numOfTwoStar / numOfReviews).clamp(0.0, 1.0)),
                RateBar(star: 1, value: numOfReviews == 0 ? 0.0 : (numOfOneStar / numOfReviews).clamp(0.0, 1.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RateBar extends StatelessWidget {
  const RateBar({
    super.key,
    required this.star,
    required this.value,
  });

  final int star;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: star == 1 ? 0 : defaultPadding / 2),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "$star Star",
              style: (Theme.of(context).textTheme.labelSmall ?? Theme.of(context).textTheme.bodySmall ?? DefaultTextStyle.of(context).style).copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: defaultPadding / 2),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(defaultBorderRadious),
              ),
              child: LinearProgressIndicator(
                minHeight: 6,
                color: warningColor,
                backgroundColor: (Theme.of(context)
                    .textTheme
                    .bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface)
                    .withValues(alpha: 0.05),
                value: value.isFinite ? value.clamp(0.0, 1.0) : 0.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
