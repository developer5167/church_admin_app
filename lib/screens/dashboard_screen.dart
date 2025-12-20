import 'dart:convert';
import 'dart:io';
import 'package:church_admin_app/services/api_service.dart';
import 'package:church_admin_app/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'admin_login_screen.dart';
import 'attendance_screen.dart';
import 'create_event_screen.dart';
import 'qr_view_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic>? events;
  String? _token;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadData(date: _selectedDate);
  }
  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  void loadData({DateTime? date}) async {
    try { 
      final useDate = date ?? _selectedDate;
      final dateStr = _formatDate(useDate);
      final result = await ApiService.getEventsByDate(dateStr);
      print('Events for $dateStr: ${jsonEncode(result)}');
      if (mounted) {
        setState(() => events = result);
      }
    }
    catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
       loadData(date: picked);
    }
  }

  void exportToCsv(dynamic event) async {
    try {
      final csvData = await ApiService.exportAttendanceCSV(event['id']);
      String filePath = '';

      if (Platform.isAndroid) {
        // Request storage permission
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }

        // On Android 11+ apps may need manage external storage
        if (!storageStatus.isGranted) {
          final mgr = await Permission.manageExternalStorage.request();
          if (!mgr.isGranted) {
            // fallback to app documents directory
            final directory = await getApplicationDocumentsDirectory();
            filePath = p.join(directory.path, '${event['name']}_attendance.csv');
          }
        }

        if (filePath.isEmpty) {
          try {
            final downloads = await getExternalStorageDirectories(type: StorageDirectory.downloads);
            String? downloadPath = downloads?.first.path;
            if (downloadPath == null || downloadPath.isEmpty) {
              downloadPath = '/storage/emulated/0/Download';
            }
            filePath = p.join(downloadPath, '${event['name']}_attendance.csv');
          } catch (_) {
            final directory = await getApplicationDocumentsDirectory();
            filePath = p.join(directory.path, '${event['name']}_attendance.csv');
          }
        }

        final file = File(filePath);
        await file.create(recursive: true);
        await file.writeAsString(csvData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV saved to $filePath')),
        );
      } else if (Platform.isIOS) {
        // iOS: write to temp and open share sheet so user can save to Files/Downloads
        final directory = await getTemporaryDirectory();
        filePath = p.join(directory.path, '${event['name']}_attendance.csv');
        final file = File(filePath);
        await file.writeAsString(csvData);

        await Share.shareXFiles([XFile(filePath)], text: 'Attendance CSV for ${event['name']}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share dialog opened to save CSV')),
        );
      } else {
        // Other platforms: save to documents
        final directory = await getApplicationDocumentsDirectory();
        filePath = p.join(directory.path, '${event['name']}_attendance.csv');
        final file = File(filePath);
        await file.writeAsString(csvData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV saved to $filePath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }

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
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
              );
            },
          )
        ],
      ),
      body: events == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Date: ${_formatDate(_selectedDate)}', style: const TextStyle(fontSize: 16)),
                      ElevatedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Pick Date'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: events!.length,
                    itemBuilder: (context, index) {
                      final event = events![index];
                      final services = event['services'] as List<dynamic>;

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Date: ${event['event_date']}'),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () => exportToCsv(event),
                                    child: const Text('Export to CSV'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (services.isNotEmpty)
                                ...services.map((service) {
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Service ${service['service_code']} at ${service['service_time']}',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                          ),
                                          const SizedBox(height: 8),
                                          FutureBuilder(
                                            future: ApiService.getAttendance(service['id'],),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Text('Attendees: Loading...');
                                              }
                                              if (snapshot.hasError || !snapshot.hasData) {
                                                return const Text('Attendees: Error');
                                              }
                                              final count = snapshot.data?['count'] ?? 0;
                                              return Text('Attendees: $count');
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => AttendanceScreen(
                                                        serviceId: service['id'],
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Text('View Attendance'),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => QrViewScreen(
                                                        qrUrl: service['qrUrl'],
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Text('View QR'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              if (services.isEmpty)
                                const Text('No services for this event.'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    child: const Text('Create Sunday Service'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateEventScreen()),
                      ).then((_) => loadData());
                    },
                  ),
                )
              ],
            ),
    );
  }
}
