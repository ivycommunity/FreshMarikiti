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
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => CartPage()));
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
                // Category section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    categoryItem('Fruits', 'assets/fruits.png'),
                    categoryItem("Vegies", 'assets/vegetables.png'),
                    categoryItem("Dairy Products", 'assets/dairy.png')
                  ],
                ),

                SizedBox(height: 10),

                Column(
                  children: [
                    sectionTitle(
                      "Vendors List", /*ontap*/
                    ),
                    SizedBox(height: 5),
                    // Vendor section
                    SizedBox(
                      height: 150,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: vendors
                            .map((vendor) => vendorCard(vendor))
                            .toList(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // Offers section
                Column(children: [
                  sectionTitle(
                    "Offers", /*ontap*/
                  ),
                  SizedBox(height: 5),
                  SizedBox(
                      height: 170,
                      child: ListView(
                          scrollDirection: Axis.horizontal,
                          children:
                              offers.map((offer) => offerCard(offer)).toList()))
                ]),

                SizedBox(height: 10),

                //Customer Reviews section
                Column(
                  children: [
                    customerReviews(),
                  ],
                )
              ],
            )),
      ),
    );
  }

  Widget sectionTitle(
    String title,
    /*VoidCallback onTap*/
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(
            onPressed: () {},
            child: Text(
              'See All',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            ))
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
            Text(vendor['name']!,
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              vendor['description']!,
              style: TextStyle(fontSize: 12),
            ),
            ElevatedButton(
                onPressed: () {}, child: Text('View ${vendor['name']}'))
          ],
        ),
      ),
    );
  }

  Widget offerCard(Map<String, dynamic> offer) {
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
              // Image.asset(offer['image'], height: 50, fit: BoxFit.cover),
              Text(offer['title'],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                offer['speech'],
                style: TextStyle(),
              ),
              Text(offer['description'], style: TextStyle()),
              // Text(
              //   offer['stallNo'],
              //   style: TextStyle(),
              // ),
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
              Text('4.0',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
          Text('Mevis Katumi - Customer',
              style: TextStyle(fontWeight: FontWeight.bold)),
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
  {
    'name': 'Hassan Abdi',
    'description': 'Welcome customer, everyone says how my bananas are sweet',
    'image': 'assets/vendor1.png'
  },
  {
    'name': 'Maria Halima',
    'description': 'Habari mimi ni muuza samaki',
    'image': 'assets/vendor2.png'
  },
  {
    'name': 'Susan Kamau',
    'description': 'Hello customer, welcome to my stand',
    'image': 'assets/vendor3.png'
  },
];

final List<Map<String, dynamic>> offers = [
  {
    'title': "It's Mango Season!",
    'speech': 'Mama Salama says',
    'description': 'Get a 30% discount for every 10 mangoes you buy',
    'stallNo': 20,
    'image': 'assets/mango.png'
  },
  {
    'title': "Coconuts from Mombasa!",
    'speech': 'Hassan says',
    'description': 'For every 5 coconuts you buy get 1 free...',
    'stallNo': 104,
    'image': 'assets/coconut.png'
  },
  {
    'title': 'Potatoes perfect for fries!',
    'speech': 'Mr Kinyanjui says',
    'description':
        'Get a bag of fresh potatoes from Nyandarua at a 10% discount per kg. Hurry while stocks last!',
    'stallNo': 003,
    'image': 'assets/potatoes.png'
  },
  {
    'title': 'Get the best fish in the market!',
    'speech': 'Mrs Onyango says',
    'description': 'Get the best fish in the market at a fair price!',
    'stallNo': 403,
    'image': 'assets/fish.png'
  }
];
