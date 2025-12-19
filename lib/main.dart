import 'package:flutter/material.dart';
import 'screens/admin_login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/storage.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: Storage.getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AdminLoginScreen();
          }
          return const DashboardScreen();
        },
      ),
    );
  }
}
