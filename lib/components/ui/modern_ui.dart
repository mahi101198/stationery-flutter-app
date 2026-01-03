// Modern UI Components Library
// A comprehensive collection of reusable, animated UI components
// following the design system principles

// Core Components
export 'modern_components.dart';

// Form Components
export 'form_components.dart';

// Layout Components
export 'layout_components.dart';

// Skeleton Loaders
export 'modern_skeletons.dart';

/// Re-export commonly used enums and models for convenience
export 'modern_components.dart' show ButtonVariant, ButtonSize;
export 'form_components.dart' show DropdownItem;
export 'layout_components.dart' show BottomNavItem, DrawerItem, TransitionType;

// Usage Example:
/*
import 'package:rps_stationery/components/ui/modern_ui.dart';

class ExampleUsage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Modern UI Example',
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Modern Card
            ModernCard(
              child: Column(
                children: [
                  // Text Field
                  ModernTextField(
                    label: 'Email',
                    hint: 'Enter your email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  
                  // Dropdown
                  ModernDropdown<String>(
                    label: 'Country',
                    hint: 'Select country',
                    items: [
                      DropdownItem(value: 'us', label: 'United States', icon: Icons.flag),
                      DropdownItem(value: 'uk', label: 'United Kingdom', icon: Icons.flag),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Checkbox
                  ModernCheckbox(
                    value: true,
                    label: 'I agree to the terms and conditions',
                  ),
                  SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ModernButton(
                          text: 'Cancel',
                          variant: ButtonVariant.secondary,
                          onPressed: () {},
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ModernButton(
                          text: 'Submit',
                          variant: ButtonVariant.primary,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Progress Indicator
            ModernProgressIndicator(
              progress: 0.7,
              label: 'Profile Completion',
            ),
            SizedBox(height: 16),
            
            // Skeleton Loaders
            ModernSkeleton.text(width: double.infinity),
            SizedBox(height: 8),
            ModernSkeleton.text(width: 200),
            SizedBox(height: 8),
            ModernSkeleton.circle(size: 40),
          ],
        ),
      ),
      floatingActionButton: ModernFAB(
        icon: Icons.add,
        onPressed: () {},
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: 0,
        onTap: (index) {},
        items: [
          BottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          BottomNavItem(
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart,
            label: 'Cart',
          ),
          BottomNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Navigation with transitions
void navigateToPage(BuildContext context, Widget page) {
  Navigator.push(
    context,
    ModernPageTransition(
      child: page,
      transitionType: TransitionType.slideFromRight,
    ),
  );
}
*/
