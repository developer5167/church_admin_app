import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';
import 'create_service_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final nameCtrl = TextEditingController(text: 'Sunday Service');
  DateTime selectedDate = DateTime.now();
  bool loading = false;

  void createEvent() async {
    setState(() => loading = true);
    final token = await Storage.getToken();

    final eventId = await ApiService.createEvent(
      nameCtrl.text,
      selectedDate.toIso8601String().split('T')[0],
      token!,
    );

    setState(() => loading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CreateServiceScreen(eventId: eventId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Event Name'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              child: Text(
                'Select Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : createEvent,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}
