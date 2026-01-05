import 'dart:async';
import 'package:church_admin_app/screens/qr_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../flavor/flavor_config.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';
import 'attendance_screen.dart';

class CreateServiceScreen extends StatefulWidget {
  final String eventId;

  const CreateServiceScreen({super.key, required this.eventId});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> with SingleTickerProviderStateMixin {
  final codeCtrl = TextEditingController();
  TimeOfDay? time;
  List<Map<String, dynamic>> services = [];
  bool loading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    codeCtrl.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (services.isEmpty) {
      try {
        await ApiService.deleteEvent(widget.eventId);
      } catch (e) {
        // ignore deletion errors
      }
    }
    return true;
  }

  Future<void> addService() async {
    if (codeCtrl.text.isEmpty) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter service code');
      return;
    }

    if (time == null) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please select service time');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => loading = true);

    try {
      final token = await Storage.getToken();
      final result = await ApiService.createService(widget.eventId, codeCtrl.text, '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}');

      HapticFeedback.selectionClick();
      setState(() {
        services.add(result);
        codeCtrl.clear();
        time = null;
        loading = false;
      });
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorDialog('Failed to create service. Please try again.');
      setState(() => loading = false);
    }
  }

  Future<void> _selectTime() async {
    HapticFeedback.lightImpact();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: FlavorConfig.instance.values.primaryColor, onPrimary: Colors.white),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => time = picked);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ScaleTransition(
        scale: CurvedAnimation(parent: ModalRoute.of(context)!.animation!, curve: Curves.easeOutBack),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            'Service Creation Failed',
            style: TextStyle(color: FlavorConfig.instance.values.primaryColor, fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FlavorConfig.instance.values.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAttendance() async {
    HapticFeedback.mediumImpact();
    try {
      final token = await Storage.getToken();
      final url = '${ApiService.baseUrl}/api/admin/attendance/export/${widget.eventId}';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        HapticFeedback.selectionClick();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Export started in browser'),
            backgroundColor: FlavorConfig.instance.values.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        throw 'Could not launch browser';
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorDialog('Failed to export attendance. Please check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          if (await _onWillPop()) Navigator.pop(context);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Services',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[900], fontFamily: 'PlayfairDisplay'),
                            ),
                            const SizedBox(height: 4),
                            Text('Add multiple services for your event', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Icon(Icons.schedule, color: FlavorConfig.instance.values.primaryColor, size: 32),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              // Service Creation Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 4))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add New Service',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800], fontFamily: 'PlayfairDisplay'),
                                    ),

                                    const SizedBox(height: 24),

                                    // Service Code Field
                                    Text(
                                      'Service Code',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black54, width: 1.5),
                                      ),
                                      child: TextField(
                                        controller: codeCtrl,
                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                          hintText: 'SS1, SS2, SS3, etc.',
                                          hintStyle: TextStyle(color: Colors.grey),
                                          prefixIcon: Icon(Icons.tag, color: FlavorConfig.instance.values.primaryColor),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),
                                    Text('Unique code for this service (e.g., SS1 for Sunday Service 1)', style: TextStyle(fontSize: 12, color: Colors.grey[500])),

                                    const SizedBox(height: 24),

                                    // Time Selection
                                    Text(
                                      'Service Time',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _selectTime,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.black54, width: 1.5),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, color: FlavorConfig.instance.values.primaryColor, size: 24),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(time == null ? 'Select Time' : 'Service Time', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                                    Text(
                                                      time?.format(context) ?? 'Tap to select',
                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Icon(Icons.arrow_drop_down, color: FlavorConfig.instance.values.primaryColor, size: 28),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // Add Service Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: loading ? null : addService,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: FlavorConfig.instance.values.primaryColor,
                                          disabledBackgroundColor: Colors.grey[400],
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          elevation: 0,
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            AnimatedOpacity(
                                              opacity: loading ? 0 : 1,
                                              duration: const Duration(milliseconds: 200),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Add Service',
                                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (loading) SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white.withOpacity(0.9))),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Services List Header
                              if (services.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Text(
                                      'Created Services (${services.length})',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: FlavorConfig.instance.values.primaryColor, borderRadius: BorderRadius.circular(20)),
                                      child: Text(
                                        services.length == 1 ? '1 Service' : '${services.length} Services',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Services List
                              if (services.isNotEmpty)
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: services.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final service = services[index];
                                    return _buildServiceCard(service, index + 1);
                                  },
                                ),

                              if (services.isEmpty) ...[
                                const SizedBox(height: 48),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.schedule_send, size: 80, color: Colors.grey[300]),
                                      const SizedBox(height: 20),
                                      Text(
                                        'No Services Yet',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add your first service to generate QR codes',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),

                              // Export Button
                              if (services.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.download_for_offline_outlined, color: FlavorConfig.instance.values.primaryColor, size: 32),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Export Attendance Data',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Download all attendance data as CSV file',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton.icon(
                                          onPressed: _exportAttendance,
                                          icon: const Icon(Icons.download, color: Colors.white, size: 22),
                                          label: const Text(
                                            'Export CSV',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: FlavorConfig.instance.values.primaryColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 40),

                              // Footer
                              Center(
                                child: Text('The Lords Church Admin Portal © ${DateTime.now().year}', style: TextStyle(color: Colors.grey[500], fontSize: 12, letterSpacing: 0.5)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: FlavorConfig.instance.values.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text(
                      index.toString(),
                      style: TextStyle(color: FlavorConfig.instance.values.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service ${index}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(service['qrUrl'].toString().split('/').last, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => QrViewScreen(qrUrl: service['qrUrl'])));
                    },
                    icon: const Icon(Icons.qr_code, color: Colors.white, size: 18),
                    label: const Text('View QR', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlavorConfig.instance.values.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(serviceId: service['serviceId'])));
                    },
                    icon: Icon(Icons.list_alt, color: FlavorConfig.instance.values.primaryColor, size: 18),
                    label: Text('Attendance', style: TextStyle(color: FlavorConfig.instance.values.primaryColor)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: FlavorConfig.instance.values.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
