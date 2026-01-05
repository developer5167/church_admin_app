import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../flavor/flavor_config.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';
import 'create_service_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen>
    with SingleTickerProviderStateMixin {
  final nameCtrl = TextEditingController(text: 'Sunday Service');
  DateTime selectedDate = DateTime.now();
  bool loading = false;
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    HapticFeedback.lightImpact();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme:  ColorScheme.light(
              primary: FlavorConfig.instance.values.primaryColor,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      HapticFeedback.selectionClick();
      setState(() => selectedDate = picked);
    }
  }

  void createEvent() async {
    if (nameCtrl.text.isEmpty) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter event name');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => loading = true);

    try {
      final token = await Storage.getToken();
      final eventId = await ApiService.createEvent(
        nameCtrl.text,
        selectedDate.toIso8601String().split('T')[0],
      );

      HapticFeedback.selectionClick();
      setState(() => loading = false);

      // Animated navigation to Create Service Screen
      await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              CreateServiceScreen(eventId: eventId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorDialog('Failed to create event. Please try again.');
      setState(() => loading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ScaleTransition(
        scale: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeOutBack,
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title:  Text(
            'Event Creation Failed',
            style: TextStyle(
             color:  FlavorConfig.instance.values.primaryColor,
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
                backgroundColor:  FlavorConfig.instance.values.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),


                  // Header
                  Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Event',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            fontFamily: 'PlayfairDisplay',
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Set up a new church event for attendance tracking',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Event Creation Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Event Name Field
                              Text(
                                'Event Name',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black54,
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: nameCtrl,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  decoration:  InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    hintText: 'Enter event name',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    prefixIcon: Icon(
                                      Icons.event,
                                     color:  FlavorConfig.instance.values.primaryColor,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF8B0000,
                                  ).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF8B0000,
                                    ).withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline,
                                          color: FlavorConfig.instance.values.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Popular Event Types',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),

                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildEventTypeChip('Sunday Service'),
                                  _buildEventTypeChip('Bible Study'),
                                  _buildEventTypeChip('Prayer Meeting'),
                                  _buildEventTypeChip('Youth Gathering'),
                                  _buildEventTypeChip('Special Service'),
                                  _buildEventTypeChip('Community Event'),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Date Selection
                              Text(
                                'Event Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.black54,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                           Icon(
                                            Icons.calendar_today,
                                            color: FlavorConfig.instance.values.primaryColor,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                DateFormat(
                                                  'EEEE',
                                                ).format(selectedDate),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                DateFormat(
                                                  'dd MMMM yyyy',
                                                ).format(selectedDate),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                       Icon(
                                        Icons.arrow_drop_down,
                                        color: FlavorConfig.instance.values.primaryColor,
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),
                              Text(
                                'Select the date for your church event',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Quick Date Options
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick Select',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _buildQuickDateOption('Today', 0),
                                      _buildQuickDateOption('Tomorrow', 1),
                                      _buildQuickDateOption(
                                        'Next Sunday',
                                        _daysUntilNextSunday(),
                                      ),
                                      _buildQuickDateOption('Next Week', 7),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 48),

                              // Create Event Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: loading ? null : createEvent,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:  FlavorConfig.instance.values.primaryColor,
                                    disabledBackgroundColor: Colors.grey[400],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AnimatedOpacity(
                                        opacity: loading ? 0 : 1,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Create Event & Continue',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (loading)
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Event Type Suggestions

                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Information Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                   Icon(
                                    Icons.info_outline,
                                    color: FlavorConfig.instance.values.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Next Steps',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildNextStep(
                                '1',
                                'Create Event',
                                'Define the event name and date',
                              ),
                              _buildNextStep(
                                '2',
                                'Add Services',
                                'Set up multiple services with timing',
                              ),
                              _buildNextStep(
                                '3',
                                'Generate QR Codes',
                                'Create unique QR codes for each service',
                              ),
                              _buildNextStep(
                                '4',
                                'Track Attendance',
                                'Monitor real-time attendance data',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Footer
                        Center(
                          child: Text(
                            'The Lords Church Admin Portal © ${DateTime.now().year}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              letterSpacing: 0.5,
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
        ),
      ),
    );
  }

  Widget _buildQuickDateOption(String label, int daysOffset) {
    final date = DateTime.now().add(Duration(days: daysOffset));
    final isSelected =
        selectedDate.day == date.day &&
        selectedDate.month == date.month &&
        selectedDate.year == date.year;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ?  FlavorConfig.instance.values.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ?  FlavorConfig.instance.values.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEventTypeChip(String type) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          nameCtrl.text = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: nameCtrl.text == type
              ?  FlavorConfig.instance.values.primaryColor.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: nameCtrl.text == type
                ?  FlavorConfig.instance.values.primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: nameCtrl.text == type
                ?  FlavorConfig.instance.values.primaryColor
                : Colors.grey[700],
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNextStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color:  FlavorConfig.instance.values.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _daysUntilNextSunday() {
    final today = DateTime.now();
    final daysUntilSunday = DateTime.sunday - today.weekday;
    return daysUntilSunday <= 0 ? 7 + daysUntilSunday : daysUntilSunday;
  }
}
