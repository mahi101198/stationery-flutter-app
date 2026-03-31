import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';
import 'package:rps_stationery/features/personalization/screens/legal_documents/terms_conditions_screen.dart';
import 'package:rps_stationery/features/personalization/screens/legal_documents/privacy_policy_screen.dart';
import 'package:rps_stationery/features/personalization/screens/legal_documents/refund_policy_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rps_stationery/services/app_settings_service.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String appVersion = '1.0.0';
  String buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(DesignSystem.spacing.lg),
          child: Column(
            children: [
              // App Logo and Info
              _buildAppInfoCard(context),
              
              SizedBox(height: DesignSystem.spacing.lg),
              
              // Legal Documents Section
              _buildSection(
                context,
                title: "Legal Documents",
                items: [
                  _SettingsItem(
                    null,
                    icon: Iconsax.document_text,
                    title: "Terms & Conditions",
                    subtitle: "Read our terms of service",
                    onTap: () => Get.to(() => const TermsConditionsScreen()),
                  ),
                  _SettingsItem(
                    null,
                    icon: Iconsax.shield_tick,
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    onTap: () => Get.to(() => const PrivacyPolicyScreen()),
                  ),
                  _SettingsItem(
                    null,
                    icon: Iconsax.money_send,
                    title: "Refund Policy",
                    subtitle: "Our refund and return policy",
                    onTap: () => Get.to(() => const RefundPolicyScreen()),
                  ),
                ],
              ),
              
              SizedBox(height: DesignSystem.spacing.lg),
              
              // App Information Section
              _buildSection(
                context,
                title: "App Information",
                items: [
                  _SettingsItem(
                    null,
                    icon: Iconsax.info_circle,
                    title: "Version",
                    subtitle: "v$appVersion (Build $buildNumber)",
                    onTap: () {},
                  ),
                  _SettingsItem(
                    null,
                    icon: Iconsax.calendar,
                    title: "Last Updated",
                    subtitle: "December 2024",
                    onTap: () {},
                  ),
                  _SettingsItem(
                    null,
                    icon: Iconsax.code,
                    title: "Developer",
                    subtitle: "RPS Shopee Team",
                    onTap: () {},
                  ),
                ],
              ),
              
              SizedBox(height: DesignSystem.spacing.xl),
              
              // Copyright Notice
              _buildCopyrightNotice(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return ThemeAwareCard(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.spacing.lg),
        child: Column(
          children: [
            // App Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: DesignSystem.shadows.elevation2,
              ),
              child: Icon(
                Iconsax.shop,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            SizedBox(height: DesignSystem.spacing.md),
            
            // App Name
            Obx(() {
              final appName = AppSettingsService.instance.appName;
              return Text(
                appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            }),
            
            SizedBox(height: DesignSystem.spacing.sm),
            
            // App Description
            Text(
              'Your one-stop destination for stationery, household essentials, and more — delivered right to your doorstep.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: DesignSystem.spacing.md),
            
            // Version Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignSystem.spacing.md,
                vertical: DesignSystem.spacing.sm,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version $appVersion',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<_SettingsItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DesignSystem.spacing.md),
        
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
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(DesignSystem.spacing.sm),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: DesignSystem.borders.md,
                      ),
                      child: Icon(
                        item.icon,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                    trailing: item.customTrailing ?? Icon(
                      Iconsax.arrow_right_3,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: item.onTap,
                  ),
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

  Widget _buildCopyrightNotice(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.copyright,
            size: 24,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: DesignSystem.spacing.sm),
          Obx(() {
            final appName = AppSettingsService.instance.appName;
            return Text(
              '© 2024 $appName',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }),
          SizedBox(height: DesignSystem.spacing.xs),
          Text(
            'All rights reserved',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? customTrailing;

  _SettingsItem(this.customTrailing, {
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
