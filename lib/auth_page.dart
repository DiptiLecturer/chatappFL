import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class AuthPage extends StatefulWidget {
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
      appBar: AppBar(title: Text("Login/Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
              onChanged: (val) => email = val,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (val) => password = val,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential user = await _auth.signInWithEmailAndPassword(
                      email: email, password: password);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ChatPage(user: user.user!)),
                  );
                } catch (e) {
                  // If login fails, try register
                  try {
                    UserCredential user =
                    await _auth.createUserWithEmailAndPassword(email: email, password: password);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => ChatPage(user: user.user!)),
                    );
                  } catch (err) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text("Error: $err")));
                  }
                }
              },
              child: Text("Login / Register"),
            )
          ],
        ),
      ),
    );
  }
}
