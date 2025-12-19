import 'package:flutter/material.dart';
import '../utils/storage.dart';
import 'admin_login_screen.dart';
import 'create_event_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Storage.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminLoginScreen()),
              );
            },
          )
        ],
      ),
      body: Center(
          child: ElevatedButton(
            child: const Text('Create Sunday Service'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              );
            },
          )
      ),
    );
  }
}
