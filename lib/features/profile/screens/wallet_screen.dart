import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/data/services/user_service.dart';
import 'package:rps_stationery/utils/constants/colors.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final UserService _userService = Get.find<UserService>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  
  double _walletBalance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    try {
      setState(() => _isLoading = true);
      
      final userId = _authRepository.currentUser?.uid;
      if (userId != null) {
        final user = await _userService.getCurrentUser();
        if (user != null) {
          setState(() {
            _walletBalance = user.walletBalance;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading wallet balance: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWalletBalance,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    _buildBalanceCard(context),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // Quick Actions
                    _buildQuickActions(context),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // How to Use Wallet
                    _buildHowToUse(context),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // Benefits Card
                    _buildBenefitsCard(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Icon and Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.wallet_3,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: TSizes.md),
                Text(
                  'Wallet Balance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.lg),

            // Balance Amount
            Text(
              '₹${_walletBalance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: TSizes.xs),
            Text(
              'Available Balance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: TSizes.md),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Refer & Earn',
                'Get ₹50 for each referral',
                Iconsax.gift,
                TColors.success,
                () {
                  Get.toNamed('/refer-earn');
                },
              ),
            ),
            const SizedBox(width: TSizes.sm),
            Expanded(
              child: _buildActionCard(
                context,
                'Use Wallet',
                'Pay with wallet balance',
                Iconsax.shopping_cart,
                TColors.info,
                () {
                  Get.back(); // Go to shop
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(TSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: TSizes.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: TSizes.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TColors.darkerGrey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowToUse(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to Use Wallet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: TSizes.md),

            _buildHowToStep(
              context,
              '1',
              'Add Money',
              'Earn wallet balance through referrals and cashback offers',
            ),
            _buildHowToStep(
              context,
              '2',
              'Shop',
              'Browse and add products to your cart',
            ),
            _buildHowToStep(
              context,
              '3',
              'Pay with Wallet',
              'Use your wallet balance during checkout to save money',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToStep(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
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

  Widget _buildBenefitsCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.medal_star, color: TColors.primary, size: 24),
                const SizedBox(width: TSizes.sm),
                Text(
                  'Wallet Benefits',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.md),

            _buildBenefitItem(
              context,
              'Instant Payments',
              'Pay quickly without entering card details',
              Iconsax.flash_1,
            ),
            _buildBenefitItem(
              context,
              'No Expiry',
              'Your wallet balance never expires',
              Iconsax.calendar,
            ),
            _buildBenefitItem(
              context,
              'Secure',
              'Your money is safe and secure with us',
              Iconsax.shield_tick,
            ),
            _buildBenefitItem(
              context,
              'Track Easily',
              'Monitor all your transactions in one place',
              Iconsax.chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: TColors.primary, size: 20),
          ),
          const SizedBox(width: TSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
}

