import 'package:church_admin_app/flavor/flavor_config.dart';
import 'package:church_admin_app/services/api_service.dart';
import 'package:church_admin_app/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentLinkScreen extends StatefulWidget {
  const PaymentLinkScreen({super.key});

  @override
  State<PaymentLinkScreen> createState() => _PaymentLinkScreenState();
}

class _PaymentLinkScreenState extends State<PaymentLinkScreen>
    with SingleTickerProviderStateMixin {
  final ctrl = TextEditingController();
  bool loading = false;
  bool fetching = true;
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

    _fetchExisting();
  }

  Future<void> _fetchExisting() async {
    try {
      final link = await ApiService.getPaymentLink();
      if (mounted) {
        ctrl.text = link ?? '';
        setState(() {
          fetching = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => fetching = false);
        _showErrorDialog('Failed to load payment link');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    ctrl.dispose();
    super.dispose();
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
              setState(() => loading = false);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlavorConfig.instance.values.primaryColor,
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (ctrl.text.trim().isEmpty) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter a payment link');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => loading = true);

    try {
      final saved = await ApiService.setPaymentLink(ctrl.text.trim());
      print('Payment link saved: $saved');

      HapticFeedback.selectionClick();
      _showSuccessDialog('Payment link saved');
      // Navigator.pop(context, saved);
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => loading = false);
      _showErrorDialog(e.toString());
    }
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

                  const SizedBox(height: 16),

                  Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Link',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            fontFamily: 'PlayfairDisplay',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add or update your church payment link',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: fetching
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
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
                                    const Text('Payment Link'),
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
                                        controller: ctrl,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                          hintText: 'https://payments.example.com/...',
                                          prefixIcon: Icon(
                                            Icons.link,
                                            color: FlavorConfig.instance.values.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: loading ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: FlavorConfig.instance.values.primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: loading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : const Text('Submit', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
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
}
