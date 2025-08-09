import 'package:flutter/foundation.dart';
import '../models/university.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/university_service.dart';
import '../services/firebase_university_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class AppProvider with ChangeNotifier {
  // User State
  UserProfile? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  // Universities State
  List<University> _allUniversities = [];
  List<University> _filteredUniversities = [];
  List<University> _favoriteUniversities = [];
  
  // Location State
  double? _userLatitude;
  double? _userLongitude;
  String? _userCity;
  bool _locationPermissionGranted = false;

  // Search State
  String _searchQuery = '';

  // Services
  final AuthService _authService = AuthService();
  final UniversityService _universityService = UniversityService();

  // Getters
  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  List<University> get universities => _filteredUniversities;
  List<University> get favoriteUniversities => _favoriteUniversities;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  String? get userCity => _userCity;
  bool get locationPermissionGranted => _locationPermissionGranted;
  String get searchQuery => _searchQuery;

  // Initialization
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Plus besoin de charger depuis le stockage local - tout vient de Firebase
      
      await _checkAuthStatus();
      await _loadUniversities();
      if (_isAuthenticated) {
        await _loadFavorites();
      }
      
      // 🔄 MODIFIÉ: Demander la localisation de manière non-bloquante
      print('🚀 Initialisation: Demande de localisation en arrière-plan...');
      _requestLocationInBackground();
      
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 🔥 NOUVEAU: Méthode pour demander la localisation sans bloquer l'initialisation
  void _requestLocationInBackground() async {
    try {
      await requestUserLocation();
      print('✅ Localisation obtenue en arrière-plan');
    } catch (e) {
      print('⚠️ Localisation refusée ou impossible: $e');
      // L'app continue de fonctionner sans localisation
    }
  }

  // Authentication Methods
  Future<bool> sendOTP(String phoneNumber) async {
    _setLoading(true);
    try {
      bool success = await _authService.sendOTP(phoneNumber);
      return success;
    } catch (e) {
      debugPrint('Erreur envoi OTP: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    _setLoading(true);
    try {
      UserProfile? user = await _authService.verifyOTP(phoneNumber, otp);
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        await _loadFavorites();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur vérification OTP: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _isAuthenticated = false;
    _favoriteUniversities.clear();
    notifyListeners();
  }

  // University Methods
  Future<void> _loadUniversities() async {
    try {
      // 1. Charger les universités standard (hardcodées)
      List<University> standardUniversities = await _universityService.getAllUniversities();
      
      // 2. Charger depuis Firebase (contient les universités créées par l'admin)
      List<University> firebaseUniversities = [];
      try {
        firebaseUniversities = await FirebaseUniversityService.getAllUniversities();
        debugPrint('🔥 Firebase: ${firebaseUniversities.length} universités chargées');
      } catch (e) {
        debugPrint('⚠️ Firebase indisponible, mode offline: $e');
      }
      
      // 3. Combiner Firebase + Standards en évitant les doublons
      // Firebase en premier car il contient les universités créées via l'admin
      Set<String> existingIds = <String>{};
      List<University> combinedUniversities = [];
      
      // Ajouter d'abord Firebase (contient les universités créées)
      for (University university in firebaseUniversities) {
        if (!existingIds.contains(university.id)) {
          combinedUniversities.add(university);
          existingIds.add(university.id);
        }
      }
      
      // Ajouter les universités standard en dernier
      for (University university in standardUniversities) {
        if (!existingIds.contains(university.id)) {
          combinedUniversities.add(university);
          existingIds.add(university.id);
        }
      }
      
      _allUniversities = combinedUniversities;
      _applySearch();
      debugPrint('🎯 AppProvider: ${_allUniversities.length} universités chargées');
      debugPrint('   • ${firebaseUniversities.length} Firebase');
      debugPrint('   • ${standardUniversities.length} standards');
    } catch (e) {
      debugPrint('Erreur chargement universités: $e');
      // Fallback vers les universités standards uniquement
      try {
        _allUniversities = await _universityService.getAllUniversities();
        _applySearch();
        debugPrint('🔄 Fallback: ${_allUniversities.length} universités standards chargées');
      } catch (fallbackError) {
        debugPrint('Erreur fallback: $fallbackError');
      }
    }
  }

  /// Recharge les universités (public pour être appelé après création/modification)
  Future<void> refreshUniversities() async {
    _isLoading = true;
    notifyListeners();
    
    // Plus besoin de recharger depuis le stockage local - tout vient de Firebase
    
    await _loadUniversities();
    await _loadFavorites();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    if (_currentUser != null) {
      print('🔄 Chargement des favoris...');
      print('   User ID: ${_currentUser!.id}');
      print('   Favoris dans profil: ${_currentUser!.favoriteUniversities}');
      
      // Récupérer les universités favorites à partir de toutes les universités
      _favoriteUniversities = _allUniversities
          .where((univ) => _currentUser!.favoriteUniversities.contains(univ.id))
          .toList();
      
      print('✅ Favoris chargés: ${_favoriteUniversities.length} universités');
      for (var fav in _favoriteUniversities) {
        print('   - ${fav.name}');
      }
      
      notifyListeners();
    }
  }

  // Search Methods
  void searchUniversities(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      // Si pas de recherche, afficher toutes les universités
      _filteredUniversities = List.from(_allUniversities);
    } else {
      // Appliquer la recherche
      final query = _searchQuery.toLowerCase();
      _filteredUniversities = _allUniversities.where((university) {
        // Recherche dans le nom
        final matchesName = university.name.toLowerCase().contains(query);
        
        // Recherche dans les programmes
        final matchesProgram = university.programs
            .any((program) => program.name.toLowerCase().contains(query));
        
        // Recherche dans les spécialités
        final matchesSpecialty = university.specialtyNames
            .any((specialty) => specialty.toLowerCase().contains(query));
        
        // Recherche dans la ville
        final matchesCity = university.city.toLowerCase().contains(query);
        
        return matchesName || matchesProgram || matchesSpecialty || matchesCity;
      }).toList();
    }

    // Trier par distance si la localisation est disponible
    if (_userLatitude != null && _userLongitude != null) {
      _filteredUniversities.sort((a, b) {
        final distanceA = a.distanceFrom(_userLatitude!, _userLongitude!);
        final distanceB = b.distanceFrom(_userLatitude!, _userLongitude!);
        return distanceA.compareTo(distanceB);
      });
    }
  }

  // Favorites Methods
  Future<void> toggleFavorite(String universityId) async {
    if (_currentUser == null) return;

    try {
      List<String> favorites = List.from(_currentUser!.favoriteUniversities);
      
      if (favorites.contains(universityId)) {
        favorites.remove(universityId);
        _favoriteUniversities.removeWhere((u) => u.id == universityId);
      } else {
        favorites.add(universityId);
        final university = _allUniversities.firstWhere((u) => u.id == universityId);
        _favoriteUniversities.add(university);
      }

      _currentUser = _currentUser!.copyWith(favoriteUniversities: favorites);
      
      // 🔥 NOUVEAU: Utiliser la nouvelle méthode Firebase spécifique
      await _authService.updateUserFavorites(_currentUser!.id, favorites);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur toggle favori: $e');
    }
  }

  bool isFavorite(String universityId) {
    return _currentUser?.favoriteUniversities.contains(universityId) ?? false;
  }

  // Helper Methods
  Future<void> _checkAuthStatus() async {
    _currentUser = await _authService.getCurrentUser();
    _isAuthenticated = _currentUser != null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Profile Methods
  Future<void> updateProfile({
    String? name,
    String? series,
    String? city,
    List<String>? interests,
  }) async {
    if (_currentUser == null) return;

    try {
      _currentUser = _currentUser!.copyWith(
        name: name,
        series: series,
        city: city,
        interests: interests,
      );
      
      await _authService.updateUserProfile(_currentUser!);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur mise à jour profil: $e');
    }
  }

  // ==================== GÉOLOCALISATION ====================

  /// Demander la permission de localisation et obtenir la position
  Future<bool> requestUserLocation() async {
    print('📍 AppProvider: Demande de localisation utilisateur...');
    
    try {
      Position? position = await LocationService.getCurrentPosition();
      
      if (position != null) {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _locationPermissionGranted = true;
        
        print('✅ Position utilisateur sauvegardée: $_userLatitude, $_userLongitude');
        
        // Récupérer le nom de la ville
        String? cityName = await LocationService.getCityFromCoordinates(
          position.latitude, 
          position.longitude
        );
        
        if (cityName != null) {
          _userCity = cityName;
          print('✅ Ville détectée: $_userCity');
        }
        
        notifyListeners();
        return true;
      } else {
        _locationPermissionGranted = false;
        print('❌ Impossible d\'obtenir la position');
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Erreur géolocalisation: $e');
      _locationPermissionGranted = false;
      notifyListeners();
      return false;
    }
  }

  /// Calculer la distance entre l'utilisateur et une université
  String? getDistanceToUniversity(University university) {
    if (!_locationPermissionGranted || _userLatitude == null || _userLongitude == null) {
      return null;
    }
    
    if (university.latitude == 0 || university.longitude == 0) {
      return null;
    }
    
    double distance = LocationService.calculateDistance(
      _userLatitude!,
      _userLongitude!,
      university.latitude,
      university.longitude,
    );
    
    return LocationService.formatDistance(distance);
  }

  // Getters pour la localisation
  bool get hasUserLocation => _locationPermissionGranted && _userLatitude != null && _userLongitude != null;
}
