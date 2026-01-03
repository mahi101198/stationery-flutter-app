import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(DesignSystem.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              
              SizedBox(height: DesignSystem.spacing.lg),
              
              // Privacy Content
              _buildPrivacyContent(context),
              
              SizedBox(height: DesignSystem.spacing.xl),
              
              // Last Updated
              _buildLastUpdated(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ThemeAwareCard(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.spacing.lg),
        child: Column(
          children: [
            Icon(
              Iconsax.shield_tick,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: DesignSystem.spacing.md),
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignSystem.spacing.sm),
            Text(
              'Your privacy and data security are our top priorities',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyContent(BuildContext context) {
    return ThemeAwareCard(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: '1. Information We Collect',
              content: 'We collect information you provide directly to us, such as when you create an account, make a purchase, or contact us for support:\n\n• Personal Information: Name, email address, phone number, shipping address\n• Payment Information: Credit card details, UPI information (processed securely through third-party payment processors)\n• Account Information: Username, password, profile preferences\n• Communication Data: Messages, feedback, and support requests\n• Device Information: Device type, operating system, unique device identifiers\n• Usage Data: App interactions, pages visited, features used',
            ),
            
            _buildSection(
              context,
              title: '2. How We Use Your Information',
              content: 'We use the information we collect to:\n\n• Process and fulfill your orders\n• Provide customer support and respond to inquiries\n• Send order confirmations, shipping updates, and delivery notifications\n• Improve our app functionality and user experience\n• Send promotional offers and marketing communications (with your consent)\n• Prevent fraud and ensure security\n• Comply with legal obligations\n• Analyze usage patterns to enhance our services',
            ),
            
            _buildSection(
              context,
              title: '3. Information Sharing',
              content: 'We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:\n\n• Service Providers: With trusted third-party vendors who assist in app operations (payment processors, delivery services, analytics providers)\n• Legal Requirements: When required by law or to protect our rights and safety\n• Business Transfers: In connection with a merger, acquisition, or sale of assets\n• Consent: When you explicitly consent to sharing your information\n\nAll third-party service providers are contractually obligated to protect your information and use it only for the purposes we specify.',
            ),
            
            _buildSection(
              context,
              title: '4. Data Security',
              content: 'We implement industry-standard security measures to protect your personal information:\n\n• Encryption: All sensitive data is encrypted in transit and at rest\n• Secure Servers: Data is stored on secure, monitored servers\n• Access Controls: Limited access to personal information on a need-to-know basis\n• Regular Audits: Security practices are regularly reviewed and updated\n• Payment Security: Payment information is processed through PCI DSS compliant systems\n\nHowever, no method of transmission over the internet or electronic storage is 100% secure. While we strive to protect your information, we cannot guarantee absolute security.',
            ),
            
            _buildSection(
              context,
              title: '5. Data Retention',
              content: 'We retain your personal information for as long as necessary to:\n\n• Provide our services to you\n• Comply with legal obligations\n• Resolve disputes and enforce agreements\n• Improve our services\n\nAccount information is retained while your account is active. Order information is retained for accounting and legal purposes. You may request deletion of your account and associated data at any time.',
            ),
            
            _buildSection(
              context,
              title: '6. Your Rights and Choices',
              content: 'You have the following rights regarding your personal information:\n\n• Access: Request a copy of the personal information we hold about you\n• Correction: Update or correct inaccurate information\n• Deletion: Request deletion of your personal information\n• Portability: Receive your data in a structured, machine-readable format\n• Opt-out: Unsubscribe from marketing communications\n• Restriction: Request limitation of processing in certain circumstances\n\nTo exercise these rights, contact us at privacy@rpsstationery.com. We will respond to your request within 30 days.',
            ),
            
            _buildSection(
              context,
              title: '7. Cookies and Tracking',
              content: 'Our app may use cookies and similar tracking technologies to:\n\n• Remember your preferences and settings\n• Analyze app usage and performance\n• Provide personalized content and recommendations\n• Improve user experience\n\nYou can control cookie settings through your device preferences. Disabling cookies may affect app functionality.',
            ),
            
            _buildSection(
              context,
              title: '8. Third-Party Services',
              content: 'Our app integrates with third-party services that have their own privacy policies:\n\n• Payment Processors (Razorpay, UPI): Handle payment transactions securely\n• Analytics Services: Help us understand app usage and improve performance\n• Push Notification Services: Deliver notifications about orders and promotions\n• Social Media Platforms: Enable social login and sharing features\n\nWe encourage you to review the privacy policies of these third-party services.',
            ),
            
            _buildSection(
              context,
              title: '9. Children\'s Privacy',
              content: 'Our app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.',
            ),
            
            _buildSection(
              context,
              title: '10. International Data Transfers',
              content: 'Your information may be transferred to and processed in countries other than your own. We ensure that such transfers comply with applicable data protection laws and implement appropriate safeguards to protect your information.',
            ),
            
            _buildSection(
              context,
              title: '11. Changes to Privacy Policy',
              content: 'We may update this Privacy Policy from time to time. We will notify you of any material changes by:\n\n• Posting the updated policy in the app\n• Sending an email notification\n• Displaying a prominent notice in the app\n\nYour continued use of the app after changes become effective constitutes acceptance of the updated policy.',
            ),
            
            _buildSection(
              context,
              title: '12. Contact Us',
              content: 'If you have any questions about this Privacy Policy or our data practices, please contact us:\n\nEmail: privacy@rpsstationery.com\nPhone: +91-XXXXXXXXXX\nAddress: [Your Business Address]\n\nData Protection Officer: dpo@rpsstationery.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignSystem.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignSystem.spacing.sm),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.calendar,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: DesignSystem.spacing.sm),
          Text(
            'Last updated: December 2024',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
