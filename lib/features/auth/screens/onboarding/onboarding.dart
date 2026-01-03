import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/ui/modern_ui.dart';
import 'package:rps_stationery/components/ui/modern_components.dart' show ButtonVariant, ButtonSize;
import 'package:rps_stationery/features/auth/controllers/onboarding/onboarding_controller.dart';
import 'package:rps_stationery/utils/constants/image_strings.dart';
import 'package:rps_stationery/utils/constants/text_strings.dart';
import 'package:rps_stationery/utils/device/device_utility.dart';
import 'package:rps_stationery/utils/helpers/helper_functions.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/utils/theme/app_colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: context.cardGradient,
        ),
        child: Stack(
          children: [
            // Horizontal Scroll Pager with animations
            PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              children: [
                OnboardingPage(
                  title: TTexts.onBoardingTitle1,
                  subtitle: TTexts.onBoardingSubTitle1,
                  image: ImageString.onBoardingImage1,
                  pageIndex: 0,
                ),
                OnboardingPage(
                  title: TTexts.onBoardingTitle2,
                  subtitle: TTexts.onBoardingSubTitle2,
                  image: ImageString.onBoardingImage2,
                  pageIndex: 1,
                ),
                OnboardingPage(
                  title: TTexts.onBoardingTitle3,
                  subtitle: TTexts.onBoardingSubTitle3,
                  image: ImageString.onBoardingImage3,
                  pageIndex: 2,
                ),
              ],
            ),

            // Modern Skip Button with glassmorphism effect
            Positioned(
              top: TDeviceUtils.getAppBarHeight(),
              right: DesignSystem.spacing.lg,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ThemeAwareButton(
                  text: "Skip",
                  variant: ButtonVariant.ghost,
                  size: ButtonSize.small,
                  onPressed: controller.skip,
                ),
              ),
            ),

            // Modern Bottom Section with glassmorphism
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
                padding: EdgeInsets.all(DesignSystem.spacing.lg),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dot navigation
                      const OnboardingDotIndicator(),
                      
                      // Next/Finish button
                      Obx(
                        () => controller.currentPageIndex.value == 2
                            ? // Get Started Button (Last page)
                              ThemeAwareButton(
                                onPressed: controller.next,
                                text: "Get Started",
                                variant: ButtonVariant.primary,
                                size: ButtonSize.medium,
                              )
                            : // Next Arrow Button (First two pages)
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: controller.next,
                                  icon: Icon(
                                    Iconsax.arrow_right_3,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    size: 24,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingDotIndicator extends StatelessWidget {
  const OnboardingDotIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnboardingController.instance;

    return SmoothPageIndicator(
      controller: controller.pageController,
      onDotClicked: controller.onDotClicked,
      count: 3,
      effect: ExpandingDotsEffect(
        activeDotColor: Theme.of(context).colorScheme.primary,
        dotColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        dotHeight: 10,
        dotWidth: 10,
        expansionFactor: 4,
        spacing: 12,
        radius: 20,
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.pageIndex,
  });

  final String title, subtitle, image;
  final int pageIndex;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Start animation with a slight delay
    Future.delayed(Duration(milliseconds: widget.pageIndex * 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: EdgeInsets.all(DesignSystem.spacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated image with modern styling and floating effect
                  Container(
                    height: HelperFunctions.screenHeight() * 0.45,
                    width: HelperFunctions.screenWidth() * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: DesignSystem.borders.xxl,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: DesignSystem.borders.xxl,
                      child: Stack(
                        children: [
                          Image(
                            image: AssetImage(widget.image),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          // Gradient overlay for better text readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: DesignSystem.spacing.xxl),
                  
                  // Modern title with gradient text effect
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      widget.title,
                      style: DesignSystem.typography.headlineLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: DesignSystem.spacing.lg),
                  
                  // Modern subtitle with improved styling
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: HelperFunctions.screenWidth() * 0.85,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacing.md,
                      vertical: DesignSystem.spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                      borderRadius: DesignSystem.borders.lg,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.subtitle,
                      style: DesignSystem.typography.bodyLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: DesignSystem.spacing.xxl * 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
