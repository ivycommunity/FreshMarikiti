import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/drawer.dart';
import 'package:marikiti/Widgets/pages/Mycart.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
            },
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.shopping_cart, color: Colors.black),
            ),
          ),
        ],
        title: Text(
          "Fresh Marikiti",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: FreshMarikitiDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        // Categories for the Fruits, veggies and dairy products 
        // Categories for the vendors list 
        // offers  

              SizedBox(height: 20),

         

              SizedBox(height: 20),

              // Offers Section
              sectionTitle('Offers', () {}),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    return offerCard(offers[index]);
                  },
                ),
              ),

              SizedBox(height: 20),

              // Customer Reviews
             // customerReviews(),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onTap, child: Text('See All'))
      ],
    );
  }

  Widget categoryItem(String name, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(imagePath),
          ),
          SizedBox(height: 5),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget vendorCard(Map<String, String> vendor) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Image.asset(vendor['image']!, height: 80, fit: BoxFit.cover),
            SizedBox(height: 5),
            Text(vendor['name']!, style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(onPressed: () {}, child: Text('View'))
          ],
        ),
      ),
    );
  }

  Widget offerCard(Map<String, String> offer) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offer['title']!, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(offer['description']!, style: TextStyle(fontSize: 12)),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(onPressed: () {}, child: Text('View')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget customerReviews() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('4.0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(width: 10),
              Icon(Icons.star, color: Colors.yellow[700]),
              Icon(Icons.star, color: Colors.yellow[700]),
              Icon(Icons.star, color: Colors.yellow[700]),
              Icon(Icons.star, color: Colors.yellow[700]),
              Icon(Icons.star_half, color: Colors.yellow[700]),
            ],
          ),
          SizedBox(height: 5),
          Text('Based on 300 reviews'),
          SizedBox(height: 5),
          Text('Mevis Katumi - Customer', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Sanple data
final List<Map<String, String>> categories = [
  {'name': 'Fruits', 'image': 'assets/fruits.png'},
  {'name': 'Veggies', 'image': 'assets/veggies.png'},
  {'name': 'Dairy', 'image': 'assets/dairy.png'},
];

final List<Map<String, String>> vendors = [
  {'name': 'Hassan Abdi', 'image': 'assets/vendor1.png'},
  {'name': 'Maria Halima', 'image': 'assets/vendor2.png'},
  {'name': 'Susan Kamau', 'image': 'assets/vendor3.png'},
];

final List<Map<String, String>> offers = [
  {'title': "It's Mango Season!", 'description': 'Get 1.5 kgs, smooth & juicy...', 'image': 'assets/mango.png'},
 // {'title': "Coconuts from Mombasa", 'description': 'Fresh & sweet coconuts...', 'image': 'assets/coconut.png'},
];
