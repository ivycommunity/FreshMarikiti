import 'package:flutter/material.dart';

class HomePage2 extends StatelessWidget {
  const HomePage2({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(
            "Earnings",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          automaticallyImplyLeading: false,
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ],
          leading: IconButton(
            onPressed: () {
              //Navigator.push(
              //context, MaterialPageRoute(builder: (context) => CartPage()));
            },
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.notifications, color: Colors.white),
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.black, // Underline color
            labelColor: Colors.black, // Selected tab color
            unselectedLabelColor: Colors.grey, // Unselected tab color
            tabs: [
              Tab(text: "Items"),
              Tab(text: "Orders"),
              Tab(text: "Rating"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Content for "Items" tab
            ItemsTab(),

            // Content for "Orders" tab
            Center(child: Text("Ongoing order"),),
            OrdersTab(),

            // Content for "Rating" tab
            Center(child: Text("Rating Content"),),
            RatingTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Define the action when the button is pressed
            print("Profile Button Pressed");
          },
          child: Icon(Icons.person),
          //backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}


class ItemsTab extends StatelessWidget {
  const ItemsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      );
  }
}


class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(

    );
  }
}

class RatingTab extends StatelessWidget {
  const RatingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      
    );
  }
}
