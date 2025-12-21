import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'categories/dm/Location_result.dart';

class MapPickerScreen extends StatefulWidget {
  final String title;
  final LatLng initialLocation;

  const MapPickerScreen({
    super.key,
    required this.title,
    required this.initialLocation,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng _currentCenter = const LatLng(
    26.1770,
    32.7444,
  ); // موقع افتراضي في قنا، مصر
  String _currentAddress = 'جاري البحث عن العنوان...';
  bool _isLoadingLocation = true;
  final MapController _mapController = MapController();
  LatLng? _lastGeocodedLatLng; // لتجنب تكرار Geocoding

  // حفظ موقع المستخدم الحقيقي لاستخدامه لزر "إعادة التمركز"
  LatLng? _userRealLocation;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation;
    _determinePosition();
  }

  // دالة لجلب العنوان النصي من الإحداثيات (Reverse Geocoding)
  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    // Check if location is already being fetched or is the same
    if (_lastGeocodedLatLng == latLng) return;
    _lastGeocodedLatLng = latLng;

    if (mounted) {
      setState(() {
        _currentAddress = 'جاري البحث عن العنوان...';
      });
    }

    try {
      // استخدام مكتبة geocoding لجلب العنوان
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // بناء عنوان واضح ومفصل
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        if (mounted) {
          setState(() {
            _currentAddress =
                address.isEmpty ? 'لم يتم العثور على عنوان دقيق' : address;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentAddress = 'لم يتم العثور على عنوان دقيق';
          });
        }
      }
    } catch (e) {
      print("خطأ في Geocoding: $e");
      if (mounted) {
        setState(() {
          _currentAddress =
              'خطأ في جلب العنوان (إحداثيات: ${latLng.latitude.toStringAsFixed(4)})';
        });
      }
    }
  }

  // الحصول على الموقع الحالي للمستخدم
  Future<void> _determinePosition() async {
    // عمليات التحقق من الصلاحيات والخدمة (كما كانت سابقاً)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _isLoadingLocation = false;
      await _getAddressFromLatLng(_currentCenter);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _isLoadingLocation = false;
        await _getAddressFromLatLng(_currentCenter);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _isLoadingLocation = false;
      await _getAddressFromLatLng(_currentCenter);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentCenter = LatLng(position.latitude, position.longitude);
      _userRealLocation = _currentCenter; // حفظ موقع المستخدم الفعلي
      _mapController.move(_currentCenter, 17.0); // تكبير أكثر (zoom 17)
      await _getAddressFromLatLng(_currentCenter);
    } catch (e) {
      print("خطأ في جلب الموقع: $e");
      await _getAddressFromLatLng(_currentCenter);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // دالة لإعادة تمركز الخريطة على موقع المستخدم
  void _recenterMap() {
    if (_userRealLocation != null) {
      _mapController.move(_userRealLocation!, 17.0);
      _getAddressFromLatLng(_userRealLocation!);
      // لا حاجة لـ setState هنا لأن onPositionChanged ستنفذه
    }
  }

  // إرجاع الموقع المختار إلى الشاشة السابقة
  void _selectLocation() {
    final result = LocationResult(
      latLng: _currentCenter,
      addressPlaceholder: _currentAddress, // نرسل العنوان النصي الذي تم جلبه
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // الخريطة
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 17.0, // زيادة مستوى التكبير الافتراضي
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  _currentCenter = position.center!;
                  // جلب العنوان النصي الجديد بعد تغيير الخريطة
                  _getAddressFromLatLng(_currentCenter);
                  if (mounted) {
                    setState(() {});
                  }
                }
              },
            ),
            children: [
              // 1. مصدر التايلات الفضائي (Esri World Imagery)
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.mshawer',
                // لإظهار تسميات الطرق والمدن فوق الصورة الفضائية
                subdomains: const ['a', 'b', 'c'],
              ),
              // 2. طبقة تسميات الطرق (اختياري لزيادة الوضوح على الستالايت)
              // يمكن استخدام طبقة شفافة تعرض أسماء الشوارع فقط إذا كان العرض الفضائي لا يحتويها
              // TileLayer(
              //   urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              //   userAgentPackageName: 'com.example.mshawer',
              //   opacity: 0.5, // شفافية
              // ),
            ],
          ),

          // العلامة المركزية الثابتة (Pin)
          const Center(
            child: Icon(Icons.location_on, color: Colors.red, size: 50.0),
          ),

          // زر إعادة التمركز - FAB (لتحسين تجربة العميل)
          Positioned(
            top: 10,
            left: 10,
            child: FloatingActionButton(
              onPressed: _recenterMap,
              heroTag: 'recenter_btn',
              backgroundColor: Colors.white,
              mini: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.my_location, color: Colors.teal),
            ),
          ),

          // معلومات الموقع في الأسفل - تم تحسين التصميم
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 10, // ظل أوضح
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'الموقع المختار حالياً:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const Divider(height: 10, color: Colors.grey),
                    const SizedBox(height: 5),

                    // العنوان النصي
                    Text(
                      _currentAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 15),

                    // زر التأكيد
                    ElevatedButton(
                      onPressed: _selectLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 5,
                      ),
                      child: const Text(
                        'تأكيد هذا العنوان',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
