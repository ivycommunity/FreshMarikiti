import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/drawer.dart';
import 'package:marikiti/Widgets/pages/Mycart.dart';

class Vendorsdetails extends StatefulWidget {
  const Vendorsdetails({super.key});

  @override
  State<Vendorsdetails> createState() => _VendorsdetailsState();
}

class _VendorsdetailsState extends State<Vendorsdetails> {
  void shoppingcart() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Vendors Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[900],
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => shoppingcart(),
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.shopping_cart, color: Colors.black),
            ),
          ),
        ],
      ),
      drawer: const FreshMarikitiDrawer(),
      body: Stack(
        children: [
          // Green background with curve
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: GreenClipper(),
              child: Container(
                height: 100, 
                color: Colors.green[800],
              ),
            ),
          ),

          // White container for vendor details
          Positioned(
            top: 130, 
            left: 20,
            right: 20,
            child: Column(
              children: [
        
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 45,
                    //backgroundImage: AssetImage("assets/vendor_image.jpg"),
                  ),
                ),
                const SizedBox(height: 10),

                
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: const [
                      Text(
                        "HASSAN ABDI",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                    
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Green ClipPath for the curved background
class GreenClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
