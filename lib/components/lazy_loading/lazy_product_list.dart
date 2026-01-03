import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/components/product/product_card.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/features/home/controllers/paginated_product_controller.dart';
import 'package:rps_stationery/routes/app_pages.dart';

class LazyProductList extends StatefulWidget {
  final String category;
  final bool isHorizontal;
  final int initialLoadCount;
  final ScrollController? scrollController;

  const LazyProductList({
    super.key,
    required this.category,
    this.isHorizontal = false,
    this.initialLoadCount = 10,
    this.scrollController,
  });

  @override
  State<LazyProductList> createState() => _LazyProductListState();
}

class _LazyProductListState extends State<LazyProductList> {
  final PaginatedProductController controller = Get.put(PaginatedProductController());
  final ScrollController _scrollController = ScrollController();
  List<ProductModel> _products = [];
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    final scrollController = widget.scrollController ?? _scrollController;
    scrollController.addListener(() {
      if (scrollController.position.pixels >= 
          scrollController.position.maxScrollExtent - 200) {
        _loadMoreProducts();
      }
    });
  }

  Future<void> _loadInitialProducts() async {
    try {
      _products = await controller.getProductsForCategory(
        widget.category,
        limit: widget.initialLoadCount,
      );
      setState(() {});
    } catch (e) {
      // Handle error
      print('Error loading initial products: $e');
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final moreProducts = await controller.getProductsForCategory(
        widget.category,
        limit: 10,
      );

      if (moreProducts.isEmpty) {
        _hasMoreData = false;
      } else {
        _products.addAll(moreProducts);
      }
    } catch (e) {
      print('Error loading more products: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return widget.isHorizontal
        ? _buildHorizontalList()
        : _buildVerticalList();
  }

  Widget _buildHorizontalList() {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        controller: widget.scrollController ?? _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _products.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: index == _products.length - 1 ? 8 : 0,
            ),
            child: ProductCard(
              product: _products[index],
              press: () {
                Get.toNamed(
                  Routes.productDetail,
                  arguments: _products[index].productId,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalList() {
    return ListView.builder(
      controller: widget.scrollController ?? _scrollController,
      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _products.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ProductCard(
            product: _products[index],
            press: () {
              Get.toNamed(
                Routes.productDetail,
                arguments: _products[index].productId,
              );
            },
          ),
        );
      },
    );
  }
}
