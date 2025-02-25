import 'package:flutter/material.dart';
import 'package:marikiti/models/authlogin.dart';
import 'package:provider/provider.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MariktiauthProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Fresh Marikiti",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            
            TextField(
              decoration: const InputDecoration(labelText: "Email"),
              onChanged: (value) => authProvider.setEmail(value),
            ),
            
            const SizedBox(height: 10),
            
            TextField(
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
              onChanged: (value) => authProvider.setPassword(value),
            ),
            
            const SizedBox(height: 20),
            
            authProvider.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () => authProvider.login(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: const Text("LOGIN"),
                  ),

            const SizedBox(height: 20),

            const Text("Don't have an account? Sign up"),
          ],
        ),
      ),
    );
  }
}
