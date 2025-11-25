import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_page.dart';


import 'signin_page.dart';
import 'register_page.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/signin',
    routes: {
      '/signin': (context) => SignInPage(),
      '/register': (context) => RegisterPage(),
    },
  ));
}

