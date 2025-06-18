import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void showSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

void httpErrorHandle({
  required http.Response response,
  required BuildContext context,
  required VoidCallback onSuccess,
}) {
  try {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      onSuccess();
    } else {
      String errorMessage;
      try {
        final responseBody = jsonDecode(response.body);
        if (responseBody is String) {
          errorMessage = responseBody;
        } else {
          errorMessage = responseBody['message'] ?? responseBody['error'] ?? 'Something went wrong';
        }
      } catch (e) {
        errorMessage = response.body;
      }
      showSnackBar(context, errorMessage);
    }
  } catch (e) {
    showSnackBar(context, e.toString());
  }
}