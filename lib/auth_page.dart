import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _auth = FirebaseAuth.instance;
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // soft green background
      appBar: AppBar(
        title: const Text("Login / Register"),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green[700],
                child: const Icon(Icons.chat, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),

              // Email input
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.green),
                  filled: true,
                  fillColor: Colors.green[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.green),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) => email = val,
              ),
              const SizedBox(height: 16),

              // Password input
              TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.green),
                  filled: true,
                  fillColor: Colors.green[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.green),
                ),
                obscureText: true,
                onChanged: (val) => password = val,
              ),
              const SizedBox(height: 24),

              // Login/Register button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _auth.signInWithEmailAndPassword(
                          email: email, password: password);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatPage()),
                      );
                    } catch (e) {
                      // register if login fails
                      try {
                        await _auth.createUserWithEmailAndPassword(
                            email: email, password: password);

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatPage()),
                        );
                      } catch (err) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $err")));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Login / Register",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
