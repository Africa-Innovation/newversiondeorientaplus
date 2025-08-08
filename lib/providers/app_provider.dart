import 'package:flutter/foundation.dart';
import '../models/university.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/university_service.dart';
import '../services/firebase_university_service.dart';
import '../services/admin_university_service.dart';

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

  // Search & Filter State
  String _searchQuery = '';
  String? _selectedCity;
  String? _selectedType;
  String? _selectedDomain;
  double? _maxBudget;
  double _maxDistance = 50.0; // km

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
      // Charger les universités personnalisées depuis le stockage local
      await AdminUniversityService.loadCustomUniversities();
      
      await _checkAuthStatus();
      await _loadUniversities();
      if (_isAuthenticated) {
        await _loadFavorites();
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
    } finally {
      _setLoading(false);
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

  // Location Methods
  Future<void> requestLocation() async {
    try {
      final position = await _universityService.getCurrentLocation();
      if (position != null) {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _locationPermissionGranted = true;
        
        // Obtenir la ville basée sur les coordonnées
        _userCity = await _universityService.getCityFromCoordinates();
        
        // Trier les universités par distance
        _sortUniversitiesByDistance();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur géolocalisation: $e');
      _locationPermissionGranted = false;
    }
  }

  // University Methods
  Future<void> _loadUniversities() async {
    try {
      // 1. Charger les universités standard (hardcodées)
      List<University> standardUniversities = await _universityService.getAllUniversities();
      
      // 2. Charger les universités personnalisées créées par l'admin (local)
      List<University> customUniversities = AdminUniversityService.getCustomUniversities();
      
      // 3. Charger depuis Firebase (priorité élevée car contient les universités créées)
      List<University> firebaseUniversities = [];
      try {
        firebaseUniversities = await FirebaseUniversityService.getAllUniversities();
        debugPrint('🔥 Firebase: ${firebaseUniversities.length} universités chargées');
      } catch (e) {
        debugPrint('⚠️ Firebase indisponible, mode offline: $e');
      }
      
      // 4. Combiner toutes les listes en évitant les doublons
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
      
      // Ajouter les universités personnalisées locales
      for (University university in customUniversities) {
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
      _applyFilters();
      debugPrint('🎯 AppProvider: ${_allUniversities.length} universités chargées');
      debugPrint('   • ${firebaseUniversities.length} Firebase');
      debugPrint('   • ${customUniversities.length} personnalisées');
      debugPrint('   • ${standardUniversities.length} standards');
    } catch (e) {
      debugPrint('Erreur chargement universités: $e');
      // Fallback vers les universités standards uniquement
      try {
        _allUniversities = await _universityService.getAllUniversities();
        _applyFilters();
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
    
    // Recharger les universités personnalisées depuis le stockage
    await AdminUniversityService.loadCustomUniversities();
    
    await _loadUniversities();
    await _loadFavorites();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    if (_currentUser != null) {
      // Filtrer les universités favorites à partir de toutes les universités
      _favoriteUniversities = _allUniversities
          .where((univ) => _currentUser!.favoriteUniversities.contains(univ.id))
          .toList();
      notifyListeners();
    }
  }

  // Search & Filter Methods
  void searchUniversities(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setFilters({
    String? city,
    String? type,
    String? domain,
    double? maxBudget,
    double? maxDistance,
  }) {
    _selectedCity = city;
    _selectedType = type;
    _selectedDomain = domain;
    _maxBudget = maxBudget;
    _maxDistance = maxDistance ?? _maxDistance;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCity = null;
    _selectedType = null;
    _selectedDomain = null;
    _maxBudget = null;
    _maxDistance = 50.0;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredUniversities = _allUniversities.where((university) {
      // Filtre par recherche (nom, programmes ou filières)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = university.name.toLowerCase().contains(query);
        final matchesProgram = university.programs
            .any((program) => program.name.toLowerCase().contains(query));
        final matchesSpecialty = university.specialtyNames
            .any((specialty) => specialty.toLowerCase().contains(query));
        if (!matchesName && !matchesProgram && !matchesSpecialty) return false;
      }

      // Filtre par ville
      if (_selectedCity != null && 
          university.city.toLowerCase() != _selectedCity!.toLowerCase()) {
        return false;
      }

      // Filtre par type
      if (_selectedType != null && university.type != _selectedType) {
        return false;
      }

      // Filtre par domaine (recherche dans les programmes et filières)
      if (_selectedDomain != null) {
        final hasProgram = university.programs
            .any((program) => program.name.toLowerCase()
                .contains(_selectedDomain!.toLowerCase()));
        final hasSpecialty = university.specialtyNames
            .any((specialty) => specialty.toLowerCase()
                .contains(_selectedDomain!.toLowerCase()));
        if (!hasProgram && !hasSpecialty) return false;
      }

      // Filtre par budget
      if (_maxBudget != null && university.minPrice != null &&
          university.minPrice! > _maxBudget!) {
        return false;
      }

      // Filtre par distance
      if (_userLatitude != null && _userLongitude != null) {
        final distance = university.distanceFrom(_userLatitude!, _userLongitude!);
        if (distance > _maxDistance) return false;
      }

      return true;
    }).toList();

    // Trier par distance si la localisation est disponible
    if (_userLatitude != null && _userLongitude != null) {
      _filteredUniversities.sort((a, b) {
        final distanceA = a.distanceFrom(_userLatitude!, _userLongitude!);
        final distanceB = b.distanceFrom(_userLatitude!, _userLongitude!);
        return distanceA.compareTo(distanceB);
      });
    }
  }

  void _sortUniversitiesByDistance() {
    if (_userLatitude != null && _userLongitude != null) {
      _applyFilters(); // Réapplique les filtres avec le nouveau tri
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
      await _authService.updateUserProfile(_currentUser!);
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
}
