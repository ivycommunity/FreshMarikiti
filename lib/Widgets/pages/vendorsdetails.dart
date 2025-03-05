import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/drawer.dart';

class VendorsDetails extends StatefulWidget {
  const VendorsDetails({super.key});

  @override
  State<VendorsDetails> createState() => _VendorsDetailsState();
}

class _VendorsDetailsState extends State<VendorsDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Vendor's Details"),
          backgroundColor: Colors.green[700],
          centerTitle: true,
        ),
         drawer: FreshMarikitiDrawer(),
         body: Stack(
            children: [
                Positioned(
                  top: 0,
                  left: 0, 
                  right: 0, 

                  
                  child: Container(
                    height: 250,
                     decoration: BoxDecoration(
                        color: Colors.green[700], 
                      
                    

                     ),
                  ),), 
                  // white space 
                  
            ],
         ),
    );
  }
}