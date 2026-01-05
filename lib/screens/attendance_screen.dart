import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../flavor/flavor_config.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';

class AttendanceScreen extends StatefulWidget {
  final String serviceId;
  const AttendanceScreen({super.key, required this.serviceId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? data;
  bool loading = true;
  bool refreshing = false;
  String filterType = 'all'; // 'all', 'regular', 'guest'
  String searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadData();

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !refreshing) {
        _refreshData();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final result = await ApiService.getAttendance(widget.serviceId);

      setState(() {
        data = result;
        loading = false;
      });
      _animationController.forward();
    } catch (e) {
      _showErrorDialog('Failed to load attendance data');
      setState(() => loading = false);
    }
  }

  Future<void> _refreshData() async {
    if (refreshing) return;

    setState(() => refreshing = true);
    HapticFeedback.lightImpact();

    try {
      final token = await Storage.getToken();
      final result = await ApiService.getAttendance(widget.serviceId);

      setState(() {
        data = result;
        refreshing = false;
      });
    } catch (e) {
      setState(() => refreshing = false);
    }
  }

  List<dynamic> getFilteredAttendees() {
    if (data == null) return [];

    var attendees = List.from(data!['attendees']);

    // Apply member type filter
    if (filterType != 'all') {
      attendees = attendees
          .where((a) => a['member_type'] == filterType)
          .toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      attendees = attendees.where((a) {
        final name = (a['full_name'] ?? '').toLowerCase();
        final phone = (a['phone'] ?? '').toLowerCase();
        final query = searchQuery.toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    }

    return attendees;
  }

  void _showErrorDialog(String message) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title:  Text(
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
              backgroundColor:  FlavorConfig.instance.values.primaryColor,
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

  void _exportData() {
    HapticFeedback.mediumImpact();
    // Implement export functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:  Text(
          'Export Attendance',
          style: TextStyle(
            color: FlavorConfig.instance.values.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Export attendance data as CSV or Excel file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
              // Implement export
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:  FlavorConfig.instance.values.primaryColor,
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer.cancel();
    super.dispose();
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
        body: loading ? SafeArea(child: _buildLoadingScreen()) : SafeArea(child: _buildContentScreen()),
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
            'Loading Attendance...',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildContentScreen() {
    final filteredAttendees = getFilteredAttendees();

    return Column(
      children: [
        // Header Card
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            children: [
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard(
                    'Total',
                    data!['count'].toString(),
                    Icons.people_outline,
                  ),
                  _buildStatCard(
                    'Regular',
                    data!['attendees']
                        .where((a) => a['member_type'] == 'regular')
                        .length
                        .toString(),
                    Icons.person,
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    'Guests',
                    data!['attendees']
                        .where((a) => a['member_type'] == 'guest')
                        .length
                        .toString(),
                    Icons.person_outline,
                    color: Colors.blue,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    border: InputBorder.none,
                    prefixIcon:  Icon(
                      Icons.search,
                      color: FlavorConfig.instance.values.primaryColor,
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() => searchQuery = '');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Regular Members', 'regular'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Guests', 'guest'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Attendance List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color:  FlavorConfig.instance.values.primaryColor,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: filteredAttendees.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredAttendees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final attendee = filteredAttendees[index];
                        return _buildAttendeeCard(attendee, index + 1);
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color ??  FlavorConfig.instance.values.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        HapticFeedback.selectionClick();
        setState(() => filterType = value);
      },
      backgroundColor: Colors.white,
      selectedColor:  FlavorConfig.instance.values.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ?  FlavorConfig.instance.values.primaryColor : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildAttendeeCard(Map<String, dynamic> attendee, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: attendee['member_type'] == 'regular'
              ?  FlavorConfig.instance.values.primaryColor.withOpacity(0.1)
              : Colors.blue.withOpacity(0.1),
          child: Text(
            index.toString(),
            style: TextStyle(
              color: attendee['member_type'] == 'regular'
                  ?  FlavorConfig.instance.values.primaryColor
                  : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          attendee['full_name'] ?? 'Unknown',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              attendee['phone'] ?? 'No phone',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: attendee['member_type'] == 'regular'
                        ?  FlavorConfig.instance.values.primaryColor.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    attendee['member_type'] == 'regular'
                        ? 'Regular Member'
                        : 'Guest',
                    style: TextStyle(
                      color: attendee['member_type'] == 'regular'
                          ?  FlavorConfig.instance.values.primaryColor
                          : Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(attendee['submitted_at']),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            _showAttendeeDetails(attendee);
          },
          icon: const Icon(Icons.more_vert, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            searchQuery.isNotEmpty
                ? 'No matching attendees found'
                : 'No attendance recorded yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Attendance will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          if (searchQuery.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => searchQuery = '');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:  FlavorConfig.instance.values.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Clear Search',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _showAttendeeDetails(Map<String, dynamic> attendee) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Attendee Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailItem('Name', attendee['full_name'] ?? 'Unknown'),
            _buildDetailItem('Phone', attendee['phone'] ?? 'N/A'),
            _buildDetailItem(
              'Member Type',
              attendee['member_type'] == 'regular' ? 'Regular Member' : 'Guest',
            ),
            _buildDetailItem('Coming From', attendee['coming_from'] ?? 'N/A'),
            _buildDetailItem(
              'Since Year',
              attendee['since_year']?.toString() ?? 'N/A',
            ),
            _buildDetailItem(
              'Attending With',
              attendee['attending_with'] ?? 'N/A',
            ),
            _buildDetailItem(
              'Registered At',
              _formatTime(attendee['submitted_at']),
            ),
            if (attendee['prayer_request'] != null &&
                attendee['prayer_request'].toString().isNotEmpty)
              _buildDetailItem('Prayer Request', attendee['prayer_request']),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  FlavorConfig.instance.values.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
