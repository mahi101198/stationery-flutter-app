import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../login/login.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  final String email;
  
  const PasswordResetSuccessScreen({super.key, required this.email});

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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD9F7E5), Color(0xFFEFFAF4)], // green gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isTablet ? 60 : 30),

                      // Success Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Success Title
                      Text(
                        "Reset Link Sent!",
                        style: TextStyle(
                          fontSize: isTablet ? 32 : 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20), // dark green
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // Success Message
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "We've sent a password reset link to:",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: isTablet ? 16 : 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              email,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF1B5E20),
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Please check your email and click the link to reset your password.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isTablet ? 14 : 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Back to Login Button
                      SizedBox(
                        width: double.infinity,
                        height: isTablet ? 55 : 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                            shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                          ),
                          onPressed: () {
                            // Navigate back to login screen
                            Get.offAll(() => const LoginScreen()); // Use offAll to clear navigation stack
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.login,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Back to Login",
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Resend Link Option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the email? ",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isTablet ? 14 : 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Go back to forgot password screen
                              Get.back();
                            },
                            child: Text(
                              "Try again",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                                fontSize: isTablet ? 14 : 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Additional Help Text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color(0xFF1B5E20),
                              size: isTablet ? 20 : 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Check your spam folder if you don't see the email in your inbox.",
                                style: TextStyle(
                                  color: const Color(0xFF1B5E20),
                                  fontSize: isTablet ? 13 : 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
