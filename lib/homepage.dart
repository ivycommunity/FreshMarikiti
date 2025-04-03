import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/drawer.dart';
import 'package:marikiti/Widgets/pages/product.dart';
import 'package:marikiti/Widgets/pages/Mycart.dart';
import 'package:marikiti/Widgets/pages/product.dart';
import 'package:marikiti/core/constants/appcolors.dart';
import 'dart:ui';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[50],
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
        child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CategoryItem(
                      name: 'Fruits',
                      imagePath: 'assets/fruits.jpg',
                      category: 'fruits',
                    ),
                    CategoryItem(
                        name: 'Vegetables',
                        imagePath: 'assets/vegetables.jpg',
                        category: 'vegetables'),
                    CategoryItem(
                      name: 'Dairy Products',
                      imagePath: 'assets/dairy.jpg',
                      category: 'dairy',
                    )
                  ],
                ),

                // Vendor section
                SectionTitle(title: 'Vendors List'),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: vendor.length,
                    itemBuilder: (context, index) {
                      return VendorCard(vendor: vendor[index]);
                    },
                  ),
                ),

                // Offers section
                SectionTitle(title: 'Offers'),
                SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: offer.length,
                      itemBuilder: (context, index) {
                        return OfferCard(offer: offer[index]);
                      },
                    )),

                SizedBox(height: 30),
                Divider(
                  color: Colors.white,
                  thickness: 1,
                  indent: 5, // Left spacing
                  endIndent: 5, // Right spacing
                ),
                SizedBox(height: 20),

                //Customer Reviews section
                CustomerReview(),
                SizedBox(height: 20),

                // Customer commment Section
                SizedBox(
                    height: 150,
                    child: PageView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: comment.length,
                        itemBuilder: (context, index) {
                          return CommentSection(comment: comment[index]);
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
}

class CategoryItem extends StatelessWidget {
  final String name;
  final String category;
  final String imagePath;
  const CategoryItem(
      {required this.name,
      required this.imagePath,
      required this.category,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              String category = _getCategoryKey(name);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ProductPage(title: name, category: category)));
            }, // Navigate to category page
            child: CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(imagePath),
            ),
          ),
          const SizedBox(height: 5),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Converts display name into category key used in `ProductProvider`
  String _getCategoryKey(String name) {
    switch (name.toLowerCase()) {
      case "fruits":
        return "fruits";
      case "dairy products":
        return "dairy";
      case "vegetables":
        return "veggies";
      default:
        return "";
    }
  }
}

// Section Title Widget
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      TextButton(
          onPressed: () {},
          child: Text(
            'See All',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ))
    ]);
  }
}

class VendorCard extends StatelessWidget {
  final Vendor vendor;
  const VendorCard({required this.vendor, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        width: 135,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Column(
          children: [
            SizedBox(
                width: 135,
                height: 110,
                child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Image.asset(vendor.imagePath, fit: BoxFit.cover))),
            SizedBox(height: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(vendor.name,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    vendor.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                  Spacer(),
                  SizedBox(
                      height: 30,
                      child: ElevatedButton(
                          onPressed: () {},
                          child: Text(
                            'View ${vendor.name}',
                            style: TextStyle(fontSize: 10),
                          ),
                          style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red[300],
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
}

class OfferCard extends StatelessWidget {
  final Offer offer;
  const OfferCard({required this.offer, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: offer.color,
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
                      Text(offer.title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white)),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        offer.speech,
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Flexible(
                          child: Text(
                        offer.description,
                        style: TextStyle(fontSize: 12, color: Colors.white),
                        softWrap: true,
                      )),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        offer.stallNo,
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
                  child: Image.asset(offer.imagePath,
                      width: 100, fit: BoxFit.cover)),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerReview extends StatelessWidget {
  const CustomerReview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow[100],
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

class CommentSection extends StatelessWidget {
  final Comment comment;
  const CommentSection({required this.comment, super.key});

  @override
  Widget build(BuildContext context) {
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
                      '${comment.name} - Customer',
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
                    Text(comment.comment ?? 'No comment available',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 5),
                    Text(
                      comment.description ?? 'No description available',
                      style:
                          TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}

// Sample data
class Vendor {
  final String name;
  final String description;
  final String imagePath;
  Vendor(
      {required this.name, required this.description, required this.imagePath});
}

class Offer {
  final String title;
  final String speech;
  final String description;
  final String stallNo;
  final String imagePath;
  final Color color;
  Offer(
      {required this.title,
      required this.speech,
      required this.description,
      required this.stallNo,
      required this.imagePath,
      required this.color});
}

class Comment {
  final String name;
  final String comment;
  final String description;
  final String imagePath;

  Comment(
      {required this.name,
      required this.comment,
      required this.description,
      required this.imagePath});
}

final List<Vendor> vendor = [
  Vendor(
      name: 'Hassan Abdi',
      description: 'Welcome customer, everyone says how my bananas are sweet',
      imagePath: 'assets/vendor1.jpeg'),
  Vendor(
      name: 'Maria Halima',
      description:
          'Habari mimi ni muuza samaki hodari. Wanunuzi wangu hufurahi',
      imagePath: 'assets/vendor2.jpeg'),
  Vendor(
      name: 'Susan Kamau',
      description: 'Hello customer, welcome to my stand',
      imagePath: 'assets/vendor3.jpeg')
];

final List<Offer> offer = [
  Offer(
    title: "It's Mango Season!",
    speech: 'Mama Salama says',
    description: 'Get a 30% discount for every 10 mangoes you buy',
    stallNo: 'Stall No 20',
    imagePath: 'assets/mangoes.jpeg',
    color: Colors.red.shade300,
  ),
  Offer(
      title: "Coconuts from Mombasa!",
      speech: 'Hassan says',
      description: 'For every 5 coconuts you buy get 1 free...',
      stallNo: 'Stall No 104',
      imagePath: 'assets/coconuts.jpeg',
      color: Colors.green.shade300),
  Offer(
      title: 'Potatoes perfect for fries!',
      speech: 'Mr Kinyanjui says',
      description:
          'Get a bag of fresh potatoes from Nyandarua at a 10% discount per kg. Hurry while stocks last!',
      stallNo: 'Stall No 003',
      imagePath: 'assets/potatoes.jpeg',
      color: Colors.red.shade800),
  Offer(
      title: 'Get the best fish in the market!',
      speech: 'Mrs Onyango says',
      description: 'Get the best fish in the market at a fair price!',
      stallNo: 'Stall No 403',
      imagePath: 'assets/fish.jpg',
      color: Colors.red)
];

final List<Comment> comment = [
  Comment(
      name: 'Mevis Katami',
      imagePath: 'assets/customer1.jpeg',
      comment: '"Very Convenient"',
      description:
          'I love that I get to have my groceries delivered to me every month without fail'),
  Comment(
      name: 'Kristian Ochola',
      imagePath: 'assets/customer2.jpeg',
      comment: '"Use friendly',
      description: 'A very briliant app!')
];
