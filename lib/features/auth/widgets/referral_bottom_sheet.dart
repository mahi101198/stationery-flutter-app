import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';

class ReferralBottomSheet extends StatefulWidget {
  final Function(String?) onReferralSubmit;

  const ReferralBottomSheet({super.key, required this.onReferralSubmit});

  @override
  State<ReferralBottomSheet> createState() => _ReferralBottomSheetState();
}

class _ReferralBottomSheetState extends State<ReferralBottomSheet> {
  final TextEditingController _referralController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleSkip();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSizes.borderRadiusLg),
            topRight: Radius.circular(AppSizes.borderRadiusLg),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Do you have a referral code?",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems / 2),

              // Subtitle
              Text(
                "Enter a referral code from a friend to get started, or skip this step.",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              // Referral code input
              TextFormField(
                controller: _referralController,
                decoration: const InputDecoration(
                  labelText: "Referral Code",
                  prefixIcon: Icon(Iconsax.gift),
                  hintText: "Enter referral code",
                ),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                enabled: !_isLoading,
                onFieldSubmitted: (_) => _handleSubmit(),
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              // Buttons
              Row(
                children: [
                  // Skip button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleSkip,
                      child: const Text("Skip"),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceBtwItems),

                  // Submit button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text("Submit"),
                    ),
                  ),
                ],
              ),

              // Safe area padding - reduced to prevent overflow
              SizedBox(height: MediaQuery.of(context).padding.bottom > 0 
                  ? MediaQuery.of(context).padding.bottom / 2 
                  : AppSizes.spaceBtwItems),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSkip() {
    Get.back();
    widget.onReferralSubmit(null);
  }

  void _handleSubmit() {
    final referralCode = _referralController.text.trim().toUpperCase();

    if (referralCode.isEmpty) {
      _handleSkip();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Get.back();
    widget.onReferralSubmit(referralCode);
  }
}

// Helper function to show the referral bottom sheet
Future<void> showReferralBottomSheet({
  required Function(String?) onReferralSubmit,
}) async {
  await Get.bottomSheet(
    ReferralBottomSheet(onReferralSubmit: onReferralSubmit),
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
  );
}
