import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
              
              // Terms Content
              _buildTermsContent(context),
              
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
              Iconsax.document_text,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: DesignSystem.spacing.md),
            Text(
              'Terms & Conditions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignSystem.spacing.sm),
            Text(
              'Please read these terms carefully before using our service',
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

  Widget _buildTermsContent(BuildContext context) {
    return ThemeAwareCard(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: '1. Acceptance of Terms',
              content: 'By accessing and using the RPS Shopee mobile application ("App"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            
            _buildSection(
              context,
              title: '2. Use License',
              content: 'Permission is granted to temporarily download one copy of the RPS Shopee app for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose or for any public display\n• Attempt to reverse engineer any software contained in the app\n• Remove any copyright or other proprietary notations from the materials',
            ),
            
            _buildSection(
              context,
              title: '3. User Accounts',
              content: 'To access certain features of the App, you may be required to create an account. You are responsible for:\n\n• Maintaining the confidentiality of your account credentials\n• All activities that occur under your account\n• Notifying us immediately of any unauthorized use\n• Providing accurate and complete information during registration',
            ),
            
            _buildSection(
              context,
              title: '4. Product Information',
              content: 'We strive to provide accurate product descriptions, images, and pricing. However, we do not warrant that product descriptions or other content is accurate, complete, reliable, current, or error-free. Product images are for illustrative purposes only.',
            ),
            
            _buildSection(
              context,
              title: '5. Orders and Payment',
              content: 'All orders are subject to acceptance and availability. We reserve the right to refuse or cancel any order for any reason. Payment must be received before order processing. We accept various payment methods including UPI, credit/debit cards, and digital wallets.',
            ),
            
            _buildSection(
              context,
              title: '6. Delivery and Shipping',
              content: 'Delivery times are estimates and may vary. We are not responsible for delays caused by third-party delivery services or circumstances beyond our control. Risk of loss and title for products purchased pass to you upon delivery.',
            ),
            
            _buildSection(
              context,
              title: '7. Returns and Refunds',
              content: 'Returns are subject to our Refund Policy. Items must be returned in original condition within the specified timeframe. Customized or personalized items may not be eligible for return. Refunds will be processed to the original payment method.',
            ),
            
            _buildSection(
              context,
              title: '8. Prohibited Uses',
              content: 'You may not use our App:\n\n• For any unlawful purpose or to solicit others to perform unlawful acts\n• To violate any international, federal, provincial, or state regulations, rules, laws, or local ordinances\n• To infringe upon or violate our intellectual property rights or the intellectual property rights of others\n• To harass, abuse, insult, harm, defame, slander, disparage, intimidate, or discriminate\n• To submit false or misleading information',
            ),
            
            _buildSection(
              context,
              title: '9. Privacy Policy',
              content: 'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the App, to understand our practices.',
            ),
            
            _buildSection(
              context,
              title: '10. Intellectual Property',
              content: 'The App and its original content, features, and functionality are and will remain the exclusive property of RPS Shopee and its licensors. The App is protected by copyright, trademark, and other laws.',
            ),
            
            _buildSection(
              context,
              title: '11. Disclaimer',
              content: 'The information on this App is provided on an "as is" basis. To the fullest extent permitted by law, RPS Shopee excludes all representations, warranties, conditions and terms relating to our App and the use of this App.',
            ),
            
            _buildSection(
              context,
              title: '12. Limitation of Liability',
              content: 'In no event shall RPS Shopee, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.',
            ),
            
            _buildSection(
              context,
              title: '13. Termination',
              content: 'We may terminate or suspend your account and bar access to the App immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms.',
            ),
            
            _buildSection(
              context,
              title: '14. Changes to Terms',
              content: 'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect.',
            ),
            
            _buildSection(
              context,
              title: '15. Contact Information',
              content: 'If you have any questions about these Terms & Conditions, please contact us at:\n\nEmail: support@rpsstationery.com\nPhone: +91-XXXXXXXXXX\nAddress: [Your Business Address]',
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
