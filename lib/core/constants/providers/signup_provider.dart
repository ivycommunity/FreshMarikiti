import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  User? _user;

  bool get isLoading => _isLoading;
  User? get user => _user;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  /// 🔹 **Sign-Up with Email & Password**
  Future<String?> signUp(String email, String password, String username) async {
    try {
      // Check if user already exists
      var userCheck = await _auth.fetchSignInMethodsForEmail(email);
      if (userCheck.isNotEmpty) {
        return "This user is already registered.";
      }

      // Create user in Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user details in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "username": username,
        "email": email,
        "uid": userCredential.user!.uid,
        "createdAt": DateTime.now(),
      });

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  /// 🔹 **Sign-In with Email & Password**
  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// 🔹 **Google Sign-In**
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return; // User canceled sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists) {
        await _firestore.collection("users").doc(userCredential.user!.uid).set({
          "username": googleUser.displayName ?? "No Name",
          "email": googleUser.email,
          "uid": userCredential.user!.uid,
          "createdAt": DateTime.now(),
        });
      }

      _isLoading = false;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-in successful!")),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

Future<String?> login(String email, String password, BuildContext context) async {
  try {
    _isLoading = true;
    notifyListeners();

    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    _user = userCredential.user;
    _isLoading = false;
    notifyListeners();

    // Show full-screen loading before navigating
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Wait for 2 seconds before navigating
    await Future.delayed(const Duration(seconds: 2));

    // Close the loading dialog
    Navigator.of(context, rootNavigator: true).pop();

    // Navigate to Home Screen
    Navigator.pushReplacementNamed(context, '/home');

    return null; // Success
  } on FirebaseAuthException catch (e) {
    _isLoading = false;
    notifyListeners();

    String errorMessage;
    if (e.code == 'user-not-found') {
      errorMessage = "No user found for this email.";
    } else if (e.code == 'wrong-password') {
      errorMessage = "Incorrect password. Please try again.";
    } else {
      errorMessage = "Login failed: ${e.message}";
    }

    // ✅ Show an alert dialog for errors
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Failed "),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    return errorMessage;
  } catch (e) {
    _isLoading = false;
    notifyListeners();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unexpected Error"),
        content: Text("Something went wrong!!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    return "Unexpected error: ${e.toString()}";
  }
}


  // **Logout**
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
