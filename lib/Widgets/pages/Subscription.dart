import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/drawer.dart';

class Subscription extends StatefulWidget {
  const Subscription({super.key});

  @override
  State<Subscription> createState() => _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  final TextEditingController nameController =
      TextEditingController(text: "Ann Wanjiku");
  final TextEditingController emailController =
      TextEditingController(text: "annwanjiku@example.com");
  final TextEditingController addressController =
      TextEditingController(text: "Siwaka Estate-Makadara");
  final TextEditingController subscriptionController =
      TextEditingController(text: "Weekly");
  final TextEditingController timeController =
      TextEditingController(text: " Wednesday 6:00pm");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: Builder(
            builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  Scaffold.of(context).openDrawer;
                })),
        title: const Text("ANN'S SUBSCRIPTION"),
        centerTitle: true,
        actions: [],
      ),
      drawer: FreshMarikitiDrawer(),
      body: Column(
        children: [
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text("PERSONAL DETAILS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                  SizedBox(height: 10),
                  buildEditableField("Name", nameController),
                  buildEditableField("E-mail", emailController),
                  buildEditableField("Delivery Address", addressController),
                  buildEditableField(
                      "Type of Subscription", subscriptionController),
                  buildEditableField("Time of Delivery", timeController)
                ],
              )),
        ],
      ),
    );
  }

  Widget buildEditableField(String label, TextEditingController controller,
      {bool isSave = false}) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(children: [
          Expanded(
            child: TextField(
                style: TextStyle(color: Colors.grey),
                controller: controller,
                decoration: InputDecoration(
                    labelText: label, border: OutlineInputBorder())),
          ),
          SizedBox(width: 10),
          ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(40, 55),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child:
                  Text("EDIT", style: TextStyle(fontWeight: FontWeight.bold)))
        ]));
  }
}
