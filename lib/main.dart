import 'package:flutter/material.dart';
import 'signin_page.dart';
import 'register_page.dart';
import 'package:firebase_core/firebase_core.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/signin',
    routes: {
      '/signin': (context) => const SignInPage(),
      '/register': (context) => const RegisterPage(),
    },
  ));
}
