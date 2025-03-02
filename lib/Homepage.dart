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
                child: Icon(Icons.shopping_cart, 
                color: Colors.black,),
              ))
        ],
        title: Text("Fresh Marikiti"),
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false,
        leading: Builder(
            builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                )),
      ),
      drawer: FreshMarikitiDrawer(),
    );
  }
}
