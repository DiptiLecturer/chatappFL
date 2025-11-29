import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'signin_page.dart';
import 'register_page.dart';
import 'chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthCheck(),
      routes: {
        '/signin': (context) => const SignInPage(),
        '/register': (context) => const RegisterPage(),
        '/chat': (context) => const ChatPage(),
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User logged in → Go to chat screen
        if (snapshot.hasData) {
          return const ChatPage();
        }
        // User not logged in → Show SignInPage
        return const SignInPage();
      },
    );
  }
}

