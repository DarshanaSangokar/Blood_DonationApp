import 'dart:math';

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371; // Radius of Earth in kilometers
  final latDistance = _toRadians(lat2 - lat1);
  final lonDistance = _toRadians(lon2 - lon1);

  final a = sin(latDistance / 2) * sin(latDistance / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(lonDistance / 2) *
          sin(lonDistance / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c; // Distance in kilometers
}

double _toRadians(double degree) {
  return degree * pi / 180;
}
