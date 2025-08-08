import '../models/university.dart';

/// Cache global pour éviter les reconstructions
class HomeCache {
  static List<University> _cachedUniversities = [];
  static String? _cachedUserCity;
  static bool _cachedLocationPermission = false;
  static bool _isInitialized = false;

  static void updateUniversities(List<University> universities) {
    _cachedUniversities = universities;
    _isInitialized = true;
  }

  static void updateLocation(String? city, bool permission) {
    _cachedUserCity = city;
    _cachedLocationPermission = permission;
  }

  static List<University> get universities => _cachedUniversities;
  static String? get userCity => _cachedUserCity;
  static bool get locationPermission => _cachedLocationPermission;
  static bool get isInitialized => _isInitialized;
}
