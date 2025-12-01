class Store {
  final int id;
  final String name;
  final int? categoryId;
  final String? ownerId;
  final double avgRating;
  final DateTime createdAt;

  Store({
    required this.id,
    required this.name,
    this.categoryId,
    this.ownerId,
    required this.avgRating,
    required this.createdAt,
  });

  // تحويل من Map لجسم Store
  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'] as int,
      name: map['name'] as String,
      categoryId: map['category_id'] as int?,
      ownerId: map['owner_id'] as String?,
      avgRating: (map['avg_rating'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // تحويل جسم Store لـ Map لو حبيت تبعت للـ Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'owner_id': ownerId,
      'avg_rating': avgRating,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
