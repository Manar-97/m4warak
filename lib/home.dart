import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mshawer/auth/login.dart';
import 'package:mshawer/profile.dart';
import 'package:mshawer/setting.dart';
import 'package:mshawer/widgets/category_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const String routeName = 'home';
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  String searchText = "";

  Future<void> logout() async {
    await _supabase.auth.signOut();
    print("LogOut Successfully");
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: IconButton(
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
              ),
              icon: Icon(Icons.logout, color: Colors.black),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hello, Manar',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Image.asset('assets/images/logoo.png'),
              Text(
                'Categories',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                children: [
                  CategoryCard(
                    icon: FontAwesomeIcons.basketShopping,
                    onPressed: () {},
                    text: 'Supermarket',
                  ),
                  CategoryCard(
                    icon: FontAwesomeIcons.burger,
                    onPressed: () {},
                    text: 'Restaurant',
                  ),
                  CategoryCard(
                    icon: FontAwesomeIcons.capsules,
                    onPressed: () {},
                    text: 'Pharmacy',
                  ),
                  CategoryCard(
                    icon: FontAwesomeIcons.breadSlice,
                    onPressed: () {},
                    text: 'Bakery',
                  ),
                  CategoryCard(
                    icon: FontAwesomeIcons.cakeCandles,
                    onPressed: () {},
                    text: 'Sweets',
                  ),
                  CategoryCard(
                    icon: FontAwesomeIcons.mortarPestle,
                    onPressed: () {},
                    text: '3tara',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
