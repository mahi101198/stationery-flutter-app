import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/utils/constants/colors.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';

class ReferralsScreen extends StatelessWidget {
  const ReferralsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Header Card
            Card(
              elevation: 3,
              color: TColors.primary.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(TSizes.lg),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.gift,
                      color: TColors.primary,
                      size: 48,
                    ),
                    const SizedBox(height: TSizes.md),
                    const Text(
                      'Refer Friends & Earn Rewards',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: TSizes.sm),
                    Text(
                      'Share your referral code and get ₹50 for every friend who places their first order',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            // Referral Code Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(TSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Referral Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: TSizes.sm),
                    Container(
                      padding: const EdgeInsets.all(TSizes.sm),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'STATIONERY2024',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: 'STATIONERY2024'));
                              Get.snackbar(
                                'Copied!',
                                'Referral code copied to clipboard',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: TColors.primary,
                                colorText: Colors.white,
                              );
                            },
                            icon: const Icon(Iconsax.copy),
                            tooltip: 'Copy code',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(TSizes.md),
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.people,
                            color: TColors.primary,
                            size: 32,
                          ),
                          const SizedBox(height: TSizes.sm),
                          const Text(
                            '5',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Referrals',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(TSizes.md),
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.wallet,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(height: TSizes.sm),
                          const Text(
                            '₹250',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Earned',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            // How it works
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(TSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: TSizes.md),
                    _buildStepItem(
                      '1',
                      'Share your code',
                      'Send your referral code to friends and family',
                      Iconsax.share,
                    ),
                    const SizedBox(height: TSizes.sm),
                    _buildStepItem(
                      '2',
                      'Friend places order',
                      'They use your code during their first purchase',
                      Iconsax.shopping_cart,
                    ),
                    const SizedBox(height: TSizes.sm),
                    _buildStepItem(
                      '3',
                      'Both get rewards',
                      'You get ₹50, they get 10% off their first order',
                      Iconsax.gift,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            // Share Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Share via WhatsApp logic would go here
                      Get.snackbar(
                        'Share',
                        'Opening WhatsApp...',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    icon: const Icon(Iconsax.message),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Generic share logic would go here
                      Get.snackbar(
                        'Share',
                        'Opening share dialog...',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    icon: const Icon(Iconsax.share),
                    label: const Text('More'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: TColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: TSizes.md),
        Icon(
          icon,
          color: TColors.primary,
          size: 20,
        ),
        const SizedBox(width: TSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
