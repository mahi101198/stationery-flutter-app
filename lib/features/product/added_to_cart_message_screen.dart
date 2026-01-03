import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/constants.dart';
import 'package:rps_stationery/routes/app_pages.dart';

class AddedToCartMessageScreen extends StatelessWidget {
  const AddedToCartMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                Theme.of(context).brightness == Brightness.light
                    ? "assets/illustration/success.png"
                    : "assets/illustration/success_dark.png",
                height: MediaQuery.of(context).size.height * 0.3,
              ),
              const Spacer(flex: 2),
              Text(
                "Added to cart",
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: defaultPadding / 2),
              const Text(
                "Click the checkout button to complete the purchase process.",
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Go back until we find the bottom nav route
                    Get.offNamedUntil(
                      Routes.bottomNav,
                      arguments: 'home',
                      (route) => route.settings.name == Routes.bottomNav,
                    );
                  },
                  child: const Text("Continue shopping"),
                ),
              ),
              const SizedBox(height: defaultPadding),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Go back until we find the bottom nav route, then navigate to cart
                    Get.offNamedUntil(
                      Routes.bottomNav,
                      arguments: 'cart',
                      (route) => route.settings.name == Routes.bottomNav,
                    );
                  },
                  child: const Text("Checkout"),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
