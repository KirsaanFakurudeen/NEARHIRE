class AppConstants {
  AppConstants._();

  static const String baseApiUrl = 'https://api.nearhire.com/v1';
  static const String socketUrl = 'https://api.nearhire.com';
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  static const double defaultRadiusKm = 10.0;
  static const double minRadiusKm = 1.0;
  static const double maxRadiusKm = 50.0;

  static const double positionUpdateThresholdMeters = 100.0;
  static const int locationUpdateIntervalSeconds = 30;

  static const String jwtTokenKey = 'jwt_token';
  static const String userRoleKey = 'user_role';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String deviceTokenKey = 'device_token';

  static const String roleEmployer = 'employer';
  static const String roleSeeker = 'seeker';

  static const int otpResendSeconds = 60;
  static const int splashDelaySeconds = 2;
}
