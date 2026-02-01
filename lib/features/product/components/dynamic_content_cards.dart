import 'package:flutter/material.dart';
import 'package:rps_stationery/constants.dart';
import 'package:rps_stationery/data/models/content_card_model.dart';

/// Dynamic Content Cards Renderer - Renders backend-provided content cards
class DynamicContentCards extends StatelessWidget {
  final List<ContentCardModel> cards;

  const DynamicContentCards({
    super.key,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out empty cards
    final validCards = cards.where((card) => card.hasData).toList();

    if (validCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final card = validCards[index];
          return _buildCardByType(context, card);
        },
        childCount: validCards.length,
      ),
    );
  }

  Widget _buildCardByType(BuildContext context, ContentCardModel card) {
    switch (card.type) {
      case 'text':
        return _TextCard(card: card);
      case 'list':
        return _ListCard(card: card);
      case 'steps':
        return _StepsCard(card: card);
      case 'key_value':
        return _KeyValueCard(card: card);
      case 'warning':
        return _WarningCard(card: card);
      case 'info':
        return _InfoCard(card: card);
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Base card wrapper with consistent styling
class _CardWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  const _CardWrapper({
    required this.title,
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding / 2,
      ),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Text card - Simple text content
class _TextCard extends StatelessWidget {
  final ContentCardModel card;

  const _TextCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return _CardWrapper(
      title: card.title,
      child: Text(
        card.data.toString(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}

/// List card - Bulleted list
class _ListCard extends StatelessWidget {
  final ContentCardModel card;

  const _ListCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final items = card.data is List ? card.data as List : [];

    return _CardWrapper(
      title: card.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Steps card - Numbered steps
class _StepsCard extends StatelessWidget {
  final ContentCardModel card;

  const _StepsCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final steps = card.data is List ? card.data as List : [];

    return _CardWrapper(
      title: card.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      step.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Key-Value card - Specifications or details
class _KeyValueCard extends StatelessWidget {
  final ContentCardModel card;

  const _KeyValueCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final data = card.data is Map ? card.data as Map : {};

    return _CardWrapper(
      title: card.title,
      child: Column(
        children: data.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Warning card - Important warnings
class _WarningCard extends StatelessWidget {
  final ContentCardModel card;

  const _WarningCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return _CardWrapper(
      title: card.title,
      backgroundColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
      borderColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              card.data.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Info card - Helpful information
class _InfoCard extends StatelessWidget {
  final ContentCardModel card;

  const _InfoCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return _CardWrapper(
      title: card.title,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
      borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              card.data.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
