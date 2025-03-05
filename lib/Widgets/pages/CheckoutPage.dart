import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/pages/Ordersuccess.dart';
import 'package:marikiti/core/constants/providers/Checkoutprovider.dart';
import 'package:provider/provider.dart';

class CheckoutPage extends StatelessWidget {
  final List<String> paymentMethods = ["M-Pesa", "Cash on Delivery"];

  @override
  Widget build(BuildContext context) {
    final checkoutProvider = Provider.of<CheckoutProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios, color: Colors.white,)),
        title: Text(
          "Checkout",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("DELIVERY ADDRESS"),
            Text("Siwaka Estate - Madarka", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            _buildSectionTitle("TYPE OF SUBSCRIPTION"),
            Text("Weekly", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            _buildSectionTitle("TIME OF DELIVERY"),
            Text("Wednesday 6:00 PM", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // Navigate to Subscription Page
              },
              child: Text(
                "Change in the subscription page",
                style: TextStyle(
                    color: Colors.blue, decoration: TextDecoration.none),
              ),
            ),
            SizedBox(height: 15),
            _buildSectionTitle("PAYMENT METHOD"),
            DropdownButtonFormField<String>(
              value: checkoutProvider.selectedPaymentMethod.isNotEmpty
                  ? checkoutProvider.selectedPaymentMethod
                  : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
              ),
              items: paymentMethods.map((method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                checkoutProvider.setPaymentMethod(value!);
              },
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.redAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text("Please remember to only pay after delivery."),
                ),
              ],
            ),
            Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: checkoutProvider.isPaymentSelected
                  ? () {
                     /* if (checkoutProvider.selectedPaymentMethod == "M-Pesa") {
                        checkoutProvider.initiateMpesaPayment(context);
                      }*/
                    
   Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => OrderSuccessPage()));

                      
                   
                    }
                  : null,
              child: Text(
                "COMPLETE",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
