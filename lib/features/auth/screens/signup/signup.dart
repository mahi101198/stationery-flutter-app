import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/auth/controllers/signup/signup_controller.dart';
import 'package:rps_stationery/features/auth/screens/login/login.dart';
import 'package:rps_stationery/utils/constants/image_strings.dart';
import 'package:rps_stationery/utils/validators/validation.dart';
import 'package:rps_stationery/utils/validators/form_validators.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/components/ui/modern_components.dart' show ButtonVariant, ButtonSize;
import 'package:rps_stationery/utils/theme/app_colors.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: context.cardGradient,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 500 : constraints.maxWidth,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 40 : 24,
                    vertical: isTablet ? 40 : 20,
                  ),
                  child: SignupForm(isTablet: isTablet),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SignupForm extends StatelessWidget {
  final bool isTablet;
  const SignupForm({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignupController());

    return Form(
      key: controller.signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: isTablet ? 20 : 10),

          // Back Button (Navigate to Login)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                // Try to pop, if can't pop then navigate to login
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Get.offAll(() => const LoginScreen());
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Iconsax.arrow_left,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            "Create your Account",
            style: TextStyle(
              fontSize: isTablet ? 32 : 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Join us today and start your journey with us",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 30),

          // First Name & Last Name Row
          Row(
            children: [
              Expanded(
                child: ThemeAwareTextField(
                  controller: controller.firstName,
                  label: "First Name",
                  hint: "Enter first name",
                  prefixIcon: Iconsax.user,
                  keyboardType: TextInputType.name,
                  validator: (value) => TValidator.validateEmpty("First name", value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ThemeAwareTextField(
                  controller: controller.lastName,
                  label: "Last Name",
                  hint: "Enter last name",
                  prefixIcon: Iconsax.user,
                  keyboardType: TextInputType.name,
                  validator: (value) => TValidator.validateEmpty("Last name", value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Email Field
          ThemeAwareTextField(
            controller: controller.email,
            label: "Email",
            hint: "Enter your email",
            prefixIcon: Iconsax.sms,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => FormValidators.validateEmail(value),
          ),
          const SizedBox(height: 20),

          // Password Field
          Obx(
            () => ThemeAwareTextField(
              controller: controller.password,
              label: "Password",
              hint: "Enter your password",
              prefixIcon: Iconsax.lock,
              suffixIcon: controller.hidePassword.value ? Iconsax.eye_slash : Iconsax.eye,
              onSuffixIconPressed: () => controller.hidePassword.value = !controller.hidePassword.value,
              isPassword: controller.hidePassword.value,
              validator: (value) => TValidator.validatePassword(value),
            ),
          ),
          const SizedBox(height: 24),

          // Confirm Password Field
          Obx(
            () => ThemeAwareTextField(
              controller: controller.confirmPassword,
              label: "Confirm Password",
              hint: "Confirm your password",
              prefixIcon: Iconsax.lock,
              suffixIcon: controller.hideConfirmPassword.value ? Iconsax.eye_slash : Iconsax.eye,
              onSuffixIconPressed: () => controller.hideConfirmPassword.value = !controller.hideConfirmPassword.value,
              isPassword: controller.hideConfirmPassword.value,
              validator: (value) => TValidator.validateConfirmPassword(
                controller.password.text,
                value,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Referral Code Field (Optional)
          ThemeAwareTextField(
            controller: controller.referralCode,
            label: "Referral Code (Optional)",
            hint: "Enter referral code",
            prefixIcon: Iconsax.gift,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 20),

          // Terms and Conditions
          Obx(
            () => Row(
              children: [
                Checkbox(
                  value: controller.privacyPolicy.value,
                  onChanged: (value) => controller.privacyPolicy.value = value ?? false,
                ),
                Expanded(
                  child: Text(
                    "I agree to the Privacy Policy and Terms of Use",
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Create Account Button
          ThemeAwareButton(
            text: "Create Account",
            onPressed: controller.signup,
            variant: ButtonVariant.primary,
            size: isTablet ? ButtonSize.large : ButtonSize.medium,
            fullWidth: true,
            icon: Iconsax.user_add,
          ),

          const SizedBox(height: 20),

          // Already have account
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account? ",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to login screen
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Get.offAll(() => const LoginScreen());
                  }
                },
                child: Text(
                  "Sign In",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              )
            ],
          ),

          const SizedBox(height: 30),

          // OR divider
          Row(
            children: [
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "OR",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Social Login Apple - Commented out for Android (will be used in iOS)
          /*
          SizedBox(
            width: double.infinity,
            height: isTablet ? 55 : 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.apple, color: Colors.black),
              label: Text(
                "Continue with Apple",
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: isTablet ? 18 : 16),
              ),
              onPressed: () {
                // Apple Sign-In implementation for iOS
              },
            ),
          ),

          const SizedBox(height: 16),
          */

          // Social Login Google
          Container(
            width: double.infinity,
            height: isTablet ? 55 : 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.googleSignIn(),
                borderRadius: BorderRadius.circular(25),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        ImageString.google,
                        height: isTablet ? 26 : 22,
                        width: isTablet ? 26 : 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Continue with Google",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
