import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/constants.dart';
import 'package:rps_stationery/features/personalization/screens/get_help_screen.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  int? expandedIndex;

  final List<FAQItem> faqs = [
    FAQItem(
      question: "How do I place an order?",
      answer:
          "Simply browse through our products, add items to your cart, and proceed to checkout. You can pay using UPI or credit/debit cards.",
    ),
    FAQItem(
      question: "What are your delivery charges?",
      answer:
          "We offer free delivery on orders above ₹500. For orders below ₹500, delivery charges are ₹50 within the jaipur city.",
    ),
    FAQItem(
      question: "How long does delivery take?",
      answer:
          "Standard delivery takes 2-3 business days within the Jaipur city. Currently we deliver inside Jaipur city only.",
    ),
    FAQItem(
      question: "Can I cancel my order?",
      answer:
          "Yes, you can cancel your order hasn't been dispatched. You can contact our support to cancel the order. Refunds will be processed within 3-5 business days.",
    ),
    FAQItem(
      question: "What payment methods do you accept?",
      answer:
          "We accept all form of online payments. We accept UPI payments, credit/debit cards and net banking.",
    ),
    FAQItem(
      question: "Do you offer bulk discounts?",
      answer:
          "Yes! We offer special discounts for bulk orders above ₹5,000. Contact our customer support for custom quotes on large quantity purchases.",
    ),
    FAQItem(
      question: "How can I track my order?",
      answer:
          "Once your order is dispatched, you'll receive a tracking link via SMS and email.",
    ),
    FAQItem(
      question: "Do you deliver to my area?",
      answer:
          "We deliver Jaipur Only . During checkout, add your address to check delivery availability and estimated delivery time for your area.",
    ),
    FAQItem(
      question: "What if I receive a damaged item?",
      answer:
          "Contact our customer support immediately with photos of the damaged item. We'll arrange for a replacement or full refund within 24 hours.",
    ),
    FAQItem(
      question: "How can I contact customer support?",
      answer:
          "You can reach us through the 'Get Help' section in the app, email us at support@rpsstationery.com, or call our helpline during business hours (9 AM - 7 PM).",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
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
                    Iconsax.message_question,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),
                  Text(
                    'Got Questions?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Find answers to the most commonly asked questions from us.',
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

            // FAQ List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faqs.length,
              separatorBuilder:
                  (context, index) => const SizedBox(height: AppSizes.sm),
              itemBuilder: (context, index) {
                final isExpanded = expandedIndex == index;
                return FAQTile(
                  faq: faqs[index],
                  isExpanded: isExpanded,
                  onTap: () {
                    setState(() {
                      expandedIndex = isExpanded ? null : index;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: AppSizes.spaceBtwSections),

            // Contact support section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Iconsax.headphone,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),
                  Text(
                    "Still need help?",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    "Our customer support team is here to assist you.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSizes.spaceBtwItems),

                  ElevatedButton.icon(
                    onPressed: () => Get.to(() => const GetHelpScreen()),
                    icon: const Icon(Iconsax.call, size: 20),
                    label: const Text('Contact Support'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }
}

class FAQTile extends StatelessWidget {
  const FAQTile({
    super.key,
    required this.faq,
    required this.isExpanded,
    required this.onTap,
  });

  final FAQItem faq;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isExpanded
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        faq.question,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(
                        Iconsax.arrow_down_1,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState:
                    isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      faq.answer,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
