import 'package:flutter/material.dart';
import 'package:marikiti/core/constants/providers/google_sign_in_provider.dart';
import 'package:marikiti/core/constants/providers/passwordprovider.dart';
import 'package:provider/provider.dart';

Widget buildTextField(String hintText, IconData icon,
    {bool obscureText = false}) {
  return TextField(
    obscureText: obscureText,
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.green[700]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green[700]!, width: 2),
      ),
    ),
  );
}

// Password Field
Widget passwordField(BuildContext context) {
  return Consumer<Passwordprovider>(
    builder: (context, passwordProvider, child) {
      return TextField(
        obscureText: passwordProvider.ispasswordvisisble,
        decoration: InputDecoration(
          hintText: "Password",
          prefixIcon: Icon(Icons.lock, color: Colors.green[700]),
          suffixIcon: IconButton(
            icon: Icon(
              passwordProvider.ispasswordvisisble
                  ? Icons.visibility_off
                  : Icons.visibility_outlined,
              color: Colors.green[700],
            ),
            onPressed: () {
              passwordProvider.viewPassword();
            },
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.green[700]!, width: 2),
          ),
        ),
      );
    },
  );
}
Widget googleSignInButton(BuildContext context) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(vertical: 13, horizontal: 10),
    ),
    onPressed: () {
      final provider = Provider.of<GoogleSignInProvider>(context, listen: false);
      provider.googleLogin();
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset("assets/Google.png", height: 24), // Add a Google logo in assets
        SizedBox(width: 10),
        Text(
          "Sign in with Google",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ],
    ),
  );
}
