import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Policy'),
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
              
              // Refund Content
              _buildRefundContent(context),
              
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
              Iconsax.money_send,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: DesignSystem.spacing.md),
            Text(
              'Refund Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignSystem.spacing.sm),
            Text(
              'Fair and transparent refund process for your peace of mind',
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

  Widget _buildRefundContent(BuildContext context) {
    return ThemeAwareCard(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: '1. Refund Eligibility',
              content: 'We offer refunds for the following circumstances:\n\n• Defective or damaged products upon delivery\n• Products that do not match the description or images\n• Wrong items delivered due to our error\n• Products lost in transit (after investigation)\n• Cancellation of orders before shipment\n• Duplicate orders placed by mistake\n\nRefunds are processed within 7-10 business days after approval.',
            ),
            
            _buildSection(
              context,
              title: '2. Return Timeframe',
              content: '• Standard Products: 7 days from delivery date\n• Electronics/Precision Items: 3 days from delivery date\n• Customized/Personalized Items: No returns accepted\n• Seasonal/Special Edition Items: 3 days from delivery date\n\nReturns must be initiated within the specified timeframe. Late return requests will be evaluated on a case-by-case basis.',
            ),
            
            _buildSection(
              context,
              title: '3. Return Conditions',
              content: 'To be eligible for a refund, items must be:\n\n• In original, unused condition\n• With original packaging and tags\n• Accompanied by original invoice/receipt\n• Not damaged by customer mishandling\n• Complete with all accessories and components\n\nItems showing signs of use, damage, or missing components may be subject to partial refund or rejection.',
            ),
            
            _buildSection(
              context,
              title: '4. Non-Refundable Items',
              content: 'The following items are not eligible for returns or refunds:\n\n• Customized or personalized products\n• Items damaged by customer misuse\n• Products returned after the specified timeframe\n• Items without original packaging\n• Digital products or downloadable content\n• Gift cards and promotional vouchers\n• Items purchased during clearance sales (unless defective)\n• Hygiene-sensitive products (opened)\n• Items specifically marked as non-returnable',
            ),
            
            _buildSection(
              context,
              title: '5. Return Process',
              content: 'To initiate a return:\n\n1. Contact our customer support within the return timeframe\n2. Provide order number and reason for return\n3. Receive return authorization and instructions\n4. Package items securely in original packaging\n5. Ship items to our return address\n6. Wait for inspection and approval\n7. Receive refund to original payment method\n\nReturn shipping costs are covered by RPS Shopee for defective or incorrect items. For other returns, customers bear the return shipping cost.',
            ),
            
            _buildSection(
              context,
              title: '6. Refund Methods',
              content: 'Refunds will be processed using the same payment method used for the original purchase:\n\n• Credit/Debit Cards: 5-7 business days\n• UPI Payments: 2-3 business days\n• Net Banking: 3-5 business days\n• Digital Wallets: 2-4 business days\n• Cash on Delivery: Bank transfer (7-10 business days)\n\nRefunds to bank accounts may take additional time depending on your bank\'s processing time.',
            ),
            
            _buildSection(
              context,
              title: '7. Partial Refunds',
              content: 'Partial refunds may be issued in the following cases:\n\n• Items returned in less than perfect condition\n• Missing accessories or components\n• Customer-caused damage\n• Items used beyond reasonable trial period\n• Partial order cancellations\n\nThe refund amount will be calculated based on the condition of returned items and any applicable restocking fees.',
            ),
            
            _buildSection(
              context,
              title: '8. Exchange Policy',
              content: 'We offer exchanges for:\n\n• Wrong size or color (subject to availability)\n• Defective items (replacement with same product)\n• Items that don\'t meet expectations (size/color only)\n\nExchange requests must be made within the return timeframe. Customers are responsible for return shipping costs unless the exchange is due to our error. New items will be shipped once the original items are received and approved.',
            ),
            
            _buildSection(
              context,
              title: '9. Cancellation Policy',
              content: 'Order cancellations are accepted under the following conditions:\n\n• Before order processing: Full refund within 24 hours\n• During processing: Refund minus processing fees\n• After shipment: Standard return policy applies\n• Custom orders: Cancellation not allowed once production begins\n\nTo cancel an order, contact customer support immediately with your order number.',
            ),
            
            _buildSection(
              context,
              title: '10. Refund Timeline',
              content: 'Our refund processing timeline:\n\n• Return request review: 1-2 business days\n• Return shipping (if applicable): 3-5 business days\n• Item inspection: 1-2 business days\n• Refund processing: 1-3 business days\n• Bank processing: 2-7 business days\n\nTotal time: 7-15 business days from return approval to refund credit.',
            ),
            
            _buildSection(
              context,
              title: '11. Dispute Resolution',
              content: 'If you disagree with our refund decision:\n\n• Contact our customer support for review\n• Provide additional documentation if needed\n• Escalate to management if necessary\n• We will provide detailed explanation for any rejection\n• External mediation available for unresolved disputes\n\nWe are committed to fair resolution of all refund disputes.',
            ),
            
            _buildSection(
              context,
              title: '12. Special Circumstances',
              content: 'We understand that special circumstances may arise:\n\n• Natural disasters affecting delivery\n• Medical emergencies preventing return\n• Military deployment or relocation\n• Product recalls or safety issues\n\nContact us to discuss your specific situation. We will work with you to find an appropriate solution.',
            ),
            
            _buildSection(
              context,
              title: '13. Contact Information',
              content: 'For refund-related inquiries:\n\nEmail: refunds@rpsstationery.com\nPhone: +91-XXXXXXXXXX\nWhatsApp: +91-XXXXXXXXXX\n\nCustomer Support Hours: Monday to Saturday, 9 AM to 6 PM\nResponse Time: Within 24 hours for email, immediate for phone calls',
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
