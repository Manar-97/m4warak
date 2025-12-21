// يجب أن يتطابق هذا النموذج مع هيكلية جدول tasks في Supabase
class TaskDM {
  final int? id;
  final String customerId; // auth.users.id
  final String? driverId; // auth.users.id
  final String taskType; // نوع المهمة (مثل: توصيل طلبات، حجز تذاكر...)
  final String taskDetails; // وصف الطلب
  final String pickupAddress; // عنوان نقطة الالتقاط (نصياً)
  final double pickupLat; // إحداثيات خط العرض لنقطة الالتقاط
  final double pickupLon; // إحداثيات خط الطول لنقطة الالتقاط
  final String deliveryAddress; // عنوان التسليم (نصياً)
  final double deliveryLat; // إحداثيات خط العرض لوجهة التسليم
  final double deliveryLon; // إحداثيات خط الطول لوجهة التسليم
  final DateTime createdAt;
  final TaskStatus status; // حالة المهمة (مثل: pending, accepted, completed)
  final double? totalPrice; // السعر التقديري

  TaskDM({
    required this.customerId,
    this.driverId, // تم تعديلها لتكون اختيارية كما في Supabase
    required this.taskType,
    required this.taskDetails,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLon,
    required this.deliveryAddress,
    required this.deliveryLat,
    required this.deliveryLon,
    this.totalPrice,
    this.id,
    DateTime? createdAt,
    required this.status,
  }) : createdAt = createdAt ?? DateTime.now();

  // تحويل النموذج إلى خريطة (Map) لتناسب Supabase INSERT
  Map<String, dynamic> toSupabase() {
    return {
      'customer_id': customerId,
      'task_type': taskType,
      'task_details': taskDetails,
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat, // إرسال الإحداثيات
      'pickup_lon': pickupLon, // إرسال الإحداثيات
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat, // إرسال الإحداثيات
      'delivery_lon': deliveryLon, // إرسال الإحداثيات
      'total_price': totalPrice ?? 0.0,
      'status': status.name,
    };
  }

  // إنشاء نموذج من بيانات Supabase
  factory TaskDM.fromSupabase(Map<String, dynamic> data) {
    // يجب التعامل مع driver_id كـ String? لأنه قد يكون null في مرحلة pending
    final driverId = data['driver_id'] as String?;
    return TaskDM(
      id: data['id'],
      customerId: data['customer_id'].toString(),
      driverId: data['driver_id']?.toString(),
      taskType: data['task_type'] as String,
      taskDetails: data['task_details'] as String,
      pickupAddress: data['pickup_address'] as String,
      deliveryAddress: data['delivery_address'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      totalPrice: (data['total_price'] as num?)?.toDouble(),
      // جلب الإحداثيات والتأكد من تحويلها إلى double
      pickupLat: (data['pickup_lat'] as num?)?.toDouble() ?? 0.0,
      pickupLon: (data['pickup_lon'] as num?)?.toDouble() ?? 0.0,
      deliveryLat: (data['delivery_lat'] as num?)?.toDouble() ?? 0.0,
      deliveryLon: (data['delivery_lon'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          data['created_at'] != null
              ? DateTime.parse(data['created_at'] as String)
              : DateTime.now(),
    );
  }
}

enum TaskStatus {
  pending, // pending
  accepted, // بدل accepted
  delivered, // delivered
  cancelled,
  completed, // بدل canceled
}
