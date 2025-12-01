import 'package:flutter/material.dart';
import 'package:mshawer/categories/products_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../categories/dm/categories_dm.dart';
import '../widgets/store_card.dart';
import 'dm/stores_dm.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final _supabase = Supabase.instance.client;

  Future<List<Store>> fetchStores() async {
    final response = await _supabase
        .from('stores')
        .select()
        .eq('category_id', widget.category.id);

    return (response as List<dynamic>)
        .map((s) => Store.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: FutureBuilder<List<Store>>(
        future: fetchStores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No stores found'));
          }
          final stores = snapshot.data!;
          return GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children:
                stores.map((sto) {
                  return StoreCard(
                    store: sto,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProductsScreen(
                                storeId: sto.id,
                                storeName: sto.name,
                              ),
                        ),
                      );
                      print('Store ${sto.name} clicked');
                    },
                  );
                }).toList(),
          );
        },
      ),
    );
  }
}
