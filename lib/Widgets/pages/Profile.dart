import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/drawer.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Details '),
        leading: Builder(builder: (context)=>IconButton(onPressed: (){
            Scaffold.of(context).openDrawer();
        }, icon: Icon(Icons.menu, color: Colors.white,))),
         actions: [
             IconButton(onPressed: (){}, icon: Icon(Icons.menu),), 
             
         ],),

      
      drawer:FreshMarikitiDrawer(),
      body: SingleChildScrollView(
          child: Column(
                children: [
                     
                ],
          ),
      )
    );
  }
}
