import 'package:flutter/material.dart';
import 'package:rps_stationery/components/network_image_with_loader.dart';

class CategoryBanner extends StatelessWidget {

  const CategoryBanner({
    super.key,
    required this.image,
    required this.title,
    required this.press,
    this.subtitle,
    this.discountPercent,
  });

  final String image;
  final VoidCallback press;
  final String title;
  final String? subtitle;
  final int? discountPercent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 4,
      shadowColor: isDark ? Colors.black54 : Colors.grey.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 2.4,
          child: InkWell(
            onTap: press,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkImageWithLoader(
                  image, 
                  radius: 16,
                  fit: BoxFit.cover,
                ),
                // Gradient overlay for better text readability
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Discount badge
                            if (discountPercent != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SAVE $discountPercent%',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            SizedBox(height: discountPercent != null ? 4 : 0),
                            
                            // Title - use Flexible for better space management
                            Flexible(
                              child: Text(
                                title.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            // Subtitle
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Flexible(
                                child: Text(
                                  subtitle!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 4),
                            
                            // Shop Now button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SHOP NOW',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
