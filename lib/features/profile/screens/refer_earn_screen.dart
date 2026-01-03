import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/profile/controllers/referral_controller.dart';
import 'package:rps_stationery/services/referral_service.dart';
import 'package:rps_stationery/utils/constants/colors.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReferralController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadReferralData,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rewards Header Card
                _buildRewardsCard(context, controller),
                const SizedBox(height: TSizes.spaceBtwSections),

                // Your Referral Code Card
                _buildReferralCodeCard(context, controller),
                const SizedBox(height: TSizes.spaceBtwSections),

                // Earnings Summary
                _buildEarningsSummary(context, controller),
                const SizedBox(height: TSizes.spaceBtwSections),

                // How It Works
                _buildHowItWorks(context),
                const SizedBox(height: TSizes.spaceBtwSections),

                // Referred Users List
                if (controller.referredUsers.isNotEmpty) ...[
                  _buildReferredUsersSection(context, controller),
                  const SizedBox(height: TSizes.spaceBtwSections),
                ],

                // Terms & Conditions
                _buildTermsCard(context),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRewardsCard(BuildContext context, ReferralController controller) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              TColors.primary,
              TColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(TSizes.lg),
        child: Column(
          children: [
            // Icon and Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.gift,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: TSizes.md),
                Text(
                  'Refer a Friend',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.md),

            Text(
              'Share the love and earn rewards!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
            ),
            const SizedBox(height: TSizes.lg),

            // Reward Amounts
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '₹${ReferralService.instance.referrerReward.toInt()}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: TSizes.xs),
                        Text(
                          'You Earn',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '₹${ReferralService.instance.refereeReward.toInt()}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: TSizes.xs),
                        Text(
                          'Friend Gets',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard(BuildContext context, ReferralController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Referral Code',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: TSizes.md),

            // Referral Code Display
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: TColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.tag,
                    color: TColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: TSizes.sm),
                  Expanded(
                    child: Obx(() => Text(
                          controller.referralCode.value.isEmpty
                              ? 'Loading...'
                              : controller.referralCode.value,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: TColors.primary,
                              ),
                        )),
                  ),
                  IconButton(
                    onPressed: controller.copyReferralCode,
                    icon: Icon(
                      Iconsax.copy,
                      color: TColors.primary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: TColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TSizes.md),

            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.shareReferralCode,
                icon: const Icon(Iconsax.share, size: 20),
                label: const Text('Share with Friends'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSummary(BuildContext context, ReferralController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: TSizes.md),

            // Earnings Grid
            Row(
              children: [
                Expanded(
                  child: _buildEarningTile(
                    context,
                    'Total Referrals',
                    controller.totalReferrals.value.toString(),
                    Iconsax.people,
                    TColors.info,
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: _buildEarningTile(
                    context,
                    'Total Earnings',
                    controller.formatCurrency(controller.totalEarnings.value),
                    Iconsax.wallet_money,
                    TColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.sm),
            Row(
              children: [
                Expanded(
                  child: _buildEarningTile(
                    context,
                    'Pending',
                    controller.formatCurrency(controller.pendingEarnings.value),
                    Iconsax.clock,
                    TColors.warning,
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: _buildEarningTile(
                    context,
                    'Withdrawn',
                    controller.formatCurrency(controller.withdrawnEarnings.value),
                    Iconsax.tick_circle,
                    TColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: TSizes.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TColors.darkerGrey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It Works',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: TSizes.md),

            _buildStep(context, '1', 'Share your referral code', 'Share your unique code with friends and family'),
            _buildStep(context, '2', 'Friend signs up', 'They create an account using your referral code'),
            _buildStep(context, '3', 'Get rewarded', 'Both of you receive rewards in your wallet instantly'),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: TSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TColors.darkerGrey,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferredUsersSection(BuildContext context, ReferralController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Referred Friends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: TSizes.md),

            Obx(() => ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.referredUsers.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = controller.referredUsers[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: TColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Iconsax.user,
                          color: TColors.primary,
                        ),
                      ),
                      title: Text(
                        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      subtitle: Text(
                        'Joined ${controller.formatDate(user['completedAt'])}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TSizes.sm,
                          vertical: TSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: TColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${(user['rewardAmount'] ?? 0).toInt()}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: TColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.info_circle, color: TColors.primary, size: 20),
                const SizedBox(width: TSizes.sm),
                Text(
                  'Terms & Conditions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.md),
            Text(
              '• Both you and your friend will receive ₹${ReferralService.instance.referrerReward.toInt()} when they sign up using your code\n'
              '• Rewards are credited instantly to your wallet\n'
              '• There is no limit on referrals\n'
              '• Referral code is unique to each user\n'
              '• Rewards can be used for purchases on the app',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TColors.darkerGrey,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

