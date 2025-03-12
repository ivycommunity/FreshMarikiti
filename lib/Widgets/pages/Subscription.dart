import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/drawer.dart';
import 'package:provider/provider.dart';
import 'package:marikiti/models/subscriptionmodel.dart';
import 'package:marikiti/Widgets/pages/Profile.dart';

class Subscription extends StatefulWidget {
  Subscription({super.key});

  @override
  State<Subscription> createState() => _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController subscriptionController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.green,
            elevation: 0,
            leading: Builder(
                builder: (context) => IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: Icon(
                      Icons.menu,
                      color: Colors.black,
                    ))),
            title: const Text("ANN'S SUBSCRIPTION"),
            centerTitle: true,
            actions: []),
        drawer: FreshMarikitiDrawer(),
        body: Container(
          padding: EdgeInsets.all(16.0),
          color: Colors.green[50],
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                buildPersonalDetailsSection(),
                SizedBox(height: 20),
                buildSubscriptionItemsSection(context),
              ],
            ),
          ),
        ));
  }

  Widget buildPersonalDetailsSection() {
    return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("PERSONAL DETAILS",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            buildEditableField("Name", nameController, hintText: "Ann Wanjiku"),
            buildEditableField("Email", emailController,
                hintText: "annwanjiku@example.com"),
            buildEditableField("Delivery Address", addressController,
                hintText: "Siwaka Estate-Makadara", isSave: true),
            buildEditableField("Type of Subscription", subscriptionController,
                hintText: "Weekly"),
            buildEditableField("Time of Subscription", timeController,
                hintText: "Wedensday 6.00pm"),
          ],
        ));
  }

  Widget buildEditableField(String label, TextEditingController controller,
      {bool isSave = false, String hintText = ""}) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
              child: Text(label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.green.shade400, width: 2),
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.green.shade800, width: 2),
                                borderRadius: BorderRadius.circular(12)))),
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isSave ? "SAVE" : "EDIT")),
                )
              ],
            ),
          ],
        ));
  }

  Widget buildSubscriptionItemsSection(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context);

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("SUBSCRIPTION ITEMS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: provider.subscriptionItems.length,
              itemBuilder: (context, index) {
                final SubscriptionItem item = provider.subscriptionItems[index];
                return buildSubscriptionItem(context, item, index);
              },
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("ADD MORE ITEMS"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSubscriptionItem(
      BuildContext context, SubscriptionItem item, int index) {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Card(
        color: Colors.green.shade400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Image.asset(item.image, width: 50, height: 50),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("From: ${item.seller}",
                        style: TextStyle(color: Colors.white)),
                    Text("Ksh: ${item.price.toString()}",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              Container(
                height: 28,
                alignment: Alignment.center,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, color: Colors.black),
                      padding: EdgeInsets.zero,
                      onPressed: () => provider.reduceItems(index),
                    ),
                    Text("${item.quantity}",
                        style: TextStyle(color: Colors.black)),
                    IconButton(
                        icon: Icon(Icons.add, color: Colors.black),
                        padding: EdgeInsets.zero,
                        onPressed: () => provider.increaseItems(index))
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                      icon: Icon(Icons.delete, color: Colors.black),
                      onPressed: () => provider.removeItem(index)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
