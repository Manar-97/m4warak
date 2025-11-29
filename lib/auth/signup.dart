import 'package:flutter/material.dart';
import 'package:mshawer/auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static const String routeName = "signup";

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String userType = "customer"; // default value

  Future<void> signUp() async {
    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'display_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'user_type': userType,
        },
      );

      final user = response.user;

      if (user == null) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: Text("Confirm Email"),
                content: Text(
                  "Please check your email and confirm your account before proceeding.",
                ),
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

      // تنظيف الحقول
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _passwordController.clear();

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text("Success"),
              content: Text(
                "Account created successfully! Please check your email and confirm your account before proceeding.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(
                      context,
                      LoginScreen.routeName,
                    );
                  },
                  child: Text("OK"),
                ),
              ],
            ),
      );
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
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Image.asset('assets/images/logoo.png'),
                SizedBox(height: 20),

                // NAME
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 15),

                // PHONE
                // TextField(
                //   controller: _phoneController,
                //   decoration: InputDecoration(
                //     labelText: "Phone",
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.all(Radius.circular(20)),
                //     ),
                //     prefixIcon: Icon(Icons.phone),
                //   ),
                // ),
                // SizedBox(height: 15),

                // EMAIL
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "E-mail",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                SizedBox(height: 15),

                // PASSWORD
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 20),

                // USER TYPE DROPDOWN
                DropdownButtonFormField<String>(
                  value: userType,
                  items: [
                    DropdownMenuItem(
                      value: "customer",
                      child: Text("Customer"),
                    ),
                    DropdownMenuItem(value: "driver", child: Text("Driver")),
                  ],
                  onChanged: (val) {
                    setState(() {
                      userType = val!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Account Type",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
                SizedBox(height: 25),

                // SIGN UP BUTTON
                ElevatedButton(
                  onPressed: signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text("SignUp", style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 10),

                Row(
                  children: [
                    Text("Have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, LoginScreen.routeName);
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
