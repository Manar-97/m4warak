import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverRatingsScreen extends StatelessWidget {
  final String driverId;
  const DriverRatingsScreen({super.key, required this.driverId});
  static const String routeName = 'driver_ratings';

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقييم السائق',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('driver_ratings')
            .select('rating, notes, created_at, task_id')
            .eq('driver_id', driverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد تقييمات لهذا السائق'));
          }

          final ratings = snapshot.data!;

          return ListView.builder(
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final rating = ratings[index];
              final stars = rating['rating'] as int;
              final notes = rating['notes'] ?? 'لا توجد ملاحظات';
              final date =
                  rating['created_at'] != null
                      ? DateTime.parse(rating['created_at']).toLocal()
                      : null;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  title: Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < stars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text('ملاحظات: $notes'),
                      if (date != null)
                        Text(
                          'التاريخ: ${date.day}/${date.month}/${date.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
