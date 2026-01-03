import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/features/auth/controllers/login/login_controller.dart';
import 'package:rps_stationery/features/auth/screens/signup/signup.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/constants/image_strings.dart';
import 'package:rps_stationery/utils/validators/validation.dart';
import 'package:rps_stationery/utils/validators/form_validators.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/components/ui/modern_components.dart' show ButtonVariant, ButtonSize;
import 'package:rps_stationery/utils/theme/app_colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                    vertical: isTablet ? 80 : 60,
                  ),
                  child: LoginForm(isTablet: isTablet),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LoginForm extends StatelessWidget {
  final bool isTablet;
  const LoginForm({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Form(
      key: controller.loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: isTablet ? 80 : 40),

          // Title
          Text(
            "Welcome back",
            style: TextStyle(
              fontSize: isTablet ? 32 : 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Use your credentials below and login to your account",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 40),

          // Email Field
          ThemeAwareTextField(
            controller: controller.email,
            label: "Email",
            hint: "Enter your email",
            prefixIcon: Iconsax.sms,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => FormValidators.validateEmail(value),
          ),
          const SizedBox(height: 24),

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
          const SizedBox(height: 16),

          // Remember me + Forgot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Row(
                  children: [
                    Checkbox(
                      value: controller.rememberMe.value,
                      onChanged: controller.toggleRememberMe,
                    ),
                    Text(
                      "Remember me",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.toNamed(Routes.forgotPassword);
                },
                child: Text(
                  "Forgot password?",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),

          // Sign In Button
          Obx(
            () => ThemeAwareButton(
              text: "Sign In",
              onPressed: controller.login,
              variant: ButtonVariant.primary,
              size: isTablet ? ButtonSize.large : ButtonSize.medium,
              fullWidth: true,
              isLoading: controller.isLoading.value,
              isDisabled: controller.isLoading.value,
              icon: Iconsax.login,
            ),
          ),

          const SizedBox(height: 20),

          // Signup
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: Text(
                  "Sign Up",
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
