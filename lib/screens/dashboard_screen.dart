import 'dart:async';
import 'dart:io';
import 'package:church_admin_app/services/api_service.dart';
import 'package:church_admin_app/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import '../flavor/flavor_config.dart' show FlavorConfig;
import '../utils/route_observer.dart';
import 'admin_login_screen.dart';
import 'attendance_screen.dart';
import 'create_event_screen.dart';
import 'qr_view_screen.dart';
import 'payment_link_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  List<dynamic>? events;
  String? _token;
  DateTime _selectedDate = DateTime.now();
  bool loading = true;
  bool exporting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    loadData(date: _selectedDate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modal = ModalRoute.of(context);
    if (modal != null) {
      routeObserver.subscribe(this, modal);
    }
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatDisplayDate(DateTime d) {
    return DateFormat('EEEE, MMMM d, yyyy').format(d);
  }

  String _formatTime(String time) {
    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = timeParts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$displayHour:${minute.padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  void loadData({DateTime? date}) async {
    try {
      setState(() => loading = true);
      final useDate = date ?? _selectedDate;
      final dateStr = _formatDate(useDate);
      final result = await ApiService.getEventsByDate(dateStr);

      if (mounted) {
        setState(() {
          events = result;
          loading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _showErrorDialog(
          'Failed to load events. Please check your connection.',
        );
      }
    }
  }

  Future<void> _selectDate() async {
    HapticFeedback.lightImpact();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: FlavorConfig.instance.values.primaryColor,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      HapticFeedback.selectionClick();
      setState(() => _selectedDate = picked);
      loadData(date: picked);
    }
  }

  Future<void> exportToCsv(dynamic event) async {
    if (exporting) return;

    HapticFeedback.mediumImpact();
    setState(() => exporting = true);

    try {
      final csvData = await ApiService.exportAttendanceCSV(event['id']);
      String filePath = '';

      if (Platform.isAndroid) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }

        if (!storageStatus.isGranted) {
          final mgr = await Permission.manageExternalStorage.request();
          if (!mgr.isGranted) {
            final directory = await getApplicationDocumentsDirectory();
            filePath = p.join(
              directory.path,
              '${event['name']}_attendance.csv',
            );
          }
        }

        if (filePath.isEmpty) {
          try {
            final downloads = await getExternalStorageDirectories(
              type: StorageDirectory.downloads,
            );
            String? downloadPath = downloads?.first.path;
            if (downloadPath == null || downloadPath.isEmpty) {
              downloadPath = '/storage/emulated/0/Download';
            }
            filePath = p.join(downloadPath, '${event['name']}_attendance.csv');
          } catch (_) {
            final directory = await getApplicationDocumentsDirectory();
            filePath = p.join(
              directory.path,
              '${event['name']}_attendance.csv',
            );
          }
        }

        final file = File(filePath);
        await file.create(recursive: true);
        await file.writeAsString(csvData);

        HapticFeedback.selectionClick();
        _showSuccessDialog('CSV exported successfully!\nSaved to: $filePath');
      } else if (Platform.isIOS) {
        final directory = await getTemporaryDirectory();
        filePath = p.join(directory.path, '${event['name']}_attendance.csv');
        final file = File(filePath);
        await file.writeAsString(csvData);

        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'Attendance CSV for ${event['name']}');
        HapticFeedback.selectionClick();
        _showSuccessDialog('Share dialog opened to save CSV');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        filePath = p.join(directory.path, '${event['name']}_attendance.csv');
        final file = File(filePath);
        await file.writeAsString(csvData);

        HapticFeedback.selectionClick();
        _showSuccessDialog('CSV saved to Documents folder');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorDialog('Failed to export CSV: $e');
    } finally {
      if (mounted) {
        setState(() => exporting = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          'Error',
          style: TextStyle(
            color: FlavorConfig.instance.values.primaryColor,
            fontWeight: FontWeight.bold,
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Success',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Logout',
              style: TextStyle(
                color: FlavorConfig.instance.values.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context, false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlavorConfig.instance.values.primaryColor,
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await Storage.logout();
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AdminLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when a top route has been popped and this route shows up again.
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: FlavorConfig.instance.values.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dashboard,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                              fontFamily: 'PlayfairDisplay',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage church events and attendance',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: Icon(
                        Icons.logout,
                        color: FlavorConfig.instance.values.primaryColor,
                        size: 28,
                      ),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),

              // Date Selection Card
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDisplayDate(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _selectDate,
                          icon: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 20,
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                FlavorConfig.instance.values.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildQuickDateOption('Today', 0),
                        _buildQuickDateOption('Yesterday', -1),
                        _buildQuickDateOption('Tomorrow', 1),
                        _buildQuickDateOption(
                          'Next Sunday',
                          _daysUntilNextSunday(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: loading
                    ? _buildLoadingScreen()
                    : events == null || events!.isEmpty
                    ? _buildEmptyState()
                    : _buildEventsList(),
              ),

              // Bottom action bar with Create Event and Payment Link
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const CreateEventScreen(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      const begin = Offset(0.0, 1.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOutCubic;

                                      var tween = Tween(
                                        begin: begin,
                                        end: end,
                                      ).chain(CurveTween(curve: curve));
                                      var offsetAnimation = animation.drive(
                                        tween,
                                      );

                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      );
                                    },
                                transitionDuration: const Duration(
                                  milliseconds: 500,
                                ),
                              ),
                            ).then((_) => loadData());
                          },
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Create Event',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const PaymentLinkScreen(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      const begin = Offset(0.0, 1.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeInOutCubic;

                                      var tween = Tween(
                                        begin: begin,
                                        end: end,
                                      ).chain(CurveTween(curve: curve));
                                      var offsetAnimation = animation.drive(
                                        tween,
                                      );

                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      );
                                    },
                                transitionDuration: const Duration(
                                  milliseconds: 500,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.link,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Payment Link',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                FlavorConfig.instance.values.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: FlavorConfig.instance.values.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Events...',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.event_available, size: 100, color: Colors.grey[300]),
              const SizedBox(height: 24),
              Text(
                'No Events Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No events scheduled for ${_formatDisplayDate(_selectedDate)}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new event to get started',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _selectDate(),
                icon: const Icon(Icons.date_range),
                label: const Text('Check Another Date'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: events!.length,
          itemBuilder: (context, index) {
            final event = events![index];
            final services = event['services'] as List<dynamic>;

            return _buildEventCard(event, services, index);
          },
        ),
      ),
    );
  }

  Widget _buildEventCard(dynamic event, List<dynamic> services, int index) {
    final totalAttendees = services.fold<int>(0, (sum, service) {
      return (sum + (service['attendanceCount'] ?? 0)).toInt();
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: FlavorConfig.instance.values.primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.event,
                                color:
                                    FlavorConfig.instance.values.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                event['name'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey[500],
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              event['event_date'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: FlavorConfig.instance.values.primaryColor
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${services.length} Service${services.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: FlavorConfig.instance.values.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$totalAttendees Attendees',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Export Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: exporting ? null : () => exportToCsv(event),
                  icon: exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.download,
                          size: 20,
                          color: Colors.white,
                        ),
                  label: Text(
                    exporting ? 'Exporting...' : 'Export Attendance CSV',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    disabledBackgroundColor: const Color.fromARGB(
                      255,
                      255,
                      255,
                      255,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Services List
              if (services.isNotEmpty) ...[
                Text(
                  'Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ...services.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;
                  return _buildServiceCard(service, index);
                }),
              ],

              if (services.isEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[500]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No services created for this event yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(dynamic service, int index) {
    return FutureBuilder(
      future: ApiService.getAttendance(service['id']),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!['count'] ?? 0 : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Service Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service ${service['service_code']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.grey[500],
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(service['service_time']),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.green[500], size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$count attendees',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AttendanceScreen(serviceId: service['id']),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.list_alt,
                      color: FlavorConfig.instance.values.primaryColor,
                      size: 24,
                    ),
                    tooltip: 'View Attendance',
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrViewScreen(qrUrl: service['qrUrl']),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.qr_code,
                      color: FlavorConfig.instance.values.primaryColor,
                      size: 24,
                    ),
                    tooltip: 'View QR Code',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickDateOption(String label, int daysOffset) {
    final date = DateTime.now().add(Duration(days: daysOffset));
    final isSelected =
        _selectedDate.day == date.day &&
        _selectedDate.month == date.month &&
        _selectedDate.year == date.year;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDate = date);
        loadData(date: date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? FlavorConfig.instance.values.primaryColor
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? FlavorConfig.instance.values.primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  int _daysUntilNextSunday() {
    final today = DateTime.now();
    final daysUntilSunday = DateTime.sunday - today.weekday;
    return daysUntilSunday <= 0 ? 7 + daysUntilSunday : daysUntilSunday;
  }
}
