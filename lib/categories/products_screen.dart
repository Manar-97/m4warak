import 'package:flutter/material.dart';
import 'package:mshawer/categories/dm/product_dm.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  final int storeId;
  final String storeName;
  const ProductsScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _supabase = Supabase.instance.client;

  Future<List<Product>> fetchProducts() async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('store_id', widget.storeId);

    return (response as List<dynamic>)
        .map((s) => Product.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.storeName)),
      body: FutureBuilder<List<Product>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No products found'));
          }
          final product = snapshot.data!;
          return ListView.builder(
            itemCount: product.length,
            itemBuilder: (context, index) {
              final products = product[index];
              return ProductCard(
                product: products,
                onPressed: () {
                  print('product ${products.name} clicked');
                },
              );
            },
          );
        },
      ),
    );
  }
}
