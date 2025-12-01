class Product {
  final int id;
  final int storeId;
  final String name;
  final double price;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.price,
    required this.createdAt,
  });

  // تحويل من Map لجسم Store
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      storeId: map['store_id'] as int, // بدل 'storeId'
      name: map['name'] as String,
      price:
          (map['price'] as num)
              .toDouble(), // للتأكد من التحويل من int/num لـ double
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // تحويل جسم Store لـ Map لو حبيت تبعت للـ Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'name': name,
      'price': price,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
