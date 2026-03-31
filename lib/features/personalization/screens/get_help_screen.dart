import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rps_stationery/constants.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/services/app_settings_service.dart';

class GetHelpScreen extends StatelessWidget {
  const GetHelpScreen({super.key});

  // These will be loaded from app settings
  String get phoneNumber => AppSettingsService.instance.supportPhone;
  String get whatsAppNumber => AppSettingsService.instance.supportPhone;
  String get emailAddress => AppSettingsService.instance.supportEmail;

  final String address = 'C-34, Lajpat Marg, C Scheme, Ashok Nagar, Jaipur';
  final String addressUrl = 'https://maps.app.goo.gl/KEPkykWYB3CtPr8aA';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Help'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Iconsax.headphone,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),
                  Text(
                    'We\'re Here to Help!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Choose the best way to reach us. Our support team is ready to assist you with any questions or concerns.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spaceBtwSections),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Iconsax.call,
                    title: 'Call Us',
                    subtitle: 'Speak directly',
                    onTap: () => _makePhoneCall(context),
                  ),
                ),
                const SizedBox(width: AppSizes.spaceBtwItems),
                Expanded(
                  child: _QuickActionCard(
                    icon: Iconsax.message,
                    title: 'WhatsApp',
                    subtitle: 'Chat with us',
                    onTap: () => _openWhatsApp(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.spaceBtwSections),

            // Contact Options
            Text(
              'Contact Options',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),

            _ContactOptionTile(
              icon: Iconsax.call,
              title: 'Phone Support',
              subtitle: phoneNumber,
              description: 'Available Mon-Sat, 10 AM - 8:30 PM',
              onTap: () => _makePhoneCall(context),
            ),

            const SizedBox(height: AppSizes.md),

            _ContactOptionTile(
              icon: Iconsax.sms,
              title: 'Email Support',
              subtitle: emailAddress,
              description: 'Get a reply within 24 hours',
              onTap: () => _sendEmail(context),
            ),

            const SizedBox(height: AppSizes.md),

            _ContactOptionTile(
              icon: Iconsax.message,
              title: 'WhatsApp Chat',
              subtitle: whatsAppNumber,
              description: 'Fast response during business hours',
              onTap: () => _openWhatsApp(context),
            ),

            const SizedBox(height: AppSizes.md),

            _ContactOptionTile(
              icon: Iconsax.location,
              title: 'Visit Our Store',
              subtitle: 'RPS Shopee Main Branch',
              description: address,
              onTap: () => _openMaps(context),
            ),

            const SizedBox(height: AppSizes.spaceBtwSections),

            // Business Hours
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.clock,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        'Business Hours',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),
                  _BusinessHourRow('Monday - Saturday', '10:00 AM - 8:30 PM'),
                  _BusinessHourRow('Sunday', 'Closed'),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  Widget _BusinessHourRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day),
          Text(hours, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _makePhoneCall(BuildContext context) async {
    final uri = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          _copyToClipboard(
            context,
            phoneNumber,
            'Phone number copied to clipboard',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _copyToClipboard(
          context,
          phoneNumber,
          'Phone number copied to clipboard',
        );
      }
    }
  }

  void _sendEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:$emailAddress?subject=Support Request');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          _copyToClipboard(
            context,
            emailAddress,
            'Email address copied to clipboard',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _copyToClipboard(
          context,
          emailAddress,
          'Email address copied to clipboard',
        );
      }
    }
  }

  void _openWhatsApp(BuildContext context) async {
    const message = 'Hi! I need help with my RPS Shopee order.';
    final uri = Uri.parse(
      'https://wa.me/${whatsAppNumber.replaceAll(' ', '').replaceAll('+', '')}?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _copyToClipboard(
            context,
            whatsAppNumber,
            'WhatsApp number copied to clipboard',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _copyToClipboard(
          context,
          whatsAppNumber,
          'WhatsApp number copied to clipboard',
        );
      }
    }
  }

  void _openMaps(BuildContext context) async {
    final uri = Uri.parse(addressUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _copyToClipboard(context, address, 'Address copied to clipboard');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _copyToClipboard(context, address, 'Address copied to clipboard');
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    TLoaders.customToast(message: message);
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactOptionTile extends StatelessWidget {
  const _ContactOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Iconsax.arrow_right_3,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onTap: onTap,
      ),
    );
  }
}
