import 'package:flutter/material.dart';
import 'package:marikiti/core/constants/providers/passwordprovider.dart';
import 'package:marikiti/core/constants/providers/signup_provider.dart';
import 'package:provider/provider.dart';

Widget buildTextField(
  String hintText,
  IconData icon, {
  bool obscureText = false,
  required TextEditingController controller, // Fixed error
}) {
  return TextFormField(
    controller: controller, // Added controller
    obscureText: obscureText,
    validator: (value) {
      if (value == null || value.isEmpty) {
        return "Please enter your $hintText";
      }
      return null;
    },
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.green[700]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green[700]!, width: 2),
      ),
    ),
  );
}

// Password Field
Widget passwordField(BuildContext context, TextEditingController controller) {
  return Consumer<Passwordprovider>(
    builder: (context, passwordProvider, child) {
      return TextFormField(
        controller: controller,
        obscureText: passwordProvider.ispasswordvisisble,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter your password";
          } else if (value.length < 6) {
            return "Password must be at least 6 characters";
          }
          return null;
        },
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
            borderSide: const BorderSide(color: Colors.green, width: 2),
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
      final provider = Provider.of<AuthProvider>(context, listen: false);
      provider.signInWithGoogle(context);
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset("assets/Google.png",
            height: 24), // Add a Google logo in assets
        SizedBox(width: 10),
        Text(
          "Sign in with Google",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ],
    ),
  );
}
