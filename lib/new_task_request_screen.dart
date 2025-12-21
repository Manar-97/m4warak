import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'categories/dm/Location_result.dart';
import 'categories/dm/task_dm.dart';
import 'map_picker.dart';

class NewTaskRequestScreen extends StatefulWidget {
  const NewTaskRequestScreen({
    super.key,
    required this.serviceName,
    required this.serviceCode,
  });
  static const String routeName = 'new_task_request';

  final String serviceName;
  final String serviceCode;

  @override
  State<NewTaskRequestScreen> createState() => _NewTaskRequestScreenState();
}

class _NewTaskRequestScreenState extends State<NewTaskRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // حالة المواقع المختارة
  LocationResult? _pickupLocation;
  LocationResult? _deliveryLocation;

  // وحدة تحكم حقل التفاصيل
  final TextEditingController _detailsController = TextEditingController();

  bool _isLoading = false;

  // موقع افتراضي (قنا، مصر) لاستخدامه كبداية للخريطة
  static const LatLng _defaultLocation = LatLng(26.1770, 32.7444);

  void _showSnackBar(String message, {Color color = Colors.red}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right),
          backgroundColor: color,
        ),
      );
    }
  }

  // فتح شاشة الخريطة والحصول على النتيجة
  Future<void> _pickLocation(bool isPickup) async {
    final initialLocation =
        isPickup
            ? (_pickupLocation?.latLng ?? _defaultLocation)
            : (_deliveryLocation?.latLng ?? _defaultLocation);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapPickerScreen(
              title: isPickup ? 'تحديد نقطة الالتقاط' : 'تحديد وجهة التسليم',
              initialLocation: initialLocation,
            ),
      ),
    );

    if (result != null && result is LocationResult) {
      setState(() {
        if (isPickup) {
          _pickupLocation = result;
        } else {
          _deliveryLocation = result;
        }
      });
    }
  }

  Future<void> _submitTask() async {
    if (_pickupLocation == null || _deliveryLocation == null) {
      _showSnackBar("الرجاء تحديد نقطة الالتقاط ووجهة التسليم على الخريطة.");
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _showSnackBar("الرجاء تسجيل الدخول أولاً.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final task = TaskDM(
        customerId: currentUser.id,
        taskType: widget.serviceCode,
        taskDetails: _detailsController.text.trim(),

        // إرسال الإحداثيات والعناوين النصية (التي تم جلبها)
        pickupAddress: _pickupLocation!.addressPlaceholder, // العنوان النصي
        pickupLat: _pickupLocation!.latLng.latitude,
        pickupLon: _pickupLocation!.latLng.longitude,

        deliveryAddress: _deliveryLocation!.addressPlaceholder, // العنوان النصي
        deliveryLat: _deliveryLocation!.latLng.latitude,
        deliveryLon: _deliveryLocation!.latLng.longitude,
        status: TaskStatus.pending,
      );

      // إرسال البيانات إلى جدول tasks
      await _supabase.from('tasks').insert(task.toSupabase());

      _showSnackBar(
        "تم إرسال طلبك بنجاح! سيتم إيجاد مُشاوِر قريباً.",
        color: Colors.green,
      );

      // العودة إلى الشاشة الرئيسية بعد النجاح
      if (mounted) {
        Navigator.pop(context);
      }
    } on PostgrestException catch (e) {
      print(e.message);
      _showSnackBar("خطأ في قاعدة البيانات: ${e.message}");
    } catch (e) {
      print(e.toString());
      _showSnackBar("حدث خطأ غير متوقع: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  // ويدجت زر اختيار الموقع
  Widget _buildLocationPickerButton({
    required String label,
    required bool isPickup,
    LocationResult? locationResult,
  }) {
    final isSelected = locationResult != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.teal.shade800 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickLocation(isPickup),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.teal : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.map,
                  color: isSelected ? Colors.teal : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isSelected
                        ? (locationResult!.addressPlaceholder.length > 50
                            ? '${locationResult.addressPlaceholder.substring(0, 50)}...'
                            : locationResult.addressPlaceholder)
                        : 'انقر لتحديد الموقع على الخريطة',
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.teal.shade900
                              : Colors.grey.shade700,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 10),
            child: Text(
              'الإحداثيات: Lat: ${locationResult!.latLng.latitude.toStringAsFixed(4)}, Lon: ${locationResult.latLng.longitude.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.right,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.serviceName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'املأ تفاصيل طلبك',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 30),

              // زر تحديد نقطة الالتقاط
              _buildLocationPickerButton(
                label: '1. تحديد نقطة الالتقاط',
                isPickup: true,
                locationResult: _pickupLocation,
              ),
              const SizedBox(height: 25),

              // زر تحديد وجهة التسليم
              _buildLocationPickerButton(
                label: '2. تحديد وجهة التسليم النهائية',
                isPickup: false,
                locationResult: _deliveryLocation,
              ),
              const SizedBox(height: 25),

              // حقل تفاصيل الطلب (بقي كما هو)
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '3. وصف الطلب / التعليمات (مهم جداً)',
                  hintText:
                      'مثال: مطلوب شراء 5 كيلو طماطم، أو: حجز تذكرة ذهاب فقط ليوم الأربعاء.',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: Align(
                      alignment: Alignment.topRight,
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: Icon(
                        Icons.description,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال تفاصيل الطلب ووصفه';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // زر الإرسال
              ElevatedButton(
                onPressed: _isLoading ? null : _submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'إرسال الطلب الآن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
              const SizedBox(height: 20),
              // ملاحظة
              const Center(
                child: Text(
                  'سيتم إخطارك عند قبول أحد المُشاوِرين لطلبك.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
