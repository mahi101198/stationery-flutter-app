import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/data/services/user_service.dart';
import 'package:rps_stationery/features/personalization/controllers/theme_controller.dart';
import 'package:rps_stationery/features/personalization/screens/address/address_list_page.dart';
import 'package:rps_stationery/features/personalization/screens/faq_screen.dart';
import 'package:rps_stationery/features/personalization/screens/get_help_screen.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';
import 'package:rps_stationery/utils/constants/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = Get.find<UserService>();
  double _walletBalance = 0.0;
  bool _isLoadingWallet = true;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _walletBalance = user.walletBalance;
          _isLoadingWallet = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingWallet = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWallet = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? TColors.backgroundDark : Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? TColors.surfaceDark : TColors.surfaceLight,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Profile',
          style: DesignSystem.typography.headlineMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(DesignSystem.spacing.lg),
        children: [
          // User Info Card
          _buildUserInfoCard(context, isDark),
          
          SizedBox(height: DesignSystem.spacing.xl),
          
          // Account Section
          _buildSectionTitle(context, 'Account'),
          SizedBox(height: DesignSystem.spacing.md),
          _buildMenuCard(
            context,
            isDark,
            items: [
              _MenuItem(
                icon: Iconsax.wallet_3,
                title: 'My Wallet',
                onTap: () async {
                  await Get.toNamed(Routes.wallet);
                  _loadWalletBalance();
                },
                trailing: _isLoadingWallet 
                    ? Text('...', style: DesignSystem.typography.bodyMedium)
                    : Text(
                        '₹${_walletBalance.toStringAsFixed(0)}',
                        style: DesignSystem.typography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
              ),
              _MenuItem(
                icon: Iconsax.bag_tick,
                title: 'Orders',
                onTap: () => Get.toNamed(Routes.order),
              ),
              _MenuItem(
                icon: Iconsax.safe_home,
                title: 'Addresses',
                onTap: () => Get.to(() => AddressListPage()),
              ),
              _MenuItem(
                icon: Iconsax.notification,
                title: 'Notifications',
                onTap: () => Get.toNamed(Routes.notification),
              ),
              _MenuItem(
                icon: Iconsax.gift,
                title: 'Refer & Earn',
                onTap: () => Get.toNamed(Routes.referEarn),
              ),
            ],
          ),
          
          SizedBox(height: DesignSystem.spacing.xl),
          
          // Settings Section
          _buildSectionTitle(context, 'Settings'),
          SizedBox(height: DesignSystem.spacing.md),
          _buildMenuCard(
            context,
            isDark,
            items: [
              _MenuItem(
                icon: Iconsax.moon,
                title: 'Theme',
                onTap: () => _showThemeDialog(context),
                trailing: Obx(() {
                  final themeController = Get.find<ThemeController>();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        themeController.themeIcon,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: DesignSystem.spacing.xs),
                      Text(
                        themeController.themeModeDisplayName,
                        style: DesignSystem.typography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              _MenuItem(
                icon: Iconsax.headphone,
                title: 'Help & Support',
                onTap: () => Get.to(() => const GetHelpScreen()),
              ),
              _MenuItem(
                icon: Iconsax.info_circle,
                title: 'About',
                onTap: () => Get.toNamed(Routes.aboutApp),
              ),
            ],
          ),
          
          SizedBox(height: DesignSystem.spacing.xl),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showLogoutDialog(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: DesignSystem.spacing.md),
                side: BorderSide(
                  color: TColors.error,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: DesignSystem.borders.md,
                ),
              ),
              child: Text(
                'Logout',
                style: DesignSystem.typography.bodyLarge.copyWith(
                  color: TColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          SizedBox(height: DesignSystem.spacing.xl),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, bool isDark) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      AuthRepository.instance.screenRedirect();
      return Container();
    }

    return Container(
      padding: EdgeInsets.all(DesignSystem.spacing.lg),
      decoration: BoxDecoration(
        color: isDark ? TColors.surfaceDark : TColors.surfaceLight,
        borderRadius: DesignSystem.borders.md,
        border: Border.all(
          color: TColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: TColors.borderPrimary,
                width: 1,
              ),
            ),
            child: ClipOval(
              child: user.photoURL != null
                  ? CachedNetworkImage(
                      imageUrl: user.photoURL!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          Iconsax.user,
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        Iconsax.user,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ),
          ),

          SizedBox(width: DesignSystem.spacing.md),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'User',
                  style: DesignSystem.typography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: DesignSystem.spacing.xs / 2),
                Text(
                  user.email ?? '',
                  style: DesignSystem.typography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: DesignSystem.typography.titleMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    bool isDark, {
    required List<_MenuItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? TColors.surfaceDark : TColors.surfaceLight,
        borderRadius: DesignSystem.borders.md,
        border: Border.all(
          color: TColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? Radius.circular(12) : Radius.zero,
                  bottom: isLast ? Radius.circular(12) : Radius.zero,
                ),
                child: Padding(
                  padding: EdgeInsets.all(DesignSystem.spacing.md),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      SizedBox(width: DesignSystem.spacing.md),
                      Expanded(
                        child: Text(
                          item.title,
                          style: DesignSystem.typography.bodyLarge.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (item.trailing != null)
                        item.trailing!
                      else
                        Icon(
                          Iconsax.arrow_right_3,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: DesignSystem.spacing.md + 20 + DesignSystem.spacing.md,
                  endIndent: DesignSystem.spacing.md,
                  color: TColors.borderPrimary,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: DesignSystem.borders.lg,
        ),
        child: Padding(
          padding: EdgeInsets.all(DesignSystem.spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Theme',
                style: DesignSystem.typography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: DesignSystem.spacing.lg),

              // Theme options
              _ThemeOption(
                title: 'Light Mode',
                icon: Icons.light_mode,
                isSelected: themeController.themeMode == ThemeMode.light && !themeController.followSystem,
                onTap: () {
                  themeController.setLightMode();
                  Get.back();
                },
              ),
              SizedBox(height: DesignSystem.spacing.md),
              _ThemeOption(
                title: 'Dark Mode',
                icon: Icons.dark_mode,
                isSelected: themeController.themeMode == ThemeMode.dark && !themeController.followSystem,
                onTap: () {
                  themeController.setDarkMode();
                  Get.back();
                },
              ),
              SizedBox(height: DesignSystem.spacing.md),
              _ThemeOption(
                title: 'System Default',
                icon: Icons.brightness_auto,
                isSelected: themeController.followSystem,
                onTap: () {
                  themeController.setSystemMode();
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: DesignSystem.borders.lg,
        ),
        child: Padding(
          padding: EdgeInsets.all(DesignSystem.spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.logout_1,
                size: 48,
                color: TColors.error,
              ),
              SizedBox(height: DesignSystem.spacing.md),
              Text(
                'Logout',
                style: DesignSystem.typography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: DesignSystem.spacing.sm),
              Text(
                'Are you sure you want to logout?',
                style: DesignSystem.typography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignSystem.spacing.lg),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: DesignSystem.spacing.md),
                        side: BorderSide(
                          color: TColors.borderPrimary,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: DesignSystem.borders.md,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: DesignSystem.typography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: DesignSystem.spacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        AuthRepository.instance.signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.error,
                        padding: EdgeInsets.symmetric(vertical: DesignSystem.spacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: DesignSystem.borders.md,
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: DesignSystem.typography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: DesignSystem.borders.md,
      child: Container(
        padding: EdgeInsets.all(DesignSystem.spacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : TColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: DesignSystem.borders.md,
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            SizedBox(width: DesignSystem.spacing.md),
            Text(
              title,
              style: DesignSystem.typography.bodyLarge.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });
}
