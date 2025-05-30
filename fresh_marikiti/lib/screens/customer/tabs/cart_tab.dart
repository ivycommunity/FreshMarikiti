import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/providers/cart_provider.dart';
import 'package:fresh_marikiti/services/order_service.dart';
import 'package:fresh_marikiti/providers/auth_provider.dart';
import 'dart:convert';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                cart.clearCart();
              },
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _buildCartItem(context, item, cart);
                    },
                  ),
                ),
                _buildCheckoutSection(context, cart),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            'Add some items to get started',
            style: AppTextStyles.body.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).maybePop();
            },
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartProvider cart) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(item.product.imageUrl.isNotEmpty ? item.product.imageUrl : 'https://via.placeholder.com/100'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KES ${item.product.price}',
                    style: AppTextStyles.body.copyWith(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity Controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (item.quantity > 1) {
                      cart.updateQuantity(item.product.id, item.quantity - 1);
                    } else {
                      cart.removeFromCart(item.product.id);
                    }
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    cart.updateQuantity(item.product.id, item.quantity + 1);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Order Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.heading2,
                ),
                Text(
                  'KES ${cart.total.toStringAsFixed(2)}',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cart.items.isEmpty ? null : () async {
                  final result = await _showCheckoutDialog(context, cart);
                  if (result == true) {
                    cart.clearCart();
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Proceed to Checkout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showCheckoutDialog(BuildContext context, CartProvider cart) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final addressController = TextEditingController();
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    bool isLoading = false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Checkout'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final address = addressController.text.trim();
                          final phone = phoneController.text.trim();
                          if (address.isEmpty || phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter address and phone number')),
                            );
                            return;
                          }
                          setState(() => isLoading = true);
                          final result = await OrderService.placeOrder(
                            cartItems: cart.items,
                            deliveryAddress: address,
                            phoneNumber: phone,
                          );
                          setState(() => isLoading = false);
                          if (result['success']) {
                            final order = result['order'];
                            final orderId = order['_id'] ?? order['id'];
                            final total = order['totalAmount'] ?? order['total'] ?? order['totalPrice'] ?? 0.0;
                            final paymentResult = await OrderService.initiateMpesaPayment(
                              phoneNumber: phone,
                              amount: (total is num) ? total.toDouble() : 0.0,
                              orderId: orderId,
                            );
                            if (paymentResult['success']) {
                              Navigator.of(context).pop(true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order placed! Complete payment on your phone.')),
                              );
                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('M-Pesa Payment'),
                                  content: const Text('A payment prompt has been sent to your phone. Please complete the payment to process your order.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(paymentResult['message'] ?? 'Payment initiation failed')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message'] ?? 'Order failed')),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Place Order'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 