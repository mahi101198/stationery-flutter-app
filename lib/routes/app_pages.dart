import 'package:get/get.dart';
import 'package:rps_stationery/bindings/initial_bindings.dart';
import 'package:rps_stationery/bindings/product_detail_binding.dart';
import 'package:rps_stationery/features/auth/screens/forgot_password/forgot_password_screen.dart';
import 'package:rps_stationery/features/category/optimized_category_screen.dart';
import 'package:rps_stationery/features/category/screens/subcategory_products_screen.dart';
import 'package:rps_stationery/features/category/bindings/streaming_subcategory_products_binding.dart';
import 'package:rps_stationery/features/home/screens/section_view_all_screen.dart';
import 'package:rps_stationery/features/notification/notification_screen.dart';
import 'package:rps_stationery/features/order/screens/order_success_screen.dart';
import 'package:rps_stationery/features/order/screens/order_list_screen.dart';
import 'package:rps_stationery/features/order/screens/order_details_screen.dart';
import 'package:rps_stationery/features/order/screens/order_cancelled_screen.dart';
import 'package:rps_stationery/features/personalization/screens/referrals_screen.dart';
import 'package:rps_stationery/features/product/minimal_product_details_screen.dart';
import 'package:rps_stationery/features/promotions/promotions_screen.dart';
import 'package:rps_stationery/features/search/optimized_search_screen.dart';
import 'package:rps_stationery/features/checkout/screens/address_selection_screen.dart';
import 'package:rps_stationery/features/checkout/screens/price_summary_screen.dart';
import 'package:rps_stationery/features/checkout/screens/payment_method_selection_screen.dart';
import 'package:rps_stationery/features/checkout/bindings/payment_binding.dart';
import 'package:rps_stationery/features/profile/screens/wallet_screen.dart';
import 'package:rps_stationery/features/profile/screens/refer_earn_screen.dart';
import 'package:rps_stationery/features/personalization/screens/about_app_screen.dart';
import 'package:rps_stationery/features/personalization/screens/legal_documents/terms_conditions_screen.dart';
import 'package:rps_stationery/features/personalization/screens/legal_documents/privacy_policy_screen.dart';
import 'package:rps_stationery/features/personalization/screens/legal_documents/refund_policy_screen.dart';
import 'package:rps_stationery/navigation.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = [
    GetPage(
      name: Routes.bottomNav,
      page: () => const BottomNavigationMenu(),
      bindings: [InitialBinding()],
    ),
    GetPage(
      name: Routes.productDetail,
      page: () => const MinimalProductDetailsScreen(),
      binding: ProductDetailBinding(),
    ),
    GetPage(name: Routes.search, page: () => OptimizedSearchScreen()),
    GetPage(name: Routes.notification, page: () => NotificationScreen()),
    GetPage(
      name: Routes.order,
      page: () => const OrderListScreen(),
    ),
    GetPage(
      name: Routes.orderDetails,
      page: () {
        String orderId;
        if (Get.arguments is String) {
          orderId = Get.arguments as String;
        } else if (Get.arguments is Map && (Get.arguments as Map)['orderId'] is String) {
          orderId = (Get.arguments as Map)['orderId'] as String;
        } else {
          throw Exception('Invalid arguments for orderDetails route. Expected String or Map with orderId.');
        }
        return OrderDetailsScreen(orderId: orderId);
      },
    ),
    GetPage(
      name: Routes.category,
      page: () => const OptimizedCategoryScreen(),
    ),
    GetPage(
      name: Routes.subCategoryProducts,
      page: () => const SubCategoryProductsScreen(),
      binding: StreamingSubCategoryProductsBinding(),
    ),
    GetPage(
      name: Routes.sectionViewAll,
      page: () => const SectionViewAllScreen(),
    ),
    GetPage(
      name: Routes.addressSelection,
      page: () => const AddressSelectionScreen(),
    ),
    GetPage(
      name: Routes.priceSummary,
      page: () {
        final args = Get.arguments;
        return PriceSummaryScreen(
          cartItems: args['cartItems'] ?? [],
          deliveryAddress: args['deliveryAddress'],
          totalAmount: args['totalAmount'] ?? 0.0,
          promoCode: args['promoCode'],
          isBuyNow: args['isBuyNow'] ?? false,
          buyNowData: args['buyNowData'],
        );
      },
    ),
    GetPage(
      name: Routes.paymentMethodSelection,
      page: () {
        final args = Get.arguments;
        return PaymentMethodSelectionScreen(
          cartItems: args['cartItems'] ?? [],
          deliveryAddress: args['deliveryAddress'],
          totalAmount: args['totalAmount'] ?? 0.0,
          promoCode: args['promoCode'],
          discountAmount: args['discountAmount'] ?? 0.0,
          finalAmount: args['finalAmount'] ?? 0.0,
          deliveryCharge: args['deliveryCharge'] ?? 0.0,
          walletDiscountAmount: args['walletDiscountAmount'] ?? 0.0,
          payFromWallet: args['payFromWallet'] ?? false,
          orderId: args['orderId'],
          remainingAmount: args['remainingAmount'],
          isBuyNow: args['isBuyNow'] ?? false,
          buyNowData: args['buyNowData'],
        );
      },
      binding: PaymentBinding(),
    ),
    GetPage(
      name: Routes.orderSuccess,
      page: () {
        final args = Get.arguments;
        String orderId;
        if (args is Map && args['orderId'] is String) {
          orderId = args['orderId'] as String;
        } else if (args is String) {
          orderId = args;
        } else {
          orderId = '';
        }
        return OrderSuccessScreen(orderId: orderId);
      },
    ),
    GetPage(
      name: Routes.orderCancelled,
      page: () {
        final cancellationData = Get.arguments as Map<String, dynamic>;
        return OrderCancelledScreen(cancellationData: cancellationData);
      },
    ),
    GetPage(
      name: Routes.promotions,
      page: () => const PromotionsScreen(),
    ),
    GetPage(
      name: Routes.profileReferrals,
      page: () => const ReferralsScreen(),
    ),
    GetPage(
      name: Routes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: Routes.wallet,
      page: () => const WalletScreen(),
    ),
    GetPage(
      name: Routes.referEarn,
      page: () => const ReferEarnScreen(),
    ),
    GetPage(
      name: Routes.aboutApp,
      page: () => const AboutAppScreen(),
    ),
    GetPage(
      name: Routes.termsConditions,
      page: () => const TermsConditionsScreen(),
    ),
    GetPage(
      name: Routes.privacyPolicy,
      page: () => const PrivacyPolicyScreen(),
    ),
    GetPage(
      name: Routes.refundPolicy,
      page: () => const RefundPolicyScreen(),
    ),
  ];
}
