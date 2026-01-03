import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/features/auth/controllers/signup/verify_email_controller.dart';
import 'package:rps_stationery/utils/constants/image_strings.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';
import 'package:rps_stationery/utils/helpers/helper_functions.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerifyEmailController());
    bool isDarkMode = HelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle:
            isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              // Illustration
              Image(
                image: AssetImage(ImageString.verifyEmail),
                width: HelperFunctions.screenWidth() * 0.6,
              ),

              const SizedBox(height: AppSizes.spaceBtwSections),

              // Title and sub-title
              Text(
                "Verify your email address",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              Text(
                email ?? '',
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              Text(
                "Almost there! We've sent you a confirmation email. "
                "Please confirm your email address to activate your account. "
                "If you haven't received it, you can resend the email or check your spam/junk folder.",
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await AuthRepository.instance.refreshUser();
                      if (AuthRepository.instance.isEmailVerified) {
                        AuthRepository.instance.screenRedirect();
                      } else {
                        TLoaders.customToast(
                          message:
                              "Please confirm your email before continuing.",
                        );
                      }
                    } catch (e) {
                      TLoaders.customToast(
                        message:
                            "Please confirm your email before continuing.",
                      );
                    }
                  },
                  child: const Text("Continue"),
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => controller.sendVerificationLink(),
                  child: const Text("Resend Email"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
