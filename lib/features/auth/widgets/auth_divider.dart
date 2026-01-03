import 'package:flutter/material.dart';
import 'package:rps_stationery/utils/constants/colors.dart';
import 'package:rps_stationery/utils/helpers/helper_functions.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    bool dark = HelperFunctions.isDarkMode(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Divider(
            color: dark ? AppColors.darkGrey : AppColors.grey,
            thickness: 1.0,
            indent: 60,
            endIndent: 5,
          ),
        ),
        Text(
          'OR CONTINUE WITH',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Flexible(
          child: Divider(
            color: Colors.grey[400],
            thickness: 1.0,
            indent: 5,
            endIndent: 60,
          ),
        ),
      ],
    );
  }
}
