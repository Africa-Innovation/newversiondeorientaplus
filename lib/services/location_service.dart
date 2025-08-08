import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Position? _currentPosition;
  
  /// Obtenir la position actuelle de l'utilisateur
  static Future<Position?> getCurrentPosition() async {
    print('📍 LocationService: Demande de localisation...');
    
    try {
      // Vérifier si la localisation est activée
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Service de localisation désactivé');
        return null;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Permission de localisation refusée');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permission de localisation refusée définitivement');
        return null;
      }

      // Obtenir la position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPosition = position;
      print('✅ Position obtenue: ${position.latitude}, ${position.longitude}');
      return position;
      
    } catch (e) {
      print('❌ Erreur lors de l\'obtention de la position: $e');
      return null;
    }
  }

  /// Calculer la distance entre deux points en kilomètres
  static double calculateDistance(
    double startLat, 
    double startLng, 
    double endLat, 
    double endLng
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }

  /// Calculer la distance entre la position actuelle et une université
  static double? calculateDistanceToUniversity(double uniLat, double uniLng) {
    if (_currentPosition == null) return null;
    
    return calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      uniLat,
      uniLng,
    );
  }

  /// Formater la distance pour l'affichage
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Obtenir le nom de la ville à partir des coordonnées
  static Future<String?> getCityFromCoordinates(double latitude, double longitude) async {
    try {
      print('🌍 Géocodage inverse: $latitude, $longitude');
      
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        
        // Essayer différents niveaux de localisation
        String? city = placemark.locality ?? 
                      placemark.subAdministrativeArea ?? 
                      placemark.administrativeArea ?? 
                      placemark.country;
        
        print('✅ Ville trouvée: $city');
        return city;
      }
      
      print('❌ Aucune ville trouvée');
      return null;
      
    } catch (e) {
      print('❌ Erreur géocodage inverse: $e');
      return null;
    }
  }

  /// Obtenir la position sauvegardée
  static Position? get currentPosition => _currentPosition;

  /// Vérifier si on a une position
  static bool get hasLocation => _currentPosition != null;
}
