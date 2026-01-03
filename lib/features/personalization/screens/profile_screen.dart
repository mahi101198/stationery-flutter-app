import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rps_stationery/components/ui/modern_ui.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/data/services/user_service.dart';
import 'package:rps_stationery/features/personalization/controllers/theme_controller.dart';
import 'package:rps_stationery/features/personalization/screens/address/address_list_page.dart';
import 'package:rps_stationery/features/personalization/screens/faq_screen.dart';
import 'package:rps_stationery/features/personalization/screens/get_help_screen.dart';
import 'package:rps_stationery/routes/app_pages.dart';

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
      // Error loading wallet balance - continue with default value
      if (mounted) {
        setState(() => _isLoadingWallet = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Modern Header with SliverAppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 16,
                  20,
                  16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.03),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Profile',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Iconsax.user,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Account Settings',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Profile Avatar in Header
                        _buildHeaderAvatar(context),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // User Info Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildUserInfoCard(context),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Account Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildModernSection(
                context,
                title: "Account",
                items: [
                  _ModernSettingsItem(
                    icon: Iconsax.wallet_3,
                    title: "My Wallet",
                    subtitle: "View balance and transactions",
                    onTap: () async {
                      await Get.toNamed(Routes.wallet);
                      // Refresh wallet balance when returning from wallet screen
                      _loadWalletBalance();
                    },
                    badge: _isLoadingWallet ? "..." : "₹${_walletBalance.toStringAsFixed(0)}",
                  ),
                  _ModernSettingsItem(
                    icon: Iconsax.gift,
                    title: "Refer & Earn",
                    subtitle: "Invite friends and earn rewards",
                    onTap: () => Get.toNamed(Routes.referEarn),
                    badge: "Earn",
                  ),
                  _ModernSettingsItem(
                    icon: Iconsax.safe_home,
                    title: "My Addresses",
                    subtitle: "Manage shipping addresses",
                    onTap: () => Get.to(() => AddressListPage()),
                  ),
                  _ModernSettingsItem(
                    icon: Iconsax.bag_tick,
                    title: "Order History",
                    subtitle: "View past orders",
                    onTap: () => Get.toNamed(Routes.order),
                  ),
                  _ModernSettingsItem(
                    icon: Iconsax.notification,
                    title: "Notifications",
                    subtitle: "Manage notification preferences",
                    onTap: () => Get.toNamed(Routes.notification),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Help & Support Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildModernSection(
                context,
                title: "Help & Support",
                items: [
                  _ModernSettingsItem(
                    icon: Iconsax.headphone,
                    title: "Get Help",
                    subtitle: "Contact customer support",
                    onTap: () => Get.to(() => const GetHelpScreen()),
                  ),
                  _ModernSettingsItem(
                    icon: Iconsax.message_question,
                    title: "FAQs",
                    subtitle: "Frequently asked questions",
                    onTap: () => Get.to(() => const FAQScreen()),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // App Settings Section  
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildModernSection(
                context,
                title: "App Settings",
                items: [
                  _ModernSettingsItem(
                    icon: Iconsax.moon,
                    title: "Theme",
                    subtitle: "Switch between light and dark mode",
                    onTap: () => _showThemeDialog(context),
                    customTrailing: Obx(() {
                      final themeController = Get.find<ThemeController>();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              themeController.themeIcon,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              themeController.themeModeDisplayName,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  _ModernSettingsItem(
                    icon: Iconsax.info_circle,
                    title: "About App",
                    subtitle: "Version, terms and privacy",
                    onTap: () => Get.toNamed(Routes.aboutApp),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Logout Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: ThemeAwareButton(
                text: "Logout",
                variant: ButtonVariant.danger,
                size: ButtonSize.large,
                icon: Iconsax.logout,
                fullWidth: true,
                onPressed: () => _showLogoutDialog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Header Avatar
  Widget _buildHeaderAvatar(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: user?.photoURL != null
            ? CachedNetworkImage(
                imageUrl: user!.photoURL!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => ModernSkeleton.circle(size: 50),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.user,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.user,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
              ),
      ),
    );
  }

  // User Info Card
  Widget _buildUserInfoCard(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      AuthRepository.instance.screenRedirect();
      return Container();
    }

    return ThemeAwareCard(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profile Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: user.photoURL != null
                    ? CachedNetworkImage(
                        imageUrl: user.photoURL!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => ModernSkeleton.circle(size: 70),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.user,
                            size: 35,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.user,
                          size: 35,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'User',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (user.emailVerified) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Iconsax.verify5,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Account',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Edit button
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () {
                  // TODO: Navigate to edit profile
                },
                icon: Icon(
                  Iconsax.edit,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Modern Section Builder
  Widget _buildModernSection(BuildContext context, {
    required String title,
    required List<_ModernSettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        ThemeAwareCard(
          elevation: 2,
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              
              return Column(
                children: [
                  _buildModernSettingsTile(context, item),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSettingsTile(BuildContext context, _ModernSettingsItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Badge or Trailing
            if (item.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.badge!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (item.customTrailing != null)
              item.customTrailing!
            else
              Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
  
  void _showThemeDialog(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.paintbucket,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Choose Theme',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Theme options
              _ThemeOption(
                title: 'Light Mode',
                subtitle: 'Bright and clean interface',
                icon: Icons.light_mode,
                isSelected: themeController.themeMode == ThemeMode.light && !themeController.followSystem,
                onTap: () {
                  themeController.setLightMode();
                  Get.back();
                },
              ),
              const SizedBox(height: 12),
              _ThemeOption(
                title: 'Dark Mode',
                subtitle: 'Easy on the eyes',
                icon: Icons.dark_mode,
                isSelected: themeController.themeMode == ThemeMode.dark && !themeController.followSystem,
                onTap: () {
                  themeController.setDarkMode();
                  Get.back();
                },
              ),
              const SizedBox(height: 12),
              _ThemeOption(
                title: 'System Default',
                subtitle: 'Follow device settings',
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
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.logout_1,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Logout Confirmation',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout?\nYou will need to sign in again to access your account.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: ThemeAwareButton(
                      text: 'Cancel',
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.medium,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ThemeAwareButton(
                      text: 'Logout',
                      variant: ButtonVariant.danger,
                      size: ButtonSize.medium,
                      onPressed: () {
                        Get.back();
                        AuthRepository.instance.signOut();
                      },
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
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _ModernSettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? customTrailing;
  final String? badge;

  _ModernSettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.customTrailing,
    this.badge,
  });
}
