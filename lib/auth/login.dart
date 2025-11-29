import 'package:flutter/material.dart';
import 'package:mshawer/auth/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const String routeName = "login";

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;

  Future<void> signIn() async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;
      if (user == null) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: Text("Login Error"),
                content: Text("Please confirm your email before logging in."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK"),
                  ),
                ],
              ),
        );
        return;
      }

      // إذا كان المستخدم Driver، نتأكد من وجود سجل في جدول drivers
      final driverCheck =
          await _supabase
              .from('drivers')
              .select()
              .eq('id', user.id)
              .maybeSingle();

      if (driverCheck == null &&
          (user.userMetadata?['user_type'] == 'driver')) {
        await _supabase.from("drivers").insert({
          "id": user.id,
          "active": false,
        });
      }

      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } catch (e) {
      final message = e is AuthException ? e.message : e.toString();
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text("Error"),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Login',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                Image.asset('assets/images/logoo.png'),

                SizedBox(height: 25),

                // EMAIL FIELD
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "E-mail",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),

                SizedBox(height: 15),

                // PASSWORD FIELD
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),

                SizedBox(height: 40),

                ElevatedButton(
                  onPressed: signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Login", style: TextStyle(color: Colors.white)),
                ),

                SizedBox(height: 10),

                Row(
                  children: [
                    Text("Don't have an account? "),
                    GestureDetector(
                      child: Text(
                        "SignUp",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, SignUpScreen.routeName);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
