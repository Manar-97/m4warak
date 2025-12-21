// نموذج مبسط لبيانات الموقع التي سيتم إرجاعها
import 'package:latlong2/latlong.dart';

class LocationResult {
  final LatLng latLng;
  final String addressPlaceholder; // عنوان نصي تقريبي

  LocationResult({required this.latLng, required this.addressPlaceholder});
}
