import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CheckoutProvider extends ChangeNotifier {
  String _selectedPaymentMethod = "";
  bool _isProcessingPayment = false;

  String get selectedPaymentMethod => _selectedPaymentMethod;
  bool get isProcessingPayment => _isProcessingPayment;

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  bool get isPaymentSelected => _selectedPaymentMethod.isNotEmpty;

  Future<void> initiateMpesaPayment(BuildContext context) async {
    _isProcessingPayment = true;
    notifyListeners();

    final consumerKey = dotenv.env['MPESA_CONSUMER_KEY'];
    final consumerSecret = dotenv.env['MPESA_CONSUMER_SECRET'];
    final shortcode = dotenv.env['MPESA_SHORTCODE'];
    final passkey = dotenv.env['MPESA_PASSKEY'];
    final callbackUrl = dotenv.env['MPESA_CALLBACK_URL'];

    final phoneNumber = "25469797534"; 
    final amount = 100; 

    try {
      // Step 1: Get Access Token
      var authResponse = await http.get(
        Uri.parse("https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query"),
        headers: {
          "Authorization": "Basic ${base64Encode(utf8.encode("$consumerKey:$consumerSecret"))}"
        },
      );

      var authData = jsonDecode(authResponse.body);
      String accessToken = authData["access_token"];

      // Step 2: Initiate Payment
      var response = await http.post(
        Uri.parse("https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "BusinessShortCode": shortcode,
          "Password": base64Encode(utf8.encode("$shortcode$passkey${DateTime.now().millisecondsSinceEpoch}")),
          "Timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
          "TransactionType": "CustomerPayBillOnline",
          "Amount": amount,
          "PartyA": phoneNumber,
          "PartyB": shortcode,
          "PhoneNumber": phoneNumber,
          "CallBackURL": callbackUrl,
          "AccountReference": "FreshMarikiti",
          "TransactionDesc": "Payment for groceries , Fruits and Veggies"
        }),
      );

      var data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["ResponseCode"] == "0") {
      
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("M-Pesa payment initiated")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment failed: ${data['errorMessage']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("System error")));
    }

    _isProcessingPayment = false;
    notifyListeners();
  }
}
