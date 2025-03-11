import 'package:flutter/material.dart';

class userpage extends StatefulWidget {
  const userpage({super.key});

  @override
  State<userpage> createState() => _userpageState();
}

class _userpageState extends State<userpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
           children: [ 
             Container(
              width: 150,
              height: 20, 
              color: Colors.green,
             ), 
                  Container(
              width: 100,
              height: 10, 
              color: Colors.red,
             ),
                  Container(
              width: 50,
              height: 5, 
              color: Colors.black,
             ),
           ],
        ),
    );
  }
}
