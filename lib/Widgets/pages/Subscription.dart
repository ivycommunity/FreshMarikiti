import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/Widgets.dart';
import 'package:marikiti/core/constants/providers/Subscriptionprovider.dart';
import 'package:provider/provider.dart';
import 'package:marikiti/Widgets/drawer.dart';
import 'package:marikiti/Widgets/pages/Mycart.dart';
import 'package:marikiti/core/constants/appcolors.dart';


class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<Subscriptionprovider>(context);

    return Scaffold(
      backgroundColor: lightyellow,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  CartPage()),
              );
            },
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.shopping_cart, color: Colors.black),
            ),
          ),
        ],
        title: const Text('Subscription'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
        ),
      ),
      drawer: const FreshMarikitiDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PERSONAL DETAILS",
                    
                    style: TextStyle(
                    
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 10),
          
                  
                  EditableField(label: "Name", hintText: "Ann Wanjiku", controller: provider.nameController),
                  EditableField(label: "E-mail", hintText: "annwanjiku@example.com", controller: provider.emailController),
                  EditableField(label: "Delivery Address", hintText: "Enter your address", controller: provider.addressController, isSaveButton: true),
                  EditableField(label: "Type of Subscription", hintText: "Weekly", controller: provider.subscriptionTypeController),
                  EditableField(label: "Delivery Time", hintText: "Wednesday 6:00pm", controller: provider.deliveryTimeController),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
