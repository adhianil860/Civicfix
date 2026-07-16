import 'package:flutter/material.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

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
                    child: Hero(
                      tag: 'civicfix_logo',
                      child: Image.asset(
                        'assets/images/CivicFix_logo.png',
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Create Your Account",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Join CivicFix and help build a better community.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),

                  const SizedBox(height: 35),

                  TextField(
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      hintText: "Enter your full name",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: border,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      hintText: "Enter your phone number",
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: border,
                    ),
                  ),

                  const SizedBox(height: 20),

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
                      hintText: "Create a password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: border,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      hintText: "Re-enter your password",
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
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Create Account",
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
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Login"),
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
