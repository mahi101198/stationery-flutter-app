import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:rps_stationery/features/auth/controllers/login/login_controller.dart';
import 'package:rps_stationery/utils/constants/colors.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';

class SocialButton extends StatelessWidget {
  const SocialButton({super.key, required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey),
        borderRadius: BorderRadius.circular(100),
      ),
      child: IconButton(
        onPressed: () => controller.googleSignIn(),
        icon: Image(
          width: AppSizes.iconMd,
          height: AppSizes.iconMd,
          image: AssetImage(image),
        ),
      ),
    );
  }
}
