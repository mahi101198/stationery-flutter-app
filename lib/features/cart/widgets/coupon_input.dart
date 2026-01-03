import 'package:flutter/material.dart';
import 'package:rps_stationery/constants.dart';

class CouponInput extends StatelessWidget {
  const CouponInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Your coupon", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: defaultPadding / 2),
        TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.card_giftcard),
            filled: true,
            fillColor: Colors.grey[200],
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: "Enter coupon code",
          ),
        ),
      ],
    );
  }
}
