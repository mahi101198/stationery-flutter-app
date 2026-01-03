import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/features/auth/controllers/login/login_controller.dart';
import 'package:rps_stationery/utils/validators/form_validators.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final controller = Get.put(LoginController());
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

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
            child: Stack(
              children: [
                // Back Button - Fixed at top left
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16, // Account for status bar
                  left: 24,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),
                
                // Main Content - Centered
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 500 : constraints.maxWidth,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 40 : 24,
                        vertical: isTablet ? 80 : 60,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: isTablet ? 40 : 20),

                            // Icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: const Icon(
                                Icons.lock_reset,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Title
                            Text(
                              "Forgot Password",
                              style: TextStyle(
                                fontSize: isTablet ? 32 : 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20), // dark green
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Don't worry! It occurs. Please enter the email address linked with your account.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Email Field
                            _buildLabel("Email", isTablet),
                            const SizedBox(height: 8),
                            _buildTextField(
                              "Enter your email",
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => FormValidators.validateEmail(value),
                            ),
                            const SizedBox(height: 32),

                            // Send Code Button
                            SizedBox(
                              width: double.infinity,
                              height: isTablet ? 55 : 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    controller.forgotPassword(emailController.text);
                                  }
                                },
                                child: Text(
                                  "Send Link to Reset",
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Remember Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Remember Password? "),
                                GestureDetector(
                                  onTap: () => Get.back(),
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ),
                              ],
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
        },
      ),
    );
  }

  Widget _buildLabel(String text, bool isTablet) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    TextEditingController? controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
    );
  }
}
