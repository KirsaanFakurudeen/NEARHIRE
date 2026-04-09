import 'dart:math';

class DistanceHelper {
  DistanceHelper._();

  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;

  static bool isWithinRadius(
    double userLat,
    double userLon,
    double jobLat,
    double jobLon,
    double radiusKm,
  ) {
    return calculateDistanceKm(userLat, userLon, jobLat, jobLon) <= radiusKm;
  }
}
