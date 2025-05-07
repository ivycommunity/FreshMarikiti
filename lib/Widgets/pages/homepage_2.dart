import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/home_page_drawer.dart';

class HomePage2 extends StatelessWidget {
  const HomePage2({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text(
            "Earnings",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          automaticallyImplyLeading: false,
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer(); // Opens the drawer
                },
              ),
            ),
          ],
          leading: IconButton(
            onPressed: () {
              // Navigator.push(
              // context, MaterialPageRoute(builder: (context) => CartPage()));
            },
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.notifications, color: Colors.white),
            ),
          ),
          bottom: const TabBar(
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
        
        endDrawer: const HomePageDrawer(),
        
        body: const TabBarView(
          children: [
            // Content for "Items" tab
            ItemsTab(),

            // Content for "Orders" tab
            OrdersTab(),

            // Content for "Rating" tab
            RatingTab(),
          ],
        ),
        
        // Using a Stack for multiple floating action buttons
        floatingActionButton: Stack(
          children: [
            // Left positioned button (add button)
            Positioned(
              left: 30,
              bottom: 0,
              child: FloatingActionButton(
                heroTag: "btn1", // Required to avoid Flutter error with multiple FABs
                onPressed: () {
                  print("Add Button Pressed");
                },
                child: const Icon(Icons.add),
              ),
            ),
            
            // Center positioned button (profile button)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.center,
                child: FloatingActionButton(
                  heroTag: "btn2",
                  onPressed: () {
                    print("Profile Button Pressed");
                  },
                  child: const Icon(Icons.person),
                ),
              ),
            ),
            
            // Right positioned button (messages button)
            Positioned(
              right: 30,
              bottom: 0,
              child: FloatingActionButton(
                heroTag: "btn3",
                onPressed: () {
                  print("Messages Button Pressed");
                },
                child: const Icon(Icons.message),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemsTab extends StatelessWidget {
  const ItemsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Items Content"),
    );
  }
}

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Orders Content"),
    );
  }
}

class RatingTab extends StatelessWidget {
  const RatingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Rating Content"),
    );
  }
}