# Quick Implementation Guide - Centralized Theme System

## TL;DR - How to Use

### Step 1: Import Required Files
```dart
import 'package:rps_stationery/utils/theme/app_colors.dart';
import 'package:rps_stationery/utils/theme/component_styles.dart';
```

### Step 2: Use Theme Colors
```dart
// For text colors
Text(
  'Hello',
  style: TextStyle(
    color: Theme.of(context).colorScheme.onSurface,
  ),
)

// For backgrounds
Container(
  color: Theme.of(context).scaffoldBackgroundColor,
)

// For primary action
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
  ),
  onPressed: () {},
  child: const Text('Click'),
)
```

### Step 3: Use ComponentStyles for Complex Styling
```dart
// Price display with gradient
ShaderMask(
  shaderCallback: (bounds) => 
    ComponentStyles.getPriceGradient(isDark).createShader(bounds),
  child: Text('₹999'),
)

// Discount badge
Container(
  decoration: ComponentStyles.discountBadgeDecoration(borderRadius: 6),
  child: Text('50% OFF'),
)

// Card styling
Container(
  decoration: ComponentStyles.getProductCardDecoration(context, isDark),
  child: YourCard(),
)
```

---

## Color Reference Quick Guide

### Text Colors
| Purpose | Light | Dark | How to Use |
|---------|-------|------|-----------|
| Primary text | `#1A1A1A` | `#E5E5E5` | `colorScheme.onSurface` |
| Secondary text | `#424242` | `#BDBDBД` | `colorScheme.onSurfaceVariant` |
| Disabled text | `#B0B0B0` | `#616161` | With `alpha: 0.5` |

### Background Colors
| Purpose | Light | Dark | How to Use |
|---------|-------|------|-----------|
| Page background | `#FFFFFF` | `#0A0A0A` | `scaffoldBackgroundColor` |
| Card background | `#FAFAFA` | `#121212` | `colorScheme.surface` |
| Button background | `#00BCD4` | `#4DD0E1` | `colorScheme.primary` |

### Accent Colors
| Purpose | Light | Dark | How to Use |
|---------|-------|------|-----------|
| Primary action | `#00BCD4` (Teal) | `#4DD0E1` | `colorScheme.primary` |
| Alert/Error | `#D32F2F` (Red) | `#EF5350` | `colorScheme.error` |
| Success | `#4CAF50` (Green) | `#81C784` | `colorScheme.tertiary` |
| Warning | `#FFA000` (Orange) | `#FFCC02` | From AppColors |

---

## ComponentStyles Cheat Sheet

### Cards
```dart
Container(
  decoration: ComponentStyles.getProductCardDecoration(context, isDark),
)
```

### Prices
```dart
// Original price (struck out)
Text(
  '₹999',
  style: ComponentStyles.originalPriceStyle(theme, isDark),
)

// Selling price (with gradient)
ShaderMask(
  shaderCallback: (bounds) => 
    ComponentStyles.getPriceGradient(isDark).createShader(bounds),
  child: Text(
    '₹599',
    style: ComponentStyles.sellingPriceStyle(theme, isCompact),
  ),
)
```

### Badges
```dart
// Discount badge (red gradient)
Container(
  decoration: ComponentStyles.discountBadgeDecoration(borderRadius: 6),
  child: Text(
    '50% OFF',
    style: ComponentStyles.discountBadgeTextStyle(fontSize: 12, bold: true),
  ),
)

// Success badge (green)
Container(
  decoration: ComponentStyles.successBadgeDecoration(),
  child: Text('In Stock', style: ComponentStyles.successBadgeTextStyle()),
)

// Warning badge (orange)
Container(
  decoration: ComponentStyles.warningBadgeDecoration(),
  child: Text('Limited Stock', style: ComponentStyles.warningBadgeTextStyle()),
)

// Error badge (red)
Container(
  decoration: ComponentStyles.errorBadgeDecoration(),
  child: Text('Out of Stock', style: ComponentStyles.errorBadgeTextStyle()),
)
```

### Shadows
```dart
// For cards with elevation
BoxDecoration(
  boxShadow: ComponentStyles.getElevationShadow(
    8, // elevation
    isDark,
  ),
)
```

### Borders
```dart
// Standard border
Container(
  decoration: BoxDecoration(
    border: Border.all(
      width: 1,
      color: ComponentStyles.getDividerColor(isDark),
    ),
  ),
)
```

### Input Fields
```dart
TextField(
  decoration: ComponentStyles.searchInputDecorationLight(context),
)

// Or for dark
TextField(
  decoration: isDark 
    ? ComponentStyles.searchInputDecorationDark(context)
    : ComponentStyles.searchInputDecorationLight(context),
)
```

---

## DO's and DON'Ts

### ✅ DO
```dart
// Use Theme.of() for colors
Text(
  'Hello',
  style: TextStyle(
    color: Theme.of(context).colorScheme.onSurface,
  ),
)

// Use ComponentStyles for decorations
Container(
  decoration: ComponentStyles.successBadgeDecoration(),
)

// Use AppColors for constants
const primaryColor = AppColors.lightPrimary;
```

### ❌ DON'T
```dart
// Never hardcode colors
Text(
  'Hello',
  style: TextStyle(
    color: Color(0xFF1A1A1A), // NO!
  ),
)

// Never duplicate styles
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
  ), // NO! Use ComponentStyles
)

// Never ignore theme brightness
Text(
  'Hello',
  style: TextStyle(
    color: Colors.black, // NO! Use colorScheme
  ),
)
```

---

## Common Implementations

### 1. Product Card
```dart
Column(
  children: [
    // Image
    ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(product.image),
    ),
    // Card container
    Container(
      decoration: ComponentStyles.getProductCardDecoration(context, isDark),
      child: Column(
        children: [
          // Product name
          Text(
            product.name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          // Price with gradient
          ShaderMask(
            shaderCallback: (bounds) => 
              ComponentStyles.getPriceGradient(isDark).createShader(bounds),
            child: Text(
              '₹${product.price}',
              style: ComponentStyles.sellingPriceStyle(theme, false),
            ),
          ),
          // Discount badge
          Container(
            decoration: ComponentStyles.discountBadgeDecoration(borderRadius: 6),
            child: Text(
              '${product.discount}% OFF',
              style: ComponentStyles.discountBadgeTextStyle(fontSize: 12, bold: true),
            ),
          ),
        ],
      ),
    ),
  ],
)
```

### 2. Alert/Status Badges
```dart
// In Stock - Green
Container(
  decoration: ComponentStyles.successBadgeDecoration(),
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: Text('In Stock', style: ComponentStyles.successBadgeTextStyle()),
)

// Limited Stock - Orange
Container(
  decoration: ComponentStyles.warningBadgeDecoration(),
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: Text('Limited Stock', style: ComponentStyles.warningBadgeTextStyle()),
)

// Out of Stock - Red
Container(
  decoration: ComponentStyles.errorBadgeDecoration(),
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: Text('Out of Stock', style: ComponentStyles.errorBadgeTextStyle()),
)
```

### 3. Primary Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  onPressed: onPressed,
  child: const Text('Button Text'),
)
```

### 4. Card with Content
```dart
Container(
  decoration: ComponentStyles.getProductCardDecoration(context, isDark),
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      // Title
      Text(
        'Card Title',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Divider
      Divider(
        color: ComponentStyles.getDividerColor(isDark),
      ),
      // Content
      Text(
        'Card content here',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  ),
)
```

---

## Theme Switching Test

To test your implementation:

1. Open app in light mode - verify colors look good
2. Go to Profile → Settings → Switch to Dark Mode
3. Return to your page - all colors should instantly update
4. Switch back to Light Mode - verify original colors return

If colors don't update, you likely used:
- Hardcoded colors instead of `Theme.of(context)`
- Const widgets when you need reactive updates
- Wrong color reference

---

## Need Help?

Refer to these files for examples:
- `lib/components/product/product_card.dart` - ✅ Updated with ComponentStyles
- `lib/features/product/minimal_product_details_screen.dart` - ✅ Updated with theme colors
- `lib/utils/theme/component_styles.dart` - Complete reference for all styles

Questions? Check `CENTRALIZED_THEME_SYSTEM.md` for detailed documentation!
