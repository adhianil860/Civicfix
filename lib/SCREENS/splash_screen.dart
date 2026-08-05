import 'dart:async';
import 'package:flutter/material.dart';
import 'package:civicfic/screens/login_screen.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white, // Always Light
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: "civicfix_logo",
                child: Image.asset(
                  "assets/images/CivicFix_logo.png",
                  height: 170,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "CivicFix",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: settings.isDarkMode ? Colors.white : Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Report. Track. Improve.",
                style: TextStyle(
                  fontSize: 16,
                  color: settings.isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}