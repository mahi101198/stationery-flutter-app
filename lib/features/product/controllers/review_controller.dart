import 'package:get/get.dart';
import 'package:rps_stationery/data/models/review_model.dart';
import 'package:rps_stationery/data/repositories/review_repo.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

/// Controller for managing product reviews
class ReviewController extends GetxController {
  static ReviewController get instance => Get.find();

  final ReviewRepo _reviewRepo = ReviewRepo.instance;

  // Current product reviews
  final RxList<ReviewModel> _reviews = <ReviewModel>[].obs;
  final Rx<ReviewStats?> _reviewStats = Rx<ReviewStats?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = ''.obs;

  // User's review for current product
  final Rx<ReviewModel?> _userReview = Rx<ReviewModel?>(null);
  final RxBool _canUserReview = false.obs;

  // Getters
  List<ReviewModel> get reviews => _reviews;
  ReviewStats? get reviewStats => _reviewStats.value;
  bool get isLoading => _isLoading.value;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;
  ReviewModel? get userReview => _userReview.value;
  bool get canUserReview => _canUserReview.value;

  @override
  void onInit() {
    super.onInit();
    print('📝 ReviewController: Initializing review controller...');
  }

  /// Load reviews for a product
  Future<void> loadProductReviews(String productId) async {
    print('📝 ReviewController: Loading reviews for product: $productId');
    
    _isLoading.value = true;
    _hasError.value = false;
    _errorMessage.value = '';

    try {
      // Load reviews and stats in parallel
      final results = await Future.wait([
        _reviewRepo.getProductReviews(productId),
        _reviewRepo.getProductReviewStats(productId),
        _reviewRepo.getUserReview(productId),
        _reviewRepo.canUserReviewProduct(productId),
      ]);

      _reviews.assignAll(results[0] as List<ReviewModel>);
      _reviewStats.value = results[1] as ReviewStats;
      _userReview.value = results[2] as ReviewModel?;
      _canUserReview.value = results[3] as bool;

      print('✅ ReviewController: Loaded ${_reviews.length} reviews for product $productId');
      print('📊 ReviewController: Review stats - Avg: ${_reviewStats.value?.averageRating}, Total: ${_reviewStats.value?.totalReviews}');
      print('👤 ReviewController: Can user review: ${_canUserReview.value}, Has user review: ${_userReview.value != null}');

    } catch (e) {
      print('❌ ReviewController: Error loading reviews: $e');
      _hasError.value = true;
      _errorMessage.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Add a review for a product
  Future<void> addReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    print('📝 ReviewController: Adding review for product: $productId');
    
    try {
      await _reviewRepo.addReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );

      // Reload reviews to show the new one
      await loadProductReviews(productId);

      TLoaders.successSnackBar(
        title: 'Review Added',
        message: 'Thank you for your review!',
      );

      print('✅ ReviewController: Successfully added review for product $productId');

    } catch (e) {
      print('❌ ReviewController: Error adding review: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Update user's review for a product
  Future<void> updateReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    print('📝 ReviewController: Updating review for product: $productId');
    
    try {
      await _reviewRepo.updateReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );

      // Reload reviews to show the updated one
      await loadProductReviews(productId);

      TLoaders.successSnackBar(
        title: 'Review Updated',
        message: 'Your review has been updated!',
      );

      print('✅ ReviewController: Successfully updated review for product $productId');

    } catch (e) {
      print('❌ ReviewController: Error updating review: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Delete user's review for a product
  Future<void> deleteReview(String productId) async {
    print('📝 ReviewController: Deleting review for product: $productId');
    
    try {
      await _reviewRepo.deleteReview(productId);

      // Reload reviews to remove the deleted one
      await loadProductReviews(productId);

      TLoaders.successSnackBar(
        title: 'Review Deleted',
        message: 'Your review has been deleted!',
      );

      print('✅ ReviewController: Successfully deleted review for product $productId');

    } catch (e) {
      print('❌ ReviewController: Error deleting review: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Clear all review data
  void clearReviews() {
    _reviews.clear();
    _reviewStats.value = null;
    _userReview.value = null;
    _canUserReview.value = false;
    _hasError.value = false;
    _errorMessage.value = '';
    print('🧹 ReviewController: Cleared all review data');
  }

  /// Refresh reviews for current product
  Future<void> refreshReviews(String productId) async {
    print('🔄 ReviewController: Refreshing reviews for product: $productId');
    await loadProductReviews(productId);
  }
}

