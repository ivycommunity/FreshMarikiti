import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/pages/CheckoutPage.dart';
import 'package:marikiti/core/constants/providers/cart_provider.dart';
import 'package:marikiti/homepage.dart';
import 'package:provider/provider.dart';
import 'package:marikiti/core/constants/providers/product_provider.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final items = cartProvider.cartItems;

    const deliveryCharge = 100.0;
    final subtotal = cartProvider.subtotal;
    final total = subtotal + deliveryCharge;

    return Scaffold(
      backgroundColor: const Color(0xFFFDE5C7),
      appBar: AppBar(
        title: const Text("MY CART"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(backgroundColor: Colors.orange),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Color(0xFF7CC242),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(9, 2, 9, 2),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage(item.product.image),
                    ),
                    title:
                        Text("${item.product.name}\nFrom: ${item.vendor.name}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            )),
                    subtitle: Text("Ksh ${item.vendor.price}",
                        style: const TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 23,
                                width: 23,
                                child: GestureDetector(
                                  child: Icon(Icons.remove,
                                      color: Colors.black, size: 18),
                                  onTap: () {
                                    cartProvider.reduceItems(index);
                                  },
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  "${item.quantity}",
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(
                                width: 23,
                                height: 23,
                                child: GestureDetector(
                                  child: Icon(Icons.add,
                                      color: Colors.black, size: 18),
                                  onTap: () {
                                    final cartProvider =
                                        context.read<CartProvider>();
                                    final product =
                                        cartProvider.cartItems[index];

                                    if (product.quantity <
                                        product.vendor.inStock) {
                                      cartProvider.increaseItems(index);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Only ${product.vendor.inStock} in stock'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 4),
                        GestureDetector(
                          child: const Icon(Icons.delete, color: Colors.black),
                          onTap: () {
                            cartProvider.removeItem(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Subtotal",
                      style: TextStyle(fontSize: 18),
                    ),
                    Text("Ksh ${subtotal.toStringAsFixed(0)}",
                        style: TextStyle(fontSize: 18)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Delivery Charge", style: TextStyle(fontSize: 18)),
                    Text("Ksh 100", style: TextStyle(fontSize: 18)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Ksh ${total.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => CheckoutPage()));
                    },
                    child: const Text("PROCEED TO CHECKOUT",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                    child: const Text(
                  "Would you like to add this order to your subscription?",
                )),
                const SizedBox(height: 10),
              ],
            ),
          )
        ],
      ),
    );
  }
}
