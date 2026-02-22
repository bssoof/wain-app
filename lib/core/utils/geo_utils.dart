import 'dart:math' show asin, cos, pi, sin, sqrt;

double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const radiusKm = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return 2 * radiusKm * asin(sqrt(a));
}
