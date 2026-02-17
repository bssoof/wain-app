import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Splash Screen - First screen when app opens
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    
    // Navigate after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash screen 1.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Text(
              'Wain',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC0006F),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
