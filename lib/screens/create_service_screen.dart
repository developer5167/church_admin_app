import 'package:church_admin_app/screens/qr_view_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';
import 'attendance_screen.dart';

class CreateServiceScreen extends StatefulWidget {
  final String eventId;
  const CreateServiceScreen({super.key, required this.eventId});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final codeCtrl = TextEditingController();
  TimeOfDay? time;
  List<Map<String, dynamic>> services = [];

  void addService() async {
    if (time == null) return;

    final token = await Storage.getToken();

    final result = await ApiService.createService(
      widget.eventId,
      codeCtrl.text,
      '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
    );

    setState(() {
      services.add(result);
      codeCtrl.clear();
      time = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Services')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: codeCtrl,
              decoration:
              const InputDecoration(labelText: 'Service Code (SS1, SS2)'),
            ),
            ElevatedButton(
              child: Text(
                time == null
                    ? 'Pick Service Time'
                    : 'Time: ${time!.format(context)}',
              ),
              onPressed: () async {
                final picked =
                await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null) {
                  setState(() => time = picked);
                }
              },
            ),
            ElevatedButton(
              onPressed: addService,
              child: const Text('Add Service'),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: services.length,
                itemBuilder: (_, i) {
                  return ListTile(
                    title: Text('Service QR'),
                    subtitle: Text(services[i]['qrUrl']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.qr_code),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QrViewScreen(qrUrl: services[i]['qrUrl']),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.list),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AttendanceScreen(
                                  serviceId: services[i]['serviceId'],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export Attendance CSV'),
              onPressed: () async {
                final token = await Storage.getToken();
                final url =
                    'http://172.20.10.2:4000/api/admin/attendance/export/${widget.eventId}';

                // simplest approach for now
                // open this URL in browser
                // CSV will auto-download
              },
            ),


          ],
        ),
      ),
    );
  }
}
