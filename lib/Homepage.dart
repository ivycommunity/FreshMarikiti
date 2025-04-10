import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/drawer.dart';
import 'package:marikiti/Widgets/pages/Shop.dart';
import 'package:marikiti/Widgets/pages/Mycart.dart';
import 'package:marikiti/core/constants/appcolors.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.lightGreen[50],
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => CartPage()));
            },
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.shopping_cart, color: Colors.black),
            ),
          ),
        ],
        title: Text(
          "Fresh Marikiti",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
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
        child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    categoryItem('Fruits', 'assets/fruits.jpg'),
                    categoryItem("Vegies", 'assets/vegetables.jpg'),
                    categoryItem("Dairy Products", 'assets/dairy.jpg')
                  ],
                ),

                sectionTitle(
                  "Vendors List", /*ontap*/
                ),
                // Vendor section
                SizedBox(
                  height: 220,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children:
                        vendors.map((vendor) => vendorCard(vendor)).toList(),
                  ),
                ),

                // Offers section

                sectionTitle(
                  "Offers", /*ontap*/
                ),
                SizedBox(
                    height: 150,
                    child: ListView(
                        scrollDirection: Axis.horizontal,
                        children:
                            offers.map((offer) => offerCard(offer)).toList())),

                SizedBox(height: 30),
                Divider(
                  color: Colors.white,
                  thickness: 1,
                  indent: 5, // Left spacing
                  endIndent: 5, // Right spacing
                ),
                SizedBox(height: 20),

                //Customer Reviews section

                customerReviews(),
                SizedBox(height: 20),

                // Customer commment Section
                SizedBox(
                    height: 150,
                    child: PageView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return commentSection(comments[index]);
                        })),
                SizedBox(height: 15),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text('See More Reviews'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
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
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        TextButton(
            onPressed: () {},
            child: Text(
              'See All',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ))
      ],
    );
  }

  Widget categoryItem(String name, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => OrderPage()));
            },
            child: CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(imagePath),
            ),
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
        width: 135,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Column(
          children: [
            SizedBox(
                width: 135,
                height: 110,
                // vendorCard image
                child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Image.asset(vendor['image']!, fit: BoxFit.cover))),
            SizedBox(height: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(vendor['name']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      )),
                  Text(
                    vendor['description']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Spacer(),
                  SizedBox(
                      height: 30,
                      child: ElevatedButton(
                          onPressed: () {},
                          child: Text(
                            'View ${vendor['name']}',
                            style: TextStyle(fontSize: 10),
                          ),
                          style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8)))),
                  SizedBox(height: 10)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget offerCard(Map<String, dynamic> offer) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: offer['color'],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  width: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(offer['title']!,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white)),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        offer['speech']!,
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Flexible(
                          child: Text(
                        offer['description']!,
                        style: TextStyle(fontSize: 12, color: Colors.white),
                        softWrap: true,
                      )),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        offer['stallNo']!,
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                          height: 22,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: ElevatedButton(
                                onPressed: () {},
                                child: Text('View Offer'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.white,
                                )),
                          )),
                    ],
                  ),
                ),
              ),
              ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  child: Image.asset(offer['image']!,
                      width: 100, fit: BoxFit.cover)),
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
        color: Color(0xFF9FD0B9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Reviews',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Text('4.0',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              SizedBox(width: 10),
              Icon(Icons.star, color: Colors.yellow[700]),
              Icon(Icons.star, color: Colors.yellow[700]),
              Icon(Icons.star, color: Colors.yellow[700]),
              Icon(Icons.star, color: Colors.yellow[700]),
              Icon(Icons.star_half, color: Colors.yellow[700]),
            ],
          ),
          SizedBox(height: 5),
          Text('BASED ON 300 REVIEWS',
              style:
                  TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
        ],
      ),
    );
  }
}

Widget commentSection(Map<String, String> comments) {
  return Container(
      decoration: BoxDecoration(color: Colors.transparent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 8, 8.0),
            child: CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/fruits.jpg'),
            ),
          ),
          // SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${comments['name']} - Customer',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700]),
                      Icon(Icons.star, color: Colors.yellow[700]),
                      Icon(Icons.star, color: Colors.yellow[700]),
                      Icon(Icons.star, color: Colors.yellow[700]),
                      Icon(Icons.star, color: Colors.yellow[700]),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(comments['comment'] ?? 'No comment available',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 5),
                  Text(
                    comments['description'] ?? 'No description available',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ));
}

// Sanple data

final List<Map<String, String>> vendors = [
  {
    'name': 'Hassan Abdi',
    'description': 'Welcome customer, everyone says how my bananas are sweet',
    'image': 'assets/vendor1.jpeg'
  },
  {
    'name': 'Maria Halima',
    'description':
        'Habari mimi ni muuza samaki hodari. Wanunuzi wangu hufurahi',
    'image': 'assets/vendor2.jpeg'
  },
  {
    'name': 'Susan Kamau',
    'description': 'Hello customer, welcome to my stand',
    'image': 'assets/vendor3.jpeg'
  },
];

final List<Map<String, dynamic>> offers = [
  {
    'title': "It's Mango Season!",
    'speech': 'Mama Salama says',
    'description': 'Get a 30% discount for every 10 mangoes you buy',
    'stallNo': 'Stall No 20',
    'image': 'assets/mangoes.jpeg',
    'color': Colors.red[300],
  },
  {
    'title': "Coconuts from Mombasa!",
    'speech': 'Hassan says',
    'description': 'For every 5 coconuts you buy get 1 free...',
    'stallNo': 'Stall No 104',
    'image': 'assets/coconuts.jpeg',
    'color': Colors.green[300]
  },
  {
    'title': 'Potatoes perfect for fries!',
    'speech': 'Mr Kinyanjui says',
    'description':
        'Get a bag of fresh potatoes from Nyandarua at a 10% discount per kg. Hurry while stocks last!',
    'stallNo': 'Stall No 003',
    'image': 'assets/potatoes.jpeg',
    'color': Colors.red[800]
  },
  {
    'title': 'Get the best fish in the market!',
    'speech': 'Mrs Onyango says',
    'description': 'Get the best fish in the market at a fair price!',
    'stallNo': 'Stall No 403',
    'image': 'assets/fish.jpg',
    'color': Colors.red
  }
];

List<Map<String, String>> comments = [
  {
    'name': 'Mevis Katami',
    'image': 'assets/customer1.jpeg',
    'comment': '"Very Convenient"',
    'description':
        'I love that I get to have my groceries delivered to me every month without fail'
  },
  {
    'name': 'Kristian Ochola',
    'image': 'assets/customer2.jpeg',
    'comment': '"Use friendly',
    'description': 'A very briliant app!'
  }
];
