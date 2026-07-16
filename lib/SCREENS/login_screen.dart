import 'package:civicfic/SCREENS/registration_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/CivicFix_logo.png',
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Welcome to CivicFix",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Report. Track. Improve your community.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),

                  const SizedBox(height: 35),

                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      hintText: "Enter your email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: border,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      hintText: "Enter your password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: border,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegistrationScreen(),
                            ),
                          );
                        },
                        child: const Text("Register"),
                      ),
                    ],
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
