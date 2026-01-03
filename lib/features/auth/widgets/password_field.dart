import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PasswordField extends StatelessWidget {
  const PasswordField({super.key, required this.label, required this.textInputAction});

  final String label;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {

    PasswordController controller = PasswordController();

    return Obx(
      () => TextFormField(
        expands: false,
        obscureText: controller.obscure.value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Iconsax.lock),
          suffixIcon: IconButton(
            onPressed: () => controller.obscure.value = !controller.obscure.value,
            icon: Icon(controller.obscure.value ? Iconsax.eye_slash : Iconsax.eye)
          ),
        ),
        keyboardType: TextInputType.visiblePassword,
        textInputAction: textInputAction,
      ),
    );
  }
}

class PasswordController extends GetxController {
  final RxBool obscure = true.obs;
}
