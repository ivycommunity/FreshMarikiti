import 'package:flutter/material.dart';
import 'package:marikiti/Homepage.dart';
import 'package:marikiti/Widgets/Widgets.dart';
import 'package:marikiti/core/constants/View/auth/signup.dart';
import 'package:marikiti/core/constants/providers/Themeprovders.dart';
import 'package:marikiti/core/constants/providers/signup_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeprovider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final _formkey = GlobalKey<FormFieldState>();
    final TextEditingController passwordcontroller = TextEditingController();
    final TextEditingController emailcontroller = TextEditingController();
  

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formkey,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //to be replaced with the FreshMarikiti Logo
              Image.asset('assets/frehs-marikiti.png'),
                    const Text(
                      "Fresh Marikiti",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 20),
                    buildTextField("Email", Icons.person, controller: emailcontroller),
                    const SizedBox(height: 10),
                    passwordField(context, passwordcontroller),
                    const SizedBox(height: 10),

                    // Login Button
                    authProvider.isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => authProvider.login(emailcontroller.text, passwordcontroller.text, context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50, vertical: 15),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Don’t have an account?'),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignUpScreen()));
                          },
                          child: const Text(
                            " Sign up",
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // OR Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.black,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google Sign-In Button
                    googleSignInButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
