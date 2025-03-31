import 'package:flutter/material.dart';
import 'package:marikiti/Homepage.dart';
import 'package:marikiti/Widgets/pages/Mycart.dart';
import 'package:marikiti/Widgets/pages/Profile.dart';
import 'package:marikiti/core/constants/providers/orderprovider.dart';
import 'package:provider/provider.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _onNavItemTapped(int index) {
    if (index == _currentIndex) return; // Avoid unnecessary navigation

    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomePage()));
        break;
      case 1:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => OrderPage()));
        break;
      case 2:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => CartPage()));
        break;
      case 3:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => ProfilePage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Shop",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: [
            Tab(text: "Fruits"),
            Tab(text: "Dairy"),
            Tab(text: "Veggies"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProductList(category: "Fruits"),
          ProductList(category: "Dairy"),
          ProductList(category: "Veggies"),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "Shop"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: "My Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class ProductList extends StatelessWidget {
  final String category;
  const ProductList({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final products =
        Provider.of<OrderProvider>(context).getProductsByCategory(category);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columns
            crossAxisSpacing: 16, // space between columns
            mainAxisSpacing: 16, // Space between rows
            childAspectRatio: 0.7 // Adjust height-to-width ratio
            ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      child: Image.asset(product.image, fit: BoxFit.cover)),
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text("Vendor: ${product.vendor}",
                                style: TextStyle(color: Colors.grey)),
                            Text("Ksh ${product.price}",
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold))
                          ])),
                  ElevatedButton(
                    onPressed: () {
                      Provider.of<OrderProvider>(context, listen: false)
                          .addToCart(product);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text("Add to Cart",
                        style: TextStyle(color: Colors.white)),
                  ),
                ]),
          );
        },
      ),
    );
  }
}
