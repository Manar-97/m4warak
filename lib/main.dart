import 'package:flutter/material.dart';
import 'package:mshawer/auth/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/signup.dart';
import 'home.dart';
import 'main_screen.dart';

void main() async {
  await Supabase.initialize(
    url: "https://fnnllyfgvrtoxkirhcmx.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZubmxseWZndnJ0b3hraXJoY214Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyNTcwNzgsImV4cCI6MjA3OTgzMzA3OH0.YqK2TEaH-kuwfsKUvGqawA_CvR-IZEubEC3XnpjXKhg",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mshawer',
      routes: {
        LoginScreen.routeName: (_) => LoginScreen(),
        SignUpScreen.routeName: (_) => SignUpScreen(),
        MainScreen.routeName: (_) => MainScreen(),
      },
      initialRoute: MainScreen.routeName,
    );
  }
}
