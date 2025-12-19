import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';

class AttendanceScreen extends StatefulWidget {
  final String serviceId;
  const AttendanceScreen({super.key, required this.serviceId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    final token = await Storage.getToken();
    final result =
    await ApiService.getAttendance(widget.serviceId, token!);

    setState(() => data = result);
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance (${data!['count']})'),
      ),
      body: ListView.builder(
        itemCount: data!['attendees'].length,
        itemBuilder: (_, i) {
          final a = data!['attendees'][i];
          return ListTile(
            title: Text(a['full_name'] ?? 'Unknown'),
            subtitle: Text(a['phone']),
            trailing: Text(a['submitted_at']),
          );
        },
      ),
    );
  }
}
