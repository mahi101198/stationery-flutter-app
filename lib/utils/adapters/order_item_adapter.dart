import 'package:rps_stationery/data/models/order_model.dart' as enterprise;
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/data/models/cart_model.dart';

/// Adapter helpers for creating enterprise OrderItems from cart/product data
class OrderItemAdapter {
  /// Create enterprise OrderItem from CartItem and ProductModel
  static enterprise.OrderItem fromCartItem({
    required CartItem cartItem,
    required ProductModel product,
  }) {
    final effectivePrice = product.hasDiscount ? product.price : product.price;
    final subtotal = effectivePrice * cartItem.quantity;

    return enterprise.OrderItem(
      productId: cartItem.productId,
      name: product.name,
      price: effectivePrice,
      quantity: cartItem.quantity,
      subtotal: subtotal,
      productImage: product.displayImage,
      discountPrice: effectivePrice,
      totalPrice: subtotal,
      selectedColor: cartItem.selectedColor,
    );
  }

  /// Batch convert list of CartItems to enterprise OrderItems
  static List<enterprise.OrderItem> batchFromCartItems({
    required List<CartItem> cartItems,
    required List<ProductModel> products,
  }) {
    final result = <enterprise.OrderItem>[];

    for (final cartItem in cartItems) {
      final product = products.firstWhere(
        (p) => p.productId == cartItem.productId,
        orElse: () => ProductModel.empty(),
      );

      if (product.productId.isNotEmpty) {
        result.add(fromCartItem(cartItem: cartItem, product: product));
      }
    }

    return result;
  }
}
