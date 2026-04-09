import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/location_service.dart';
import '../core/constants/app_constants.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  double? _latitude;
  double? _longitude;
  String _address = '';
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionStream;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get address => _address;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _latitude != null && _longitude != null;

  Future<void> refreshLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final position = await _locationService.getCurrentLocation();
      _latitude = position.latitude;
      _longitude = position.longitude;
      _address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startLocationStream(void Function(double lat, double lon) onUpdate) {
    _positionStream?.cancel();
    _positionStream = _locationService.getPositionStream().listen((position) {
      final prevLat = _latitude;
      final prevLon = _longitude;
      if (prevLat != null && prevLon != null) {
        final dist = Geolocator.distanceBetween(
          prevLat,
          prevLon,
          position.latitude,
          position.longitude,
        );
        if (dist < AppConstants.positionUpdateThresholdMeters) return;
      }
      _latitude = position.latitude;
      _longitude = position.longitude;
      notifyListeners();
      onUpdate(position.latitude, position.longitude);
    });
  }

  void stopLocationStream() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  @override
  void dispose() {
    stopLocationStream();
    super.dispose();
  }
}
