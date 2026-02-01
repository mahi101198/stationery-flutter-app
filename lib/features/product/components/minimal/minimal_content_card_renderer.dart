import 'package:flutter/material.dart';
import 'package:rps_stationery/data/models/content_card_model.dart';

/// Minimal Dynamic Content Card Renderer
/// Renders different card types based on the type field
class MinimalContentCardRenderer extends StatelessWidget {
  final ContentCardModel card;

  const MinimalContentCardRenderer({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    if (!card.hasData) {
      return const SizedBox.shrink();
    }

    switch (card.type.toLowerCase()) {
      case 'list':
        return _buildListCard(context);
      case 'steps':
        return _buildStepsCard(context);
      case 'key_value':
        return _buildKeyValueCard(context);
      case 'warning':
        return _buildWarningCard(context);
      case 'info':
        return _buildInfoCard(context);
      case 'text':
      default:
        return _buildTextCard(context);
    }
  }

  /// Build List Card (e.g., Highlights) - Fixed layout matching mockup
  Widget _buildListCard(BuildContext context) {
    if (card.data is! List) return const SizedBox.shrink();
    
    final items = (card.data as List).whereType<String>().toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          if (card.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                card.title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          
          // List items in 2 columns with consistent spacing
          ...List.generate((items.length / 2).ceil(), (rowIndex) {
            final leftIndex = rowIndex * 2;
            final rightIndex = leftIndex + 1;
            final isLastRow = rowIndex == ((items.length / 2).ceil() - 1);
            
            return Padding(
              padding: EdgeInsets.only(bottom: isLastRow ? 0 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left item
                  Expanded(
                    child: _buildHighlightItem(items[leftIndex]),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Right item (or empty space if odd number)
                  Expanded(
                    child: rightIndex < items.length
                        ? _buildHighlightItem(items[rightIndex])
                        : const SizedBox(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Circle
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle,
              size: 18,
              color: Color(0xFF00BCD4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Text
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// Build Steps Card (e.g., Usage Instructions)
  Widget _buildStepsCard(BuildContext context) {
    if (card.data is! List) return const SizedBox.shrink();
    
    final steps = (card.data as List).whereType<String>().toList();
    if (steps.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title (h3)
            if (card.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            
            // Steps Container (space-y 10px)
            Column(
              children: List.generate(steps.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == steps.length - 1 ? 0 : 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step Number Circle (32x32, bg-cyan/10)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00BCD4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Step Text (14px, color gray-700)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            steps[index],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Key-Value Card (e.g., Specifications) - Two-column table layout
  Widget _buildKeyValueCard(BuildContext context) {
    if (card.data is! Map) return const SizedBox.shrink();
    
    final specs = card.data as Map<String, dynamic>;
    if (specs.isEmpty) return const SizedBox.shrink();

    final specsList = specs.entries.toList();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section Title - CENTERED as per mockup
          if (card.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                card.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Card Container for Specifications - Full Width
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Specs list with two-column table layout
                ...List.generate(specsList.length, (index) {
                  final entry = specsList[index];
                  final isLast = index == specsList.length - 1;
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Label (left-aligned, bold)
                        Expanded(
                          flex: 45,
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right Column: Value (left-aligned, bold)
                        Expanded(
                          flex: 55,
                          child: Text(
                            entry.value.toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build Warning Card
  Widget _buildWarningCard(BuildContext context) {
    final text = card.data?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF332701) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFFB45309) : const Color(0xFFFBBF24),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (card.title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        card.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
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

  /// Build Info Card
  Widget _buildInfoCard(BuildContext context) {
    final text = card.data?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF10B981) : const Color(0xFF10B981),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (card.title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        card.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
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

  /// Build Text Card (e.g., Product Description) with Read More functionality
  Widget _buildTextCard(BuildContext context) {
    final text = card.data?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title (h3)
          if (card.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                card.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          
          // Description Text with Read More functionality
          _ExpandableText(text: text),
        ],
      ),
    );
  }
}

/// Expandable Text Widget with Read More/Read Less functionality
class _ExpandableText extends StatefulWidget {
  final String text;

  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.6,
          ),
        ),
        
        // Read More / Read Less button
        if (widget.text.length > 100) // Only show if text is long enough
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(
                _isExpanded ? 'Read Less' : 'Read More',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
