import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/pages/ChangePassword.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios)),
          title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: Text('Change Language'),
                leading: Icon(Icons.language),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showLanguageSelectionDialog(context);
                },
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                title: Text('Change Password'),
                leading: Icon(Icons.lock),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Changepassword()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('English'),
                onTap: () {
                  // Set language to English
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Kiswahili'),
                onTap: () {
                  // Set language to Kiswahili
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
