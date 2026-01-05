import 'package:church_admin_app/flavor/flavor_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';
import 'dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool loading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
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

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _gradientAnimation =
        ColorTween(
          begin:  FlavorConfig.instance.values.primaryColor.withOpacity(0.7),
          end:  FlavorConfig.instance.values.primaryColor,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  void login() async {
    if (usernameCtrl.text.isEmpty) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter username');
      return;
    }

    if (passwordCtrl.text.isEmpty) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter password');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => loading = true);

    try {
      final token = await ApiService.adminLogin(
        usernameCtrl.text,
        passwordCtrl.text,
      );
      await Storage.saveToken(token);

      HapticFeedback.selectionClick();

      // Animated navigation to Dashboard
      await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardScreen(),
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
      final errorMessage = e.toString().startsWith("Exception: ")
          ? e.toString().substring(11)
          : e.toString();
      _showErrorDialog(errorMessage.isNotEmpty ? errorMessage : 'Login failed');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
            'Login Failed',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Try Again',
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

  void _togglePasswordVisibility() {
    HapticFeedback.selectionClick();
    setState(() => _obscurePassword = !_obscurePassword);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF8F8F8),
                const Color(0xFFE8E8E8),
                _gradientAnimation.value ??  FlavorConfig.instance.values.primaryColor.withOpacity(0.1),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Logo and Title Section
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRect(
                            child: Image.asset(
                              FlavorConfig.instance.values.logoAsset,
                              fit: BoxFit.contain,
                              width: 50,
                              height: 50,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Column(
                          children: [
                            Text(
                              'Admin Portal',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                                fontFamily: 'PlayfairDisplay',
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Church Management System',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Login Form Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
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
                              Text(
                                'Login Credentials',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                  fontFamily: 'PlayfairDisplay',
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Username Field
                              Text(
                                'Username',
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
                                  controller: usernameCtrl,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  decoration:  InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    hintText: 'Enter admin username',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: FlavorConfig.instance.values.primaryColor,
                                    ),
                                  ),
                                  onSubmitted: (_) =>
                                      FocusScope.of(context).nextFocus(),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Password Field
                              Text(
                                'Password',
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
                                  controller: passwordCtrl,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    hintText: 'Enter admin password',
                                    hintStyle: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                    prefixIcon:  Icon(
                                      Icons.lock_outline,
                                      color: FlavorConfig.instance.values.primaryColor,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: _togglePasswordVisibility,
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color:  FlavorConfig.instance.values.primaryColor,
                                      ),
                                    ),
                                  ),
                                  onSubmitted: (_) => login(),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    // Implement forgot password
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color:  FlavorConfig.instance.values.primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: loading ? null : login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FlavorConfig.instance.values.primaryColor,
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
                                              'Login to Dashboard',
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
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Footer
                        Text(
                          'The Lords Church Admin Portal © ${DateTime.now().year}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
